// Point d'entrée de l'application GSB Frais (gestion des notes de frais)
// Projet BTS SIO SLAM - Application mobile Android

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const GsbApp());
}

// Classe principale de l'application (affiche l'écran de connexion au démarrage)
class GsbApp extends StatelessWidget {
  const GsbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GSB Frais',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF004A99),
          visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}
