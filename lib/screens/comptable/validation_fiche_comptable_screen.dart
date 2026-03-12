// Liste des fiches "à payer" (validées par le manager) : le comptable peut les mettre en paiement ou les refuser
// Données depuis l'endpoint a-payer

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details_fiche_comptable_screen.dart';

class ValidationFichesComptableScreen extends StatefulWidget {
  const ValidationFichesComptableScreen({super.key});

  @override
  State<ValidationFichesComptableScreen> createState() => _ValidationFichesComptableScreenState();
}

class _ValidationFichesComptableScreenState extends State<ValidationFichesComptableScreen> {
  final _storage = const FlutterSecureStorage();
  List _fichesAValider = [];
  bool _isLoading = true;
  final Color comptableColor = Colors.teal[800]!;

  @override
  void initState() {
    super.initState();
    _fetchFichesAValider();
  }

  /// Récupère la liste des fiches en attente de mise en paiement (API a-payer)
  Future<void> _fetchFichesAValider() async {
    try {
      final String? token = await _storage.read(key: "jwt");
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/frais/a-payer"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _fichesAValider = jsonDecode(response.body);
        });
      } else {
        print("Erreur HTTP: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur réseau: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Validation Paiements", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                colors: [comptableColor, comptableColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${_fichesAValider.length} fiches en attente", style: const TextStyle(color: Colors.white70)),
                    const Text("Mise en paiement", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.payments, color: Colors.white, size: 50),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _fichesAValider.length,
              itemBuilder: (context, index) {
                final fiche = _fichesAValider[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    title: Text("${fiche['visiteurNom']} ${fiche['visiteurPrenom']}"),
                    subtitle: Text("Mois : ${fiche['mois']} - Montant : ${fiche['montantTotal']} €"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsFicheComptableScreen(fiche: fiche),
                        ),
                      ).then((_) => _fetchFichesAValider());
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
}