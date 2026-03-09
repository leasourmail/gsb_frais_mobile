// Consultation des fiches de frais par mois : choix du mois, affichage du statut, forfaits et hors-forfait
// Si la fiche est refusée, on affiche le motif et un bouton pour la corriger

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../services/frais_service.dart';
import 'saisie_frais_screen.dart';

class ConsultationFraisScreen extends StatefulWidget {
  const ConsultationFraisScreen({super.key});

  @override
  State<ConsultationFraisScreen> createState() => _ConsultationFraisScreenState();
}

class _ConsultationFraisScreenState extends State<ConsultationFraisScreen> {
  final FraisService _fraisService = FraisService();
  final _storage = const FlutterSecureStorage();
  String _moisSelectionne = "";
  Map<String, dynamic>? _donneesFiche;
  bool _isLoading = false;

  /// Convertit le code état du backend en libellé lisible pour l'utilisateur
  String _formaterEtat(String etatRaw) {
    switch (etatRaw) {
      case 'Saisie_en_cours': return "Saisie en cours";
      case 'Transmise': return "En attente de validation";
      case 'Validee_par_manager': return "Validée par le Manager";
      case 'Refusee_par_manager': return "Refusée par le Manager";
      case 'Refusee': return "Refusée par comptable";
      case 'Mise_en_paiement': return "Mise en paiement";
      case 'Remboursee': return "Remboursée / Payée";
      default: return etatRaw.replaceAll('_', ' ');
    }
  }

  /// Couleur du badge selon l'état (refusé = rouge, validé = vert, etc.)
  Color _getCouleurEtat(String etatRaw) {
    if (etatRaw.contains('Refusee')) return Colors.red;
    if (etatRaw.contains('Validee') || etatRaw == 'Remboursee') return Colors.green;
    if (etatRaw == 'Transmise') return Colors.orange;
    return Colors.blue;
  }

  /// Ouvre le sélecteur de date (année/mois) puis charge la fiche correspondante
  Future<void> _choisirMois() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: "Sélectionnez le mois à consulter",
    );
    if (picked != null) {
      setState(() {
        _moisSelectionne = DateFormat('yyyyMM').format(picked);
        _donneesFiche = null;
      });
      _chargerFiche();
    }
  }

  /// Appel API pour récupérer la fiche du mois sélectionné
  Future<void> _chargerFiche() async {
    setState(() => _isLoading = true);
    final data = await _fraisService.consulterFicheParMois(_moisSelectionne);
    setState(() {
      _donneesFiche = data;
      _isLoading = false;
    });
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucune fiche trouvée pour ce mois."))
      );
    }
  }

  /// Affiche l'image du justificatif dans une boîte de dialogue (avec token dans les headers)
  void _afficherJustificatif(String fileName) async {
    final String? token = await _storage.read(key: "jwt");

    final String imageUrl = "http://10.0.2.2:8080/api/frais/uploads/$fileName";

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias, // Pour que l'image respecte les bords arrondis
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text("Justificatif numérique", style: TextStyle(fontSize: 18)),
              backgroundColor: Colors.blue[900],
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Image.network(
                imageUrl,
                headers: {
                  "Authorization": "Bearer $token",
                },
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print("Erreur chargement image : $error");
                  return const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.red),
                        SizedBox(height: 10),
                        Text("Fichier introuvable ou accès refusé",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  );
                },
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
        title: const Text("Historique des Fiches", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 100, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [Colors.blue[900]!, Colors.blue[600]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_moisSelectionne == "" ? "Sélectionnez un mois" : "Mois : ${_moisSelectionne.substring(4)}/${_moisSelectionne.substring(0, 4)}",
                        style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const Text("Consultation", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.white, size: 40),
                  onPressed: _choisirMois,
                ),
              ],
            ),
          ),

          // Zone scrollable : statut, éventuel motif refus + bouton corriger, forfaits, hors-forfait
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _donneesFiche == null
                ? _buildEmptyState()
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),

                  // Si la fiche a été refusée, on affiche le motif et le bouton pour corriger
                  if (_donneesFiche!['etat'].toString().contains('Refusee')) ...[
                    if (_donneesFiche!['commentaireRefus'] != null)
                      _buildCommentaireRefus(),
                    _buildBoutonModifier(),
                  ],

                  const SizedBox(height: 20),
                  const Text("Éléments forfaitisés", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildForfaitCard(),

                  const SizedBox(height: 20),
                  const Text("Frais Hors-Forfait", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...(_donneesFiche!['horsForfait'] as List? ?? []).map((hf) => _buildHorsForfaitTile(hf)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affichage quand aucun mois n'est choisi ou qu'il n'y a pas de fiche
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Aucune donnée à afficher", style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: _choisirMois, child: const Text("Choisir un mois"))
        ],
      ),
    );
  }

  /// Carte qui affiche le statut de la fiche (saisie en cours, transmise, validée, etc.)
  Widget _buildStatusCard() {
    String etat = _donneesFiche!['etat']?.toString() ?? "Inconnu";
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _getCouleurEtat(etat).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(Icons.info_outline, color: _getCouleurEtat(etat)),
        title: const Text("Statut de la fiche"),
        subtitle: Text(_formaterEtat(etat), style: TextStyle(color: _getCouleurEtat(etat), fontWeight: FontWeight.bold)),
        trailing: Text(_donneesFiche!['dateModif']?.toString() ?? "", style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  /// Encadré rouge avec le motif du refus renvoyé par le manager ou le comptable
  Widget _buildCommentaireRefus() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text("MOTIF DU REFUS",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
            ],
          ),
          SizedBox(height: 8),
          Text("${_donneesFiche!['commentaireRefus']}", style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  /// Bouton qui ouvre la saisie en mode correction pour le mois concerné
  Widget _buildBoutonModifier() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SaisieFraisScreen(moisAcorriger: _moisSelectionne)),
          ).then((value) => _chargerFiche());
        },
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: const Text("CORRIGER LA FICHE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  /// Carte récap des quantités forfait (nuitées, repas, km, étape)
  Widget _buildForfaitCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildForfaitRow("Nuitées", _donneesFiche!['nuitees'], Icons.hotel),
            _buildForfaitRow("Repas", _donneesFiche!['repas'], Icons.restaurant),
            _buildForfaitRow("KM", _donneesFiche!['km'], Icons.directions_car),
            _buildForfaitRow("Étape", _donneesFiche!['etape'], Icons.map),
          ],
        ),
      ),
    );
  }

  /// Une ligne dans la carte forfait (label + valeur + icône)
  Widget _buildForfaitRow(String label, dynamic valeur, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[300]),
          const SizedBox(width: 10),
          Text(label),
          const Spacer(),
          Text(valeur.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Une carte pour un frais hors-forfait (libellé, date, montant, clic pour voir justificatif)
  Widget _buildHorsForfaitTile(Map<String, dynamic> hf) {
    final String? imageName = hf['urlJustificatif'];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(imageName != null ? Icons.image : Icons.image_not_supported, color: Colors.blue[200]),
        title: Text(hf['libelle'] ?? "Sans libellé"),
        subtitle: Text("${hf['dateFrais']} - ${hf['montant']}€"),
        trailing: imageName != null ? const Icon(Icons.visibility, color: Colors.blue) : null,
        onTap: imageName != null ? () => _afficherJustificatif(imageName) : null,
      ),
    );
  }
}