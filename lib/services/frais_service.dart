// Service qui gère toutes les requêtes liées aux fiches de frais (forfaits, hors-forfait, soumission)
// Utilise le JWT stocké pour s'authentifier auprès de l'API

import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FraisService {
  final String baseUrl = "http://10.0.2.2:8080/api/frais";
  final _storage = const FlutterSecureStorage();

  // Récupère la fiche du mois courant (ou la crée côté backend si elle n'existe pas encore)
  Future<Map<String, dynamic>?> getFicheMoisCourant() async {
    final token = await _storage.read(key: "jwt");
    final email = await _storage.read(key: "email");

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/fiche-courante?email=$email"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Erreur récupération fiche: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur réseau: $e");
      return null;
    }
  }

  // Enregistre ou met à jour les quantités forfait (nuitées, repas, km, étape) pour une fiche
  Future<bool> majFraisForfait(int? idFiche, int nuitees, int repas, int km, int etape, String email) async {
    final token = await _storage.read(key: "jwt");

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forfait/groupe"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "idFiche": idFiche, // Peut être null au premier clic
          "email": email,    // Utilisé par le backend pour créer la fiche si idFiche est null
          "nuitees": nuitees,
          "repas": repas,
          "km": km,
          "etape": etape,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Ajoute une ligne hors-forfait (sans photo) ; la date est déjà formatée par l'écran
  Future<bool> ajouterHorsForfait(int idFiche, String libelle, String date, double montant) async {
    final token = await _storage.read(key: "jwt");

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/hors-forfait"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "idFiche": idFiche,
          "libelle": libelle,
          "dateFrais": date,
          "montant": montant,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Même chose qu'ajouterHorsForfait mais avec envoi d'une image en multipart (justificatif)
  Future<bool> ajouterHorsForfaitAvecImage(int idFiche, String libelle, String date, double montant, File? image) async {
    final token = await _storage.read(key: "jwt");

    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/hors-forfait/uploads"));
    request.headers['Authorization'] = 'Bearer $token';

    // Ajout des champs textes
    request.fields['idFiche'] = idFiche.toString();
    request.fields['libelle'] = libelle;
    request.fields['dateFrais'] = date;
    request.fields['montant'] = montant.toString();

    // Ajout du fichier image s'il existe
    if (image != null) {
      request.files.add(
          await http.MultipartFile.fromPath('file', image.path));
    }

    var response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Supprime une ligne hors-forfait via son id (uniquement si la fiche est encore modifiable)
  Future<bool> supprimerHorsForfait(int idLigneHf) async {
    final token = await _storage.read(key: "jwt");

    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/hors-forfait/$idLigneHf"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Récupère une fiche pour un mois donné (format yyyyMM) pour consultation ou correction
  Future<Map<String, dynamic>?> consulterFicheParMois(String mois) async {
    final email = await _storage.read(key: "email");
    final token = await _storage.read(key: "jwt");
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/consulter?email=$email&mois=$mois"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Erreur récupération fiche: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur réseau: $e");
      return null;
    }
  }

  // Passe la fiche en état "Transmise" pour validation par le manager
  Future<bool> soumettreFiche(int idFiche) async {
    final String? token = await _storage.read(key: "jwt");
    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/frais/soumettre-fiche/$idFiche"),
        headers: {"Authorization": "Bearer $token"},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Méthode pour créer ou mettre à jour les frais forfaitisés
  Future<bool> creerOuMajFraisForfait(String email, int nuitees, int repas, int km, int etape) async {
    final token = await _storage.read(key: "jwt");

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/api/frais/forfait/groupe"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email, // Le backend utilisera ça si idFiche est absent
        "nuitees": nuitees,
        "repas": repas,
        "km": km,
        "etape": etape,
      }),
    );
    return response.statusCode == 200;
  }
}