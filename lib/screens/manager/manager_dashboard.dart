// Tableau de bord manager : accès Mes Visiteurs, Suivi Frais, Profil, Aide

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gsb_frais_appli/screens/manager/suivi_statistiques_manager_screen.dart';
import '../login_screen.dart';
import '../profil_screen.dart';
import '../aide_screen.dart';
import 'liste_visiteurs_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final _storage = const FlutterSecureStorage();
  int _selectedIndex = 0;

  String _nom = "";
  String _prenom = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Charge nom / prénom depuis le stockage pour l'en-tête
  Future<void> _loadUserInfo() async {
    String? nom = await _storage.read(key: "nom");
    String? prenom = await _storage.read(key: "prenom");
    if (mounted) {
      setState(() {
        _nom = nom ?? "Responsable";
        _prenom = prenom ?? "";
      });
    }
  }

  /// Déconnexion et retour à l'écran de login
  void _logout() async {
    await _storage.deleteAll();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  Widget _buildAccueilPage() {
    final Color primaryColor = Colors.indigo[900]!;
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Espace Responsable", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              gradient: LinearGradient(begin: Alignment.topCenter, colors: [primaryColor, Colors.indigo[700]!]),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Session Responsable", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text("$_prenom $_nom", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.manage_accounts, color: Colors.white, size: 35),
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
                  _buildMenuCard("Mes Visiteurs", Icons.people_alt, Colors.indigo, () => setState(() => _selectedIndex = 1)),
                  _buildMenuCard("Suivi Frais", Icons.analytics_outlined, Colors.teal, () => setState(() => _selectedIndex = 2)),
                  _buildMenuCard("Mon Profil", Icons.account_circle, Colors.blue, () => setState(() => _selectedIndex = 3)),
                  _buildMenuCard("Aide", Icons.help_center_outlined, Colors.purple, () => setState(() => _selectedIndex = 4)),
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
          const ListeVisiteursScreen(),
          const SuiviStatistiquesManagerScreen(),
          const ProfilScreen(role: 'ROLE_MANAGER'),
          const AideScreen(role: 'ROLE_MANAGER'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo[800],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Mes Visiteurs'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Suivi Frais'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Aide'),
        ],
      ),
    );
  }

  /// Carte du menu (même principe que visiteur mais avec les entrées manager)
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
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
            ),
          ],
        ),
      ),
    );
  }
}