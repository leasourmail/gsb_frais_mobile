// Test widget : vérifier que l'écran de login affiche les bons éléments
// À lancer avec : flutter test test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsb_frais_appli/main.dart';

void main() {
  testWidgets('L\'écran de connexion affiche le titre et le bouton', (WidgetTester tester) async {
    await tester.pumpWidget(const GsbApp());

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Bienvenue sur GSB Frais'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
  });

  testWidgets('Les champs email et mot de passe sont présents', (WidgetTester tester) async {
    await tester.pumpWidget(const GsbApp());

    expect(find.byType(TextField), findsNWidgets(2));
  });
}
