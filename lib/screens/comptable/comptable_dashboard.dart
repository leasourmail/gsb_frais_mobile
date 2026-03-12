// Tableau de bord comptable : Valider Fiches, Suivi Paiements, Profil, Configuration, Aide

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gsb_frais_appli/screens/comptable/suivi_paiements_comptable_screen.dart';
import 'package:gsb_frais_appli/screens/comptable/validation_fiche_comptable_screen.dart';
import '../login_screen.dart';
import '../aide_screen.dart';
import '../profil_screen.dart';
import 'gestion_parametres_screen.dart';

class ComptableDashboard extends StatefulWidget {
  const ComptableDashboard({super.key});

  @override
  State<ComptableDashboard> createState() => _ComptableDashboardState();
}

class _ComptableDashboardState extends State<ComptableDashboard> {
  final _storage = const FlutterSecureStorage();
  int _selectedIndex = 0;

  String _nom = "";
  String _prenom = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    String? nom = await _storage.read(key: "nom");
    String? prenom = await _storage.read(key: "prenom");
    if (mounted) {
      setState(() {
        _nom = nom ?? "Comptable";
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
    final Color primary = Colors.teal[800]!;
    final Color secondary = Colors.teal[400]!;
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Espace Comptable", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout)],
      ),
      body: Column(
        children: [
          // Entête fixe
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: topPadding, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, colors: [primary, secondary]),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Session Comptabilité", style: TextStyle(color: Colors.white70, fontSize: 18)),
                    Text("$_prenom $_nom", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 35),
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
                  _buildMenuCard("Valider Fiches", Icons.fact_check, Colors.orange[700]!, () => setState(() => _selectedIndex = 1)),
                  _buildMenuCard("Suivi Paiements", Icons.payments, Colors.green[700]!, () => setState(() => _selectedIndex = 2)),
                  _buildMenuCard("Configuration", Icons.settings_applications, Colors.teal[700]!, () => setState(() => _selectedIndex = 3)),
                  _buildMenuCard("Profil", Icons.manage_accounts, Colors.blue[700]!, () => setState(() => _selectedIndex = 4)),
                  _buildMenuCard("Aide", Icons.support_agent, Colors.purple[700]!, () => setState(() => _selectedIndex = 5)),
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
          const ValidationFichesComptableScreen(),
          const SuiviPaiementsComptableScreen(),
          const GestionParametresScreen(),
          const ProfilScreen(role: 'ROLE_COMPTABLE'),
          const AideScreen(role: 'ROLE_COMPTABLE'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal[800],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: 'Valider Fiches'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Suivi Paiements'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuration'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Aide'),
        ],
      ),
    );
  }

  /// Carte du menu comptable (même principe que visiteur / manager)
  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}