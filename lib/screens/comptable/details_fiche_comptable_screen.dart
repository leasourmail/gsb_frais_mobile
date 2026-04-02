// Détail d'une fiche pour le comptable : forfaits, hors-forfait, boutons Refuser / Mettre en paiement

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailsFicheComptableScreen extends StatefulWidget {
  final Map<String, dynamic> fiche;

  const DetailsFicheComptableScreen({super.key, required this.fiche});

  @override
  State<DetailsFicheComptableScreen> createState() => _DetailsFicheComptableScreenState();
}

class _DetailsFicheComptableScreenState extends State<DetailsFicheComptableScreen> {
  final _storage = const FlutterSecureStorage();
  final TextEditingController _refusController = TextEditingController();
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  final Color comptableColor = Colors.teal[800]!;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _refusController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    final String? token = await _storage.read(key: "jwt");
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/api/frais/consulter?email=${widget.fiche['emailVisiteur']}&mois=${widget.fiche['mois']}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _details = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Passe la fiche en état Mise_en_paiement 
  Future<void> _mettreEnPaiement() async {
    setState(() => _isLoading = true);
    final String? token = await _storage.read(key: "jwt");

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8080/api/frais/valider-fiche/${widget.fiche['idFiche']}?nouvelEtat=Mise_en_paiement"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        _showSnackBar("Fiche mise en paiement !", Colors.teal);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- ACTION : REFUSER LA FICHE ---
  Future<void> _refuserFiche(String motif) async {
    if (motif.trim().isEmpty) {
      _showSnackBar("Le motif est obligatoire pour un refus", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final String? token = await _storage.read(key: "jwt");

    try {
      final String url = "http://localhost:8080/api/frais/valider-fiche/${widget.fiche['idFiche']}?nouvelEtat=Refusee&commentaire=${Uri.encodeComponent(motif)}";

      final response = await http.put(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        _showSnackBar("Fiche refusée avec succès", Colors.redAccent);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Erreur lors du refus", Colors.red);
    }
  }

  /// Ouvre le dialogue pour saisir le motif de refus
  void _showRefusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Refuser la fiche"),
        content: TextField(
          controller: _refusController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Saisissez le motif du refus...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final motif = _refusController.text;
              Navigator.pop(ctx);
              _refuserFiche(motif);
            },
            child: const Text("CONFIRMER LE REFUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  /// Affiche l'image du justificatif dans une boîte de dialogue
  void _afficherJustificatif(String fileName) async {
    final String? token = await _storage.read(key: "jwt");
    final String imageUrl = "http://localhost:8080/api/frais/uploads/$fileName";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text("Justificatif", style: TextStyle(fontSize: 18)),
              backgroundColor: comptableColor,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Image.network(
                imageUrl,
                headers: {"Authorization": "Bearer $token"},
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Détails Fiche", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${widget.fiche['visiteurPrenom'] ?? ''} ${widget.fiche['visiteurNom'] ?? 'Visiteur'}",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Mois : ${widget.fiche['mois'] ?? 'Inconnu'}", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text("TOTAL : ${widget.fiche['montantTotal']?.toString() ?? '0'} €",
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Forfaits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildForfaitCard(),
                  const SizedBox(height: 25),
                  const Text("Hors-Forfait", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildHorsForfaitList(),
                  const SizedBox(height: 40),

                  // --- ZONE BOUTONS ---
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: _showRefusDialog,
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text("REFUSER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _mettreEnPaiement,
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text("PAYER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte forfaits (nuitées, repas, km, étape)
  Widget _buildForfaitCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _rowForfait("Nuitées", _details?['nuitees']),
            _rowForfait("Repas", _details?['repas']),
            _rowForfait("Kilométrage", _details?['km']),
            _rowForfait("Étape", _details?['etape']),
          ],
        ),
      ),
    );
  }

  Widget _rowForfait(String label, dynamic val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(val?.toString() ?? "0", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  /// Liste des lignes hors-forfait avec lien vers justificatif
  Widget _buildHorsForfaitList() {
    List horsForfait = _details?['horsForfait'] ?? [];
    if (horsForfait.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aucun frais hors-forfait")));
    }
    return Column(
      children: horsForfait.map((item) {
        String? urlImage = item['urlJustificatif'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.teal),
            title: Text(item['libelle'] ?? "Frais", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item['dateFrais']} - ${item['montant']} €"),
            trailing: urlImage != null && urlImage.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.visibility, color: Colors.teal),
              onPressed: () => _afficherJustificatif(urlImage),
            )
                : const Icon(Icons.no_photography, color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }
}