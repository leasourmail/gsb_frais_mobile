// Détail d'une fiche pour le manager : forfaits, hors-forfait, boutons Valider / Refuser (si état Transmise)

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailsFicheVisiteurScreen extends StatefulWidget {
  final int idFiche;
  final String mois;
  final String nomVisiteur;
  final String emailVisiteur;

  const DetailsFicheVisiteurScreen({
    super.key,
    required this.idFiche,
    required this.mois,
    required this.nomVisiteur,
    required this.emailVisiteur,
  });

  @override
  State<DetailsFicheVisiteurScreen> createState() => _DetailsFicheVisiteurScreenState();
}

class _DetailsFicheVisiteurScreenState extends State<DetailsFicheVisiteurScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailsFiche();
  }

  /// Récupère le détail de la fiche 
  Future<void> _fetchDetailsFiche() async {
    final String? token = await _storage.read(key: "jwt");
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/frais/consulter?email=${widget.emailVisiteur}&mois=${widget.mois}"),
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

  /// Format "Janvier 2025" pour l'affichage
  String _formaterMois(String moisRaw) {
    try {
      String annee = moisRaw.substring(0, 4);
      String moisNum = moisRaw.substring(4);
      const moisNoms = {
        '01': 'Janvier', '02': 'Février', '03': 'Mars', '04': 'Avril',
        '05': 'Mai', '06': 'Juin', '07': 'Juillet', '08': 'Août',
        '09': 'Septembre', '10': 'Octobre', '11': 'Novembre', '12': 'Décembre',
      };
      return "${moisNoms[moisNum]} $annee";
    } catch (e) { return moisRaw; }
  }

  /// Libellé lisible de l'état de la fiche
  String _formaterEtat(String etatRaw) {
    switch (etatRaw) {
      case 'Saisie_en_cours': return "Saisie en cours";
      case 'Transmise': return "À valider";
      case 'Validee_par_manager': return "Validée";
      case 'Refusee_par_manager': return "Refusée (Motif transmis)";
      case 'Remboursee': return "Payée";
      default: return etatRaw.replaceAll('_', ' ');
    }
  }

  /// Ouvre un dialogue pour saisir le motif du refus puis appelle _changerEtatFiche(Refusee_par_manager)
  void _afficherDialogueRefus() {
    TextEditingController _motifController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Refuser la fiche"),
        content: TextField(
          controller: _motifController,
          decoration: const InputDecoration(
            hintText: "Saisissez le motif du refus...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
          ElevatedButton(
            onPressed: () {
              if (_motifController.text.isNotEmpty) {
                Navigator.pop(context);
                _changerEtatFiche('Refusee_par_manager', commentaire: _motifController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("CONFIRMER LE REFUS"),
          ),
        ],
      ),
    );
  }

  /// Appel API valider-fiche pour passer en Validee_par_manager ou Refusee_par_manager (avec commentaire)
  Future<void> _changerEtatFiche(String nouvelEtat, {String? commentaire}) async {
    setState(() => _isLoading = true);
    final String? token = await _storage.read(key: "jwt");

    String url = "http://10.0.2.2:8080/api/frais/valider-fiche/${widget.idFiche}?nouvelEtat=$nouvelEtat";
    if (commentaire != null) {
      url += "&commentaire=${Uri.encodeComponent(commentaire)}";
    }

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        _fetchDetailsFiche();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nouvelEtat.contains('Validee') ? "Fiche validée !" : "Fiche refusée"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Affiche l'image du justificatif dans une boîte de dialogue
  void _afficherJustificatif(String fileName) async {
    final String? token = await _storage.read(key: "jwt");
    final String imageUrl = "http://10.0.2.2:8080/api/frais/uploads/$fileName";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text("Justificatif numérique"),
              backgroundColor: Colors.indigo[900],
              leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ),
            Image.network(
              imageUrl,
              headers: {"Authorization": "Bearer $token"},
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Erreur de chargement du fichier"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color managerColor = Colors.indigo[900]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Décision Manager", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // En-tête : visiteur, période, badge état
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nomVisiteur, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Période : ${_formaterMois(widget.mois)}", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  child: Text(_formaterEtat(_details?['etat'] ?? ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Frais forfaitisés", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildForfaitGrid(),
                  const SizedBox(height: 25),
                  const Text("Frais Hors-Forfait", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildHorsForfaitList(),
                  const SizedBox(height: 30),
                  if (_details?['etat'] == 'Transmise') _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte récap forfaits (nuitées, repas, km, étape)
  Widget _buildForfaitGrid() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _rowForfait("Nuitées", _details?['nuitees'], Icons.hotel),
            _rowForfait("Repas", _details?['repas'], Icons.restaurant),
            _rowForfait("KM", _details?['km'], Icons.directions_car),
            _rowForfait("Étape", _details?['etape'], Icons.map),
          ],
        ),
      ),
    );
  }

  Widget _rowForfait(String label, dynamic val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(width: 15),
          Text(label),
          const Spacer(),
          Text(val.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  /// Liste des lignes hors-forfait avec lien vers justificatif si présent
  Widget _buildHorsForfaitList() {
    List hf = _details?['horsForfait'] ?? [];
    if (hf.isEmpty) return const Text("Aucun frais hors-forfait.");
    return Column(
      children: hf.map((item) {
        String? urlImage = item['urlJustificatif'];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text(item['libelle']),
            subtitle: Text("${item['dateFrais']} - ${item['montant']} €"),
            trailing: urlImage != null && urlImage.isNotEmpty
                ? IconButton(icon: const Icon(Icons.image, color: Colors.orange), onPressed: () => _afficherJustificatif(urlImage))
                : const Icon(Icons.no_photography, color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }

  /// Boutons Valider (vert) et Refuser (rouge) pour la fiche transmise
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _changerEtatFiche('Validee_par_manager'),
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text("VALIDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _afficherDialogueRefus(),
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text("REFUSER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ),
      ],
    );
  }
}