// Saisie et modification des frais : forfaits (nuitées, repas, km, étape) + hors-forfait avec photo justificatif
// Si moisAcorriger est renseigné, on est en mode "correction" d'une fiche refusée

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/frais_service.dart';

class SaisieFraisScreen extends StatefulWidget {
  /// Si non null, on charge la fiche de ce mois pour correction (format yyyyMM)
  final String? moisAcorriger;

  const SaisieFraisScreen({super.key, this.moisAcorriger});

  @override
  State<SaisieFraisScreen> createState() => _SaisieFraisScreenState();
}

class _SaisieFraisScreenState extends State<SaisieFraisScreen> {
  final FraisService _fraisService = FraisService();
  final _storage = const FlutterSecureStorage();
  final _formKeyForfait = GlobalKey<FormState>();
  final _formKeyHF = GlobalKey<FormState>();

  final TextEditingController _nuiteesCtrl = TextEditingController();
  final TextEditingController _repasCtrl = TextEditingController();
  final TextEditingController _kmCtrl = TextEditingController();
  final TextEditingController _etapeCtrl = TextEditingController();
  final TextEditingController _libelleHFCtrl = TextEditingController();
  final TextEditingController _montantHFCtrl = TextEditingController();

  DateTime? _selectedDate;
  File? _imageFile;
  int? _idFiche;
  List<dynamic> _horsForfaits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  /// Charge la fiche du mois (courant ou à corriger) et remplit les champs forfait + liste hors-forfait
  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    try {
      final String moisATraiter = widget.moisAcorriger ?? DateFormat('yyyyMM').format(DateTime.now());
      final data = await _fraisService.consulterFicheParMois(moisATraiter);

      if (data != null) {
        setState(() {
          _idFiche = data['idFiche']; // C'est ICI que l'ID est récupéré après création
          _horsForfaits = data['horsForfait'] ?? [];
          _nuiteesCtrl.text = (data['nuitees'] ?? 0).toString();
          _repasCtrl.text = (data['repas'] ?? 0).toString();
          _kmCtrl.text = (data['km'] ?? 0).toString();
          _etapeCtrl.text = (data['etape'] ?? 0).toString();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _afficherMessage("Erreur de chargement");
    }
  }

  /// En mode correction : soumet à nouveau la fiche après modification 
  Future<void> _renvoyerFiche() async {
    if (_idFiche == null) return;
    setState(() => _isLoading = true);
    final String? token = await _storage.read(key: "jwt");

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/frais/soumettre-fiche/$_idFiche"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        _afficherMessage("Fiche rectifiée et transmise !");
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
        _afficherMessage("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _afficherMessage("Erreur réseau");
    }
  }

  /// Ouvre une boîte de dialogue pour afficher l'image du justificatif (appel API avec token)
  void _voirJustificatif(String fileName) async {
    final String? token = await _storage.read(key: "jwt");
    final String imageUrl = "http://10.0.2.2:8080/api/frais/uploads/$fileName";
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: const Text("Justificatif"), backgroundColor: Colors.blue[900]),
            Image.network(
              imageUrl,
              headers: {"Authorization": "Bearer $token"},
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Erreur de chargement"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre la caméra pour prendre une photo 
  Future<void> _prendrePhoto(StateSetter setStateDialog) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setStateDialog(() { _imageFile = File(pickedFile.path); });
    }
  }

  /// Envoie les quantités forfait à l'API puis recharge les données
  void _validerForfaits() async {
    if (_formKeyForfait.currentState!.validate()) {
      setState(() => _isLoading = true);

      // On récupère l'email stocké
      final String? email = await _storage.read(key: "email");

      if (email == null) {
        setState(() => _isLoading = false);
        _afficherMessage("Erreur : session expirée");
        return;
      }

      // Appel au service
      bool succes = await _fraisService.majFraisForfait(
        _idFiche,
        int.parse(_nuiteesCtrl.text),
        int.parse(_repasCtrl.text),
        int.parse(_kmCtrl.text),
        int.parse(_etapeCtrl.text),
        email,
      );

      if (succes) {
        await _chargerDonnees();
        _afficherMessage("Enregistré avec succès");
      } else {
        setState(() => _isLoading = false);
        _afficherMessage("Erreur lors de l'enregistrement");
      }
    }
  }

  /// Ajoute la ligne hors-forfait (avec photo si choisie) et ferme le dialogue
  void _ajouterHorsForfait() async {
    if (_formKeyHF.currentState!.validate() && _selectedDate != null && _idFiche != null) {
      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      bool succes = await _fraisService.ajouterHorsForfaitAvecImage(
        _idFiche!, _libelleHFCtrl.text, dateStr, double.parse(_montantHFCtrl.text), _imageFile,
      );
      if (succes) {
        Navigator.pop(context);
        _libelleHFCtrl.clear();
        _montantHFCtrl.clear();
        _selectedDate = null;
        _imageFile = null;
        _chargerDonnees();
      }
    } else if (_selectedDate == null) {
      _afficherMessage("Veuillez choisir une date");
    }
  }

  /// Demande confirmation avant de supprimer une ligne hors-forfait
  void _confirmerSuppression(int idLigne) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer ce frais hors forfait ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            if(await _fraisService.supprimerHorsForfait(idLigne)) _chargerDonnees();
          }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _afficherMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Bouton "Renvoyer la fiche" uniquement en mode correction (fiche refusée)
    bool afficherBoutonTransmission = widget.moisAcorriger != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.moisAcorriger != null ? "Correction Fiche" : "Saisie Frais",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ENTÊTE DÉGRADÉE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 100, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [Colors.blue[900]!, Colors.blue[600]!],
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.moisAcorriger ?? "Mois en cours", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const Text("Saisie Frais", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.edit_calendar, color: Colors.white, size: 50),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Bloc forfaits : nuitées, repas, km, étape
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKeyForfait,
                        child: Column(
                          children: [
                            const Text("Forfaits standards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const Divider(height: 30),
                            _buildNumericField("Nuitées", _nuiteesCtrl, Icons.hotel),
                            _buildNumericField("Repas", _repasCtrl, Icons.restaurant),
                            _buildNumericField("KM", _kmCtrl, Icons.directions_car),
                            _buildNumericField("Étape", _etapeCtrl, Icons.map),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _validerForfaits,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                                child: const Text("ENREGISTRER FORFAITS", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Liste des lignes hors-forfait avec possibilité de voir le justificatif ou supprimer
                  const Align(alignment: Alignment.centerLeft, child: Text("Frais Hors-Forfait", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _horsForfaits.length,
                    itemBuilder: (context, index) {
                      final item = _horsForfaits[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(item['urlJustificatif'] != null ? Icons.image : Icons.image_not_supported, color: Colors.blue),
                            onPressed: item['urlJustificatif'] != null ? () => _voirJustificatif(item['urlJustificatif']) : null,
                          ),
                          title: Text(item['libelle']),
                          subtitle: Text("${item['dateFrais']} - ${item['montant']}€"),
                          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmerSuppression(item['idLigneHf'])),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Affiché seulement en correction
                  if (afficherBoutonTransmission)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _renvoyerFiche,
                        icon: const Icon(Icons.send, color: Colors.white),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        label: const Text("RENVOYER LA FICHE CORRIGÉE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bouton pour ajouter un frais hors-forfait (ouvre le dialogue avec formulaire + photo)
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHFDialog,
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  /// Ouvre le dialogue pour saisir libellé, montant, date et optionnellement une photo
  void _showAddHFDialog() {
    _imageFile = null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Nouveau hors forfait"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKeyHF,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: _libelleHFCtrl, decoration: const InputDecoration(labelText: "Libellé"), validator: (v) => v!.isEmpty ? "Requis" : null),
                  TextFormField(controller: _montantHFCtrl, decoration: const InputDecoration(labelText: "Montant (€)"), keyboardType: TextInputType.number, validator: (v) => double.tryParse(v!) == null ? "Numérique attendu" : null),
                  ListTile(
                    title: Text(_selectedDate == null ? "Date" : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
                      if (picked != null) setStateDialog(() => _selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_imageFile != null) Image.file(_imageFile!, height: 80),
                  TextButton.icon(onPressed: () => _prendrePhoto(setStateDialog), icon: const Icon(Icons.camera_alt), label: const Text("Photo")),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(onPressed: _ajouterHorsForfait, child: const Text("Ajouter")),
          ],
        ),
      ),
    );
  }

  /// Champ numérique réutilisable pour forfaits (nuitées, repas, km, étape)
  Widget _buildNumericField(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        keyboardType: TextInputType.number,
      ),
    );
  }
}