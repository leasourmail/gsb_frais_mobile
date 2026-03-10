// Liste des fiches de frais d'un visiteur donné (récupérées via API frais/visiteur/{id})

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details_fiche_visiteur_Screen.dart';

class ConsulterFichesVisiteurScreen extends StatefulWidget {
  final int idVisiteur;
  final String nomVisiteur;
  final String emailVisiteur;

  const ConsulterFichesVisiteurScreen({
    super.key,
    required this.idVisiteur,
    required this.nomVisiteur,
    required this.emailVisiteur,
  });

  @override
  State<ConsulterFichesVisiteurScreen> createState() => _ConsulterFichesVisiteurScreenState();
}

class _ConsulterFichesVisiteurScreenState extends State<ConsulterFichesVisiteurScreen> {
  final _storage = const FlutterSecureStorage();
  List _fiches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFichesDuVisiteur();
  }

  Future<void> _fetchFichesDuVisiteur() async {
    final String? token = await _storage.read(key: "jwt");

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/frais/visiteur/${widget.idVisiteur}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        // Trier : Transmise en premier, puis par mois décroissant
        data.sort((a, b) {
          if (a['etat'] == 'Transmise' && b['etat'] != 'Transmise') return -1;
          if (a['etat'] != 'Transmise' && b['etat'] == 'Transmise') return 1;
          return b['mois'].compareTo(a['mois']); // Plus récent en haut
        });

        setState(() {
          _fiches = data;
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

  /// Badge de statut (À VALIDER, VALIDÉE, REFUSÉE, etc.) avec couleur selon l'état
  Widget _buildStatusChip(String etat) {
    Color color;
    String label;
    String etatLower = etat.toLowerCase();

    if (etatLower.contains('transmise')) {
      color = Colors.orange;
      label = "À VALIDER";
    } else if (etatLower.contains('validee')) {
      color = Colors.green;
      label = "VALIDÉE";
    } else if (etatLower.contains('refusee')) {
      color = Colors.red;
      label = "REFUSÉE";
    } else if (etatLower.contains('paiement') || etatLower.contains('remboursee')) {
      color = Colors.blue;
      label = "TRAITÉE";
    } else {
      color = Colors.blueGrey;
      label = "EN COURS";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Convertit yyyyMM en "Jan. 2025" par exemple
  String _formaterMois(String moisRaw) {
    try {
      String annee = moisRaw.substring(0, 4);
      String moisNum = moisRaw.substring(4);
      const moisNoms = {
        '01': 'Jan.', '02': 'Fév.', '03': 'Mar.', '04': 'Avr.',
        '05': 'Mai', '06': 'Juin', '07': 'Juil.', '08': 'Août',
        '09': 'Sep.', '10': 'Oct.', '11': 'Nov.', '12': 'Déc.',
      };
      return "${moisNoms[moisNum]} $annee";
    } catch (e) {
      return moisRaw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color managerColor = Colors.indigo[900]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Fiches de frais", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête avec nom du visiteur et email
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 100, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [managerColor, managerColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.emailVisiteur, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(widget.nomVisiteur, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Icon(Icons.folder_shared, color: Colors.white, size: 50),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: managerColor))
                : _fiches.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _fiches.length,
              itemBuilder: (context, index) {
                final fiche = _fiches[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: managerColor.withOpacity(0.1),
                      child: Icon(Icons.description, color: managerColor),
                    ),
                    title: Text(
                      _formaterMois(fiche['mois']),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        "Total : ${fiche['montantTotal'] ?? 0} €",
                        style: TextStyle(color: managerColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    trailing: _buildStatusChip(fiche['etat'] ?? ""),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsFicheVisiteurScreen(
                            idFiche: fiche['idFiche'],
                            mois: fiche['mois'],
                            nomVisiteur: widget.nomVisiteur,
                            emailVisiteur: widget.emailVisiteur,
                          ),
                        ),
                      ).then((_) => _fetchFichesDuVisiteur());
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

  /// Message quand le visiteur n'a aucune fiche
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Historique vide pour ce visiteur.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}