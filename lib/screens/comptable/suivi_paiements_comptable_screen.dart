// Vue trésorerie : montant décaissé, en attente, et consommation du budget (stats-comptable + enveloppe)

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SuiviPaiementsComptableScreen extends StatefulWidget {
  const SuiviPaiementsComptableScreen({super.key});

  @override
  State<SuiviPaiementsComptableScreen> createState() => _SuiviPaiementsComptableScreenState();
}

class _SuiviPaiementsComptableScreenState extends State<SuiviPaiementsComptableScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic> _stats = {
    "totalDecaisse": 0.0,
    "enAttente": 0.0,
    "enveloppeBudgetaire": 0.0,
    "annee": ""
  };
  bool _isLoading = true;
  final Color primaryColor = Colors.teal[800]!;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  /// Charge les stats comptable (décaissé, en attente) et l'enveloppe budgétaire
  Future<void> _loadAllStats() async {
    final String? token = await _storage.read(key: "jwt");
    try {
      final responseStats = await http.get(
        Uri.parse("http://localhost:8080/api/frais/stats-comptable"),
        headers: {"Authorization": "Bearer $token"},
      );

      final responseEnv = await http.get(
        Uri.parse("http://localhost:8080/api/frais/stats-manager/1"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (responseStats.statusCode == 200 && responseEnv.statusCode == 200) {
        final dataStats = jsonDecode(responseStats.body);
        final dataEnv = jsonDecode(responseEnv.body);

        setState(() {
          _stats = {
            "totalDecaisse": dataStats['totalDecaisse']?.toDouble() ?? 0.0,
            "enAttente": dataStats['enAttente']?.toDouble() ?? 0.0,
            "enveloppeBudgetaire": dataEnv['enveloppeBudgetaire']?.toDouble() ?? 0.0,
            "annee": dataStats['annee'] ?? DateTime.now().year.toString(),
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalEngage = _stats['totalDecaisse'] + _stats['enAttente'];
    double enveloppe = _stats['enveloppeBudgetaire'] > 0 ? _stats['enveloppeBudgetaire'] : 1.0;
    double ratio = totalEngage / enveloppe;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Trésorerie Annuelle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
        children: [
          // En-tête avec montant décaissé
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 100, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [primaryColor, Colors.teal[400]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Column(
              children: [
                Text("DÉCAISSÉ RÉEL (${_stats['annee']})",
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Text("${_stats['totalDecaisse']} €",
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoCard(
                  "En attente de traitement",
                  "${_stats['enAttente']} €",
                  "Fiches validées managers non payées",
                  Icons.hourglass_bottom_rounded,
                  Colors.orange,
                ),

                const SizedBox(height: 25),
                const Text("CONSOMMATION DU BUDGET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 15),

                // Carte budget : engagé vs enveloppe avec barre de progression
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Engagé vs Enveloppe", style: TextStyle(fontWeight: FontWeight.w600)),
                            Text("${(ratio * 100).toStringAsFixed(1)} %",
                                style: TextStyle(color: ratio > 0.9 ? Colors.red : Colors.teal, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        LinearProgressIndicator(
                          value: ratio > 1.0 ? 1.0 : ratio,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: Colors.grey[200],
                          color: ratio > 0.9 ? Colors.red : Colors.teal,
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _amountLabel("Total engagé", "$totalEngage €"),
                            _amountLabel("Budget max", "${_stats['enveloppeBudgetaire']} €"),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte d'info (titre, valeur, sous-titre, icône)
  Widget _buildInfoCard(String title, String val, String sub, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _amountLabel(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}