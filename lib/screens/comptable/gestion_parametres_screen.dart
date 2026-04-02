// Configuration réservée au comptable : modification des tarifs forfaits et de l'enveloppe budgétaire
// Appels API tarifs-forfaits, stats-manager, modifier-tarif, modifier-enveloppe

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GestionParametresScreen extends StatefulWidget {
  const GestionParametresScreen({super.key});

  @override
  State<GestionParametresScreen> createState() => _GestionParametresScreenState();
}

class _GestionParametresScreenState extends State<GestionParametresScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _tarifs = [];
  double _enveloppe = 0.0;
  bool _isLoading = true;

  final Color primaryColor = Colors.teal[800]!;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Charge les tarifs forfaits et l'enveloppe budgétaire (stats-manager/1 pour l'enveloppe)
  Future<void> _loadAllData() async {
    final String? token = await _storage.read(key: "jwt");
    try {
      final resTarifs = await http.get(
        Uri.parse("http://localhost:8080/api/frais/tarifs-forfaits"),
        headers: {"Authorization": "Bearer $token"},
      );

      final resStats = await http.get(
        Uri.parse("http://localhost:8080/api/frais/stats-manager/1"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        setState(() {
          _tarifs = jsonDecode(resTarifs.body);
          var stats = jsonDecode(resStats.body);
          _enveloppe = stats['enveloppeBudgetaire']?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Met à jour un tarif forfait 
  Future<void> _updateTarif(int id, double montant) async {
    final String? token = await _storage.read(key: "jwt");
    final response = await http.put(
      Uri.parse("http://localhost:8080/api/frais/modifier-tarif/$id?montant=$montant"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      _loadAllData();
      _showSnackBar("Tarif mis à jour !", Colors.teal);
    }
  }

  /// Met à jour l'enveloppe budgétaire globale 
  Future<void> _updateEnveloppe(double montant) async {
    final String? token = await _storage.read(key: "jwt");
    final response = await http.put(
      Uri.parse("http://localhost:8080/api/frais/modifier-enveloppe?montant=$montant"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      _loadAllData();
      _showSnackBar("Enveloppe budgétaire mise à jour !", Colors.blue);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  /// Ouvre un dialogue pour modifier un montant (tarif ou enveloppe)
  void _showEditDialog(String title, double currentVal, Function(double) onSave) {
    TextEditingController controller = TextEditingController(text: currentVal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Modifier $title"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Nouveau montant",
            suffixText: "€",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              double? val = double.tryParse(controller.text);
              if (val != null) {
                onSave(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Configuration GSB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
        children: [
          // En-tête
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Paramètres métier", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Gestion des tarifs et du budget annuel", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("TARIFS DES FORFAITS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                ..._tarifs.map((t) => _buildSettingsCard(
                  t['libelle'],
                  "${t['montant']} €",
                  Icons.euro_symbol,
                  Colors.teal,
                      () => _showEditDialog(t['libelle'], t['montant'].toDouble(), (val) => _updateTarif(t['idForfait'], val)),
                )),

                const SizedBox(height: 30),
                const Text("COMPTABILITÉ GLOBALE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                _buildSettingsCard(
                  "Enveloppe Budgétaire",
                  "$_enveloppe €",
                  Icons.account_balance_wallet,
                  Colors.blue[700]!,
                      () => _showEditDialog("l'enveloppe", _enveloppe, (val) => _updateEnveloppe(val)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte paramètre (titre, valeur actuelle, clic pour modifier)
  Widget _buildSettingsCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Valeur actuelle : $value", style: const TextStyle(color: Colors.black54)),
        trailing: Icon(Icons.edit, color: primaryColor),
        onTap: onTap,
      ),
    );
  }
}