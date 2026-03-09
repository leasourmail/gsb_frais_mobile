// Écran profil : affichage et modification des infos personnelles (nom, prénom, tél, mot de passe, adresse pour visiteur)
// Données chargées depuis mon-profil, sauvegarde via update-mon-profil

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _adresseCtrl = TextEditingController();
  final TextEditingController _villeCtrl = TextEditingController();
  final TextEditingController _cpCtrl = TextEditingController();
  final TextEditingController _telCtrl = TextEditingController();
  final TextEditingController _mdpCtrl = TextEditingController();

  String _dateEmbauche = "Chargement...";
  String _nomManager = "Chargement...";
  String _role = "Chargement...";
  bool _isLoading = true;
  bool _isVisiteur = false;

  @override
  void initState() {
    super.initState();
    _fetchProfilFromServer();
  }

  /// Récupère le profil complet depuis l'API et remplit le formulaire ; si visiteur, on affiche date embauche + manager
  Future<void> _fetchProfilFromServer() async {
    final String? token = await _storage.read(key: "jwt");
    final String? email = await _storage.read(key: "email");

    if (email == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/utilisateurs/mon-profil?email=$email"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nomCtrl.text = data['nom'] ?? "";
          _prenomCtrl.text = data['prenom'] ?? "";
          _emailCtrl.text = data['email'] ?? "";
          _telCtrl.text = data['telephone'] ?? "";
          _role = data['role'] ?? "";

          if (data.containsKey('adresse')){
            _isVisiteur = true;
            _adresseCtrl.text = data['adresse'];
            _villeCtrl.text = data['ville'];
            _cpCtrl.text = data['codePostal'];
            _dateEmbauche = data['dateEmbauche'];
            _nomManager = data['nomManager'] ?? "Aucun manager affilié";
          } else {
            _isVisiteur = false;
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion au serveur")));
    }
  }

  /// Envoie les modifications au backend ; le mot de passe est optionnel mais validé si renseigné
  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final String? token = await _storage.read(key: "jwt");
    final String? email = await _storage.read(key: "email");

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/utilisateurs/update-mon-profil"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "oldEmail": email,
          "nom": _nomCtrl.text,
          "prenom": _prenomCtrl.text,
          "email": email,
          "adresse": _adresseCtrl.text,
          "ville": _villeCtrl.text,
          "codePostal": _cpCtrl.text,
          "telephone": _telCtrl.text,
          "password": _mdpCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        _mdpCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mis à jour !")));
        _fetchProfilFromServer();
      } else {
        setState(() => _isLoading = false);
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = errorData['error'] ?? "Erreur lors de la mise à jour";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur serveur"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isManager = _role == 'ROLE_MANAGER';
    final bool isComptable = _role == 'ROLE_COMPTABLE';

    Color primaryColor;
    if (isManager) {
      primaryColor = Colors.indigo[900]!; // Couleur spécifique Manager
    } else if (isComptable) {
      primaryColor = Colors.teal[800]!; // Couleur spécifique Comptable
    } else {
      primaryColor = Colors.blue[900]!; // Couleur Visiteur par défaut
    }


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Mon Profil GSB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // En-tête (couleur selon le rôle : bleu visiteur, indigo manager, teal comptable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 100, left: 25, right: 25, bottom: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Paramètres", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text("Mon Profil", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.person_pin, color: Colors.white, size: 50),
              ],
            ),
          ),

          // Formulaire : nom, prénom, email (lecture seule), tél, puis champs visiteur si besoin, mot de passe optionnel
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_nomCtrl, "Nom", Icons.badge),
                    _buildTextField(_prenomCtrl, "Prénom", Icons.person_outline),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TextFormField(
                        controller: _emailCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Email (Non modifiable)",
                          icon: Icon(Icons.email),
                          filled: true,
                          fillColor: Color(0xFFEEEEEE),
                        ),
                      ),
                    ),

                    _buildTextField(_telCtrl, "Téléphone", Icons.phone),

                    // Bloc visible uniquement pour un visiteur (rattaché à un manager) : date embauche, manager, adresse, code postal, ville
                    if (_isVisiteur) ...[
                      TextFormField(
                        controller: TextEditingController(text: _dateEmbauche),
                        decoration: const InputDecoration(labelText: "Date d'embauche", icon: Icon(Icons.calendar_today)),
                        enabled: false,
                      ),
                      TextFormField(
                        controller: TextEditingController(text: _nomManager),
                        decoration: const InputDecoration(
                          labelText: "Mon Manager (Responsable)",
                          icon: Icon(Icons.supervisor_account),
                        ),
                        enabled: false,
                      ),
                      _buildTextField(_adresseCtrl, "Adresse", Icons.home),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_cpCtrl, "Code Postal", Icons.map)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_villeCtrl, "Ville", Icons.location_city)),
                        ],
                      ),
                    ],

                    TextFormField(
                      controller: _mdpCtrl,
                      decoration: const InputDecoration(
                        labelText: "Changer le mot de passe",
                        icon: Icon(Icons.lock_outline),
                        helperText: "Min. 8 caractères, 1 majuscule, 1 chiffre, 1 spécial.",
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 8) return "Minimum 8 caractères";
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                              .hasMatch(value)) {
                            return "Le mot de passe n'est pas assez complexe";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _sauvegarder,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: const Text("ENREGISTRER LES MODIFICATIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Champ texte réutilisable avec validation "champ requis"
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, icon: Icon(icon)),
        validator: (v) => v!.isEmpty ? "Champ requis" : null,
      ),
    );
  }
}