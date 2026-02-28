// Modèle qui représente un utilisateur connecté (visiteur, manager ou comptable)
// Les données viennent du backend Spring Boot après le login

class Utilisateur {
  final String email;
  final String role;
  final String token;
  final int idUtilisateur;
  final String nom;
  final String prenom;

  Utilisateur({required this.idUtilisateur, required this.email, required this.role, required this.token, required this.nom, required this.prenom});

  // Pour transformer le JSON de l'API en objet Flutter
  factory Utilisateur.fromJson(Map<String, dynamic> json){
    return Utilisateur(
      idUtilisateur: json['idUtilisateur'] ?? 0, // au cas où le backend ne renvoie pas l'id
      email: json['email'],
      role: json['role'],
      token: json['token'],
      nom: json['nom'],
      prenom: json['prenom'],
    );
  }
}