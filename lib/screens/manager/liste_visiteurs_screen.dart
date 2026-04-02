// Liste des visiteurs rattachés au manager (appel API mes-visiteurs avec l'email du manager)

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'consulter_fiche_visiteur_screen.dart';

class ListeVisiteursScreen extends StatefulWidget {
  const ListeVisiteursScreen({super.key});

  @override
  State<ListeVisiteursScreen> createState() => _ListeVisiteursScreenState();
}

class _ListeVisiteursScreenState extends State<ListeVisiteursScreen> {
  final _storage = const FlutterSecureStorage();
  List _visiteurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerVisiteurs();
  }

  /// Récupère la liste des visiteurs dont le manager est responsable (backend : mes-visiteurs)
  Future<void> _chargerVisiteurs() async {
    final String? token = await _storage.read(key: "jwt");
    final String? emailManager = await _storage.read(key: "email");

    try {
   
      final response = await http.get(
        Uri.parse("http://localhost:8080/api/utilisateurs/mes-visiteurs?emailManager=$emailManager"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _visiteurs = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion au serveur")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color managerColor = Colors.indigo[900]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Équipe de Visiteurs",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête avec nombre de collaborateurs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 100, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [managerColor, managerColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${_visiteurs.length} collaborateurs",
                        style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const Text("Mes Visiteurs",
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.groups, color: Colors.white, size: 50),
              ],
            ),
          ),

          // Liste des cartes visiteurs (clic = ouvrir les fiches du visiteur)
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: managerColor))
                : _visiteurs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 20),
              itemCount: _visiteurs.length,
              itemBuilder: (context, index) {
                final visiteur = _visiteurs[index];
                // Sécurité sur le nom pour éviter les erreurs de null
                final String nom = (visiteur['nom'] ?? "Nom").toString().toUpperCase();
                final String prenom = (visiteur['prenom'] ?? "Prénom").toString();

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: managerColor.withOpacity(0.1),
                      child: Text(nom.isNotEmpty ? nom[0] : "?",
                        style: TextStyle(color: managerColor, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    title: Text("$prenom $nom",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(visiteur['email'] ?? "",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    trailing: Icon(Icons.arrow_forward_ios, color: managerColor, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsulterFichesVisiteurScreen(
                            idVisiteur: visiteur['idUtilisateur'],
                            nomVisiteur: "$prenom $nom",
                            emailVisiteur: visiteur['email'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Affichage quand le manager n'a aucun visiteur rattaché
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucun visiteur rattaché",
              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}