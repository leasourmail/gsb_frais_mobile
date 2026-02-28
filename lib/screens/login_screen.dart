// Écran de connexion : formulaire email / mot de passe puis redirection selon le rôle (visiteur, manager, comptable)

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'visiteur/visiteur_dashboard.dart';
import 'manager/manager_dashboard.dart';
import 'comptable/comptable_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  /// Vérifie les champs, appelle l'API de login et redirige vers le bon dashboard selon le rôle
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.login(_emailController.text, _passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      // On choisit l'écran d'accueil en fonction du rôle renvoyé par le backend
      Widget nextScreen;
      switch (user.role.toUpperCase()) {
        case "ROLE_VISITEUR": nextScreen = const VisiteurDashboard(); break;
        case "ROLE_MANAGER": nextScreen = const ManagerDashboard(); break;
        case "ROLE_COMPTABLE": nextScreen = const ComptableDashboard(); break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Role non reconnu : ${user.role}")));
          return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email ou mot de passe incorrect"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!, Colors.blue[400]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 80),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Connexion", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Bienvenue sur GSB Frais", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 40),
                      // Logo GSB
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Image.asset("assets/images/logo.png", height: 100),
                      ),
                      const SizedBox(height: 40),
                      // Saisie email
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue),
                          hintText: "Email professionnel",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mot de passe avec bouton pour afficher / masquer
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          hintText: "Mot de passe",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Bouton connexion (ou indicateur de chargement pendant l'appel API)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}