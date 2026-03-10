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
  int _selectedIndex = 0;

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

  /// Page Accueil (bienvenue + cartes raccourcis). Entête fixe, seule la grille défile. 
  Widget _buildAccueilPage() {
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Espace Visiteur", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: Column(
        children: [
          // Entête fixe 
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: topPadding, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, colors: [Colors.blue[900]!, Colors.blue[600]!]),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bienvenue,", style: TextStyle(color: Colors.white70, fontSize: 18)),
                    Text("$_prenom $_nom", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
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
          // Seule la grille de cartes défile
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildMenuCard("Saisir Frais", Icons.add_circle, Colors.green, () => setState(() => _selectedIndex = 1)),
                  _buildMenuCard("Mes fiches", Icons.folder_shared, Colors.orange, () => setState(() => _selectedIndex = 2)),
                  _buildMenuCard("Profil", Icons.person, Colors.blue, () => setState(() => _selectedIndex = 3)),
                  _buildMenuCard("Aide", Icons.help_outline, Colors.purple, () => setState(() => _selectedIndex = 4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildAccueilPage(),
          const SaisieFraisScreen(),
          const ConsultationFraisScreen(),
          const ProfilScreen(role: 'ROLE_VISITEUR'),
          const AideScreen(role: 'ROLE_VISITEUR'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Saisir Frais'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared), label: 'Mes fiches'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Aide'),
        ],
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