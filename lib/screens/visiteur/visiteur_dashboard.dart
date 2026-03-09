// Tableau de bord visiteur : menu avec Saisie frais, Mes fiches, Profil, Aide

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gsb_frais_appli/screens/profil_screen.dart';
import 'package:gsb_frais_appli/screens/visiteur/saisie_frais_screen.dart';

import '../login_screen.dart';
import '../aide_screen.dart';
import 'consultation_frais_screen.dart';

class VisiteurDashboard extends StatefulWidget {
  const VisiteurDashboard({super.key});

  @override
  State<VisiteurDashboard> createState() => _VisiteurDashboardState();
}

class _VisiteurDashboardState extends State<VisiteurDashboard> {
  final _storage = const FlutterSecureStorage();

  String _userEmail = "";
  String _nom = "";
  String _prenom = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Récupère nom / prénom depuis le stockage pour afficher le message de bienvenue
  Future<void> _loadUserInfo() async {
    String? email = await _storage.read(key: "email");
    String? nom = await _storage.read(key: "nom");
    String? prenom = await _storage.read(key: "prenom");
    if (mounted) {
      setState(() {
        _userEmail = email ?? "";
        _nom = nom ?? "Visiteur";
        _prenom = prenom ?? "";
      });
    }
  }

  /// Déconnexion : on vide le stockage et on revient à l'écran de login
  void _logout() async {
    await _storage.deleteAll();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Espace Visiteur", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, left: 25, right: 25, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  colors: [Colors.blue[900]!, Colors.blue[600]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(60), // Match Login Screen
                  bottomRight: Radius.circular(60), // Match Login Screen
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bienvenue,", style: TextStyle(color: Colors.white70, fontSize: 18)),
                      Text("$_prenom $_nom",
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Grille des 4 cartes : Saisir Frais, Mes fiches, Profil, Aide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildMenuCard(
                    "Saisir Frais",
                    Icons.add_circle,
                    Colors.green,
                        () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SaisieFraisScreen()),
                      );
                    }
                  ),
                  _buildMenuCard(
                      "Mes fiches",
                      Icons.folder_shared,
                      Colors.orange,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ConsultationFraisScreen()),
                        );
                          }
                  ),
                  _buildMenuCard(
                      "Profil",
                      Icons.person,
                      Colors.blue,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilScreen()),
                        );
                          }
                  ),
                  _buildMenuCard(
                      "Aide",
                      Icons.help_outline,
                      Colors.purple,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AideScreen(role: 'ROLE_VISITEUR')),
                        );
                          }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte cliquable du menu (titre, icône, couleur) pour naviguer vers les autres écrans
  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color,),
            ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}