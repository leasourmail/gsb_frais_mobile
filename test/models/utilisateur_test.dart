// Tests unitaires du modèle Utilisateur (désérialisation JSON)
// À lancer avec : flutter test test/models/utilisateur_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gsb_frais_appli/models/utilisateur.dart';

void main() {
  group('Utilisateur.fromJson', () {
    test('crée un utilisateur à partir d\'un JSON complet', () {
      final json = {
        'idUtilisateur': 1,
        'email': 'jean.dupont@gsb.fr',
        'role': 'ROLE_VISITEUR',
        'token': 'abc123',
        'nom': 'Dupont',
        'prenom': 'Jean',
      };

      final user = Utilisateur.fromJson(json);

      expect(user.idUtilisateur, 1);
      expect(user.email, 'jean.dupont@gsb.fr');
      expect(user.role, 'ROLE_VISITEUR');
      expect(user.token, 'abc123');
      expect(user.nom, 'Dupont');
      expect(user.prenom, 'Jean');
    });

    test('utilise 0 pour idUtilisateur si absent du JSON', () {
      final json = {
        'email': 'test@gsb.fr',
        'role': 'ROLE_MANAGER',
        'token': 'xyz',
        'nom': 'Martin',
        'prenom': 'Marie',
      };

      final user = Utilisateur.fromJson(json);

      expect(user.idUtilisateur, 0);
      expect(user.email, 'test@gsb.fr');
    });
  });
}
