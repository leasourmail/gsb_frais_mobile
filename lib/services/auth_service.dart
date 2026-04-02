// Service d'authentification : appelle l'API Spring Boot pour se connecter
// et stocke le token JWT + infos user dans le stockage sécurisé

import 'dart:convert';
import 'package:gsb_frais_appli/models/utilisateur.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Déclaration de la classe AuthService
class AuthService {
  final String baseUrl = "http://localhost:8080/api/auth"; // URL de l'API (10.0.2.2 est l'adresse IP de la machine locale pour que l'emulateur Flutter puisse accéder à l'API)

  final _storage = const FlutterSecureStorage();

  // Envoie email + mot de passe à l'API, récupère le user et enregistre le token + infos en local
  Future<Utilisateur?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}),
      );

      // Vérification de la réponse de l'API
      // Si la réponse est OK, on retourne l'utilisateur
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final user = Utilisateur.fromJson(data);

        // On garde tout en secure storage pour les appels API suivants et l'affichage du profil
        await _storage.write(key: "jwt", value: user.token);
        await _storage.write(key: "email", value: user.email);


        // Stockage du role de l'utilisateur
        await _storage.write(key: "role", value: user.role);

        // Stockage du nom de l'utilisateur
        await _storage.write(key: "nom", value: user.nom);

        // Stockage du prénom de l'utilisateur
        await _storage.write(key: "prenom", value: user.prenom);

        // Stockage de l'id de l'utilisateur pour les stats
        await _storage.write(key: "id_utilisateur", value: user.idUtilisateur.toString());


        return user;
      } else {
        print("Erreur de connexion : ${response.statusCode}");
        return null;
      }
      } catch (e) {
        print("Erreur de connexion : $e");
        return null;
      }
    }

  /// Récupère le JWT pour l'envoyer dans les headers des requêtes API
  Future<String?> getToken() async {
    return await _storage.read(key: "jwt");
  }

  /// Supprime le token et le rôle pour déconnecter l'utilisateur
  Future<void> logout() async {
    await _storage.delete(key: "jwt");
    await _storage.delete(key: "role");
  }
}