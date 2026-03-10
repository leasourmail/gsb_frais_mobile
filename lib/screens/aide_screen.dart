// Centre d'aide : FAQ selon le rôle (visiteur / manager / comptable) + contact support (mail, téléphone)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AideScreen extends StatelessWidget {
  final String role;
  const AideScreen({super.key, required this.role});

  /// Ouvre l'app téléphone pour appeler le numéro du support
  Future<void> _faireAppel(String numero) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: numero,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Impossible de lancer l\'appel vers $numero';
    }
  }

  // Fonction pour envoyer un email au support
  Future<void> _envoyerMail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Assistance GSB - Appli Mobile&body=Bonjour, j\'ai un problème avec...',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Impossible d\'ouvrir l\'application de mail';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isManager = role == 'ROLE_MANAGER';
    bool isComptable = role == 'ROLE_COMPTABLE';

    // Définition des couleurs selon le rôle : manager (indigo), comptable (teal), visiteur (bleu)
    Color primaryColor;
    Color secondaryColor;
    if (isManager) {
      primaryColor = Colors.indigo[900]!;
      secondaryColor = Colors.indigo[700]!;
    } else if (isComptable) {
      primaryColor = Colors.teal[800]!;
      secondaryColor = Colors.teal[600]!;
    } else {
      primaryColor = Colors.blue[900]!;
      secondaryColor = Colors.blue[600]!;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Centre d'aide GSB",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                colors: [primaryColor, secondaryColor],
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
                    Text("Assistance",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text("Besoin d'aide ?",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.help_center_outlined, color: Colors.white, size: 50),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Comment pouvons-nous vous aider ?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Section dynamique du titre
                  _buildSectionTitle(
                      "Foire aux questions ${isManager ? 'Responsable' : isComptable ? 'Comptable' : 'Visiteur'}",
                      primaryColor),

                  // Questions communes à tous les roles
                  _buildFaqItem("J'ai perdu mon mot de passe",
                      "Contactez le support IT via le bouton ci-dessous pour une réinitialisation."),

                  // Questions spécifiques au COMPTABLE
                  if (isComptable) ...[
                    _buildFaqItem(
                      "Comment mettre une fiche en paiement ?",
                      "Une fois dans la rubrique 'Validation Paiements', sélectionnez une fiche validée par un manager et cliquez sur le bouton 'Mettre en paiement'.",
                    ),
                    _buildFaqItem(
                      "Quel est le délai de remboursement automatique ?",
                      "Une fois qu'une fiche est passée en 'Mise en paiement', le système la passera automatiquement en 'Remboursée' après un délai de 10 jours.",
                    ),
                    _buildFaqItem(
                      "Puis-je refuser une fiche déjà validée par un manager ?",
                      "Oui, si vous constatez une erreur sur un justificatif ou un montant forfaitaire, vous pouvez rejeter la fiche pour correction.",
                    ),
                  ]
                  // Questions spécifiques au MANAGER
                  else if (isManager) ...[
                    _buildFaqItem(
                      "Comment valider une fiche ?",
                      "Sélectionnez un visiteur dans 'Mes Visiteurs', ouvrez sa fiche et cliquez sur 'Valider' après vérification des justificatifs.",
                    ),
                    _buildFaqItem(
                      "Puis-je modifier la fiche d'un visiteur ?",
                      "Non, vous pouvez uniquement la valider ou la mettre en 'Refusé' avec un motif pour que le visiteur la corrige.",
                    ),
                  ]
                  // Questions spécifiques au VISITEUR
                  else ...[
                      _buildFaqItem(
                        "Comment saisir une nouvelle fiche de frais ?",
                        "Allez dans l'onglet 'Saisie', remplissez les frais forfaitisés ou hors forfait, puis cliquez sur 'Valider'. N'oubliez pas de joindre vos justificatifs.",
                      ),
                      _buildFaqItem(
                        "Quels justificatifs sont acceptés ?",
                        "Nous acceptons les formats JPG, PNG et PDF. La taille maximale par fichier est de 5 Mo.",
                      ),
                      _buildFaqItem(
                        "Quand mes frais sont-ils remboursés ?",
                        "Les fiches sont traitées par le service comptable entre le 1er et le 10 du mois suivant. Le remboursement intervient après validation.",
                      ),
                    ],

                  const SizedBox(height: 30),

                  _buildSectionTitle("Contactez le support", primaryColor),
                  Card(
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.email, color: primaryColor),
                      title: const Text("Assistance Technique"),
                      subtitle: const Text("support-it@gsb.fr"),
                      onTap: () => _envoyerMail("support-it@gsb.fr"),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.green),
                      title: const Text("Ligne Urgente"),
                      subtitle: const Text("01 45 67 89 00"),
                      onTap: () => _faireAppel("0145678900"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Center(
                    child: Text(
                      "Version de l'application : 1.2.0\n© 2026 Laboratoire GSB",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Titre de section (FAQ ou Contact) avec couleur selon le rôle
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  /// Une question / réponse dépliable 
  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title:
      Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
}