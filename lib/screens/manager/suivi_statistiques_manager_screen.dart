// Statistiques du secteur du manager : total engagé, budget, répartition par catégorie (repas, nuitées, etc.)
// Données fournies par l'API stats-manager

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SuiviStatistiquesManagerScreen extends StatefulWidget {
  const SuiviStatistiquesManagerScreen({super.key});

  @override
  State<SuiviStatistiquesManagerScreen> createState() => _SuiviStatistiquesManagerScreenState();
}

class _SuiviStatistiquesManagerScreenState extends State<SuiviStatistiquesManagerScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  /// Appel API stats-manager avec l'id du manager connecté (timeout 10 s)
  Future<void> _chargerStats() async {
    try {
      final String? token = await _storage.read(key: "jwt");
      final String? idMan = await _storage.read(key: "id_utilisateur");

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/frais/stats-manager/$idMan"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color managerColor = Colors.indigo[900]!;

    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator(color: managerColor)));

    double totalReel = (_stats['totalEngage'] ?? 0.0).toDouble();
    double budgetMaxBDD = (_stats['enveloppeBudgetaire'] ?? 100000.0).toDouble();
    double ratioGlobal = (totalReel / budgetMaxBDD).clamp(0.0, 1.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Statistiques Secteur", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
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
            child: Column(
              children: [
                const Text("Dépenses annuelles engagées", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 5),
                Text("${totalReel.toStringAsFixed(2)} €",
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // Carte budget global avec barre de progression
                  _buildGlobalBudgetCard(totalReel, ratioGlobal, budgetMaxBDD),
                  const SizedBox(height: 25),

                  // Compteurs à valider / validées
                  Row(
                    children: [
                      _buildMiniCard("À VALIDER", _stats['nbFichesAValider'].toString(), Colors.orange, Icons.pending_actions),
                      const SizedBox(width: 15),
                      _buildMiniCard("VALIDÉES", _stats['nbFichesValidees'].toString(), Colors.green, Icons.check_circle_outline),
                    ],
                  ),
                  const SizedBox(height: 30),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Répartition par catégorie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),

                  // RATIOS PAR CATÉGORIE
                  _buildCategoryList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte qui affiche le pourcentage du budget consommé avec une barre de progression
  Widget _buildGlobalBudgetCard(double montant, double ratio, double limite) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Budget global", style: TextStyle(fontWeight: FontWeight.w600)),
                Text("${(ratio * 100).toStringAsFixed(1)} %", style: TextStyle(color: ratio > 0.85 ? Colors.red : Colors.indigo, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.grey[200],
              color: ratio > 0.85 ? Colors.red : Colors.indigo[700],
            ),
            const SizedBox(height: 15),
            Text("Limite autorisée : ${limite.toInt()} €", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  /// Liste des catégories avec montant et barre de proportion
  Widget _buildCategoryList() {
    if (_stats.containsKey('repartition') && _stats['repartition'] != null) {
      return Column(
        children: [
          _buildCategoryRatio("Repas", _stats['repartition']['repas'], Colors.teal, Icons.restaurant),
          _buildCategoryRatio("Nuitées", _stats['repartition']['nuitees'], Colors.purple, Icons.hotel),
          _buildCategoryRatio("Transports (KM)", _stats['repartition']['transport'], Colors.orange, Icons.directions_car),
          _buildCategoryRatio("Etape", _stats['repartition']['etape'], Colors.indigo, Icons.map),
          _buildCategoryRatio("Hors-Forfait", _stats['repartition']['autres'], Colors.redAccent, Icons.receipt_long),
        ],
      );
    }
    return const Center(child: Text("Aucune donnée disponible"));
  }

  Widget _buildCategoryRatio(String label, dynamic montant, Color couleur, IconData icon) {
    double m = (montant ?? 0.0).toDouble();
    double totalConsomme = (_stats['totalEngage'] ?? 1.0).toDouble();
    double ratioInterne = totalConsomme > 0 ? (m / totalConsomme).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: couleur, size: 20),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text("${m.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ratioInterne,
            color: couleur,
            minHeight: 6,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: Colors.grey[100],
          ),
        ],
      ),
    );
  }

  /// Petite carte (ex : "À VALIDER" avec un nombre)
  Widget _buildMiniCard(String titre, String valeur, Color couleur, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleur.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: couleur),
            const SizedBox(height: 8),
            Text(valeur, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: couleur)),
            Text(titre, style: TextStyle(color: couleur.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}