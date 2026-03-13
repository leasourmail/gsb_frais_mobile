# GSB Frais – Application mobile

Application mobile de gestion des notes de frais pour le laboratoire GSB (Galaxy Swiss Bourdin).  
Projet réalisé dans le cadre d’un BTS SIO option SLAM.

## Description

L’application permet aux **visiteurs** de saisir et consulter leurs fiches de frais (forfaits et hors-forfait avec justificatifs), aux **managers** de valider ou refuser les fiches de leur équipe et de suivre les statistiques, et aux **comptables** de mettre les fiches en paiement, gérer la trésorerie et les paramètres (tarifs, enveloppe budgétaire).

- **Front-end :** Flutter (Dart)  
- **Back-end :** API REST Spring Boot (Java) – à lancer séparément

## Prérequis

- [Flutter](https://flutter.dev/docs/get-started/install) (SDK ^3.10.8)
- Android Studio ou VS Code avec les extensions Flutter / Dart
- L’API Spring Boot du projet GSB doit être démarrée (ex. sur `http://localhost:8080`)

## Installation et lancement

```bash
# Cloner le projet (ou ouvrir le dossier existant)
cd gsb_frais_appli

# Installer les dépendances
flutter pub get

# Lancer l’application sur un émulateur ou un appareil connecté
flutter run
```

## Configuration de l’API

L’application appelle l’API à l’adresse **`http://10.0.2.2:8080`** (configurée dans `auth_service.dart` et `frais_service.dart`).  

- **10.0.2.2** = localhost vu depuis l’émulateur Android.  
- Sur un appareil physique, remplacer par l’IP de la machine qui héberge l’API (ex. `http://192.168.1.10:8080`).

## Rôles et fonctionnalités

| Rôle        | Fonctionnalités principales                                      |
|------------|-------------------------------------------------------------------|
| **Visiteur** | Saisie des frais (forfaits + hors-forfait avec photo), consultation des fiches, correction si refus, profil, aide |
| **Manager**  | Liste des visiteurs, consultation et validation/refus des fiches, suivi statistiques (budget, catégories), profil, aide |
| **Comptable** | Validation des fiches (mise en paiement / refus), suivi trésorerie, configuration (tarifs, enveloppe), profil, aide |

## Structure du projet

```
lib/
├── main.dart                 # Point d'entrée, thème, écran de login
├── models/
│   └── utilisateur.dart      # Modèle utilisateur (désérialisation JSON)
├── services/
│   ├── auth_service.dart     # Connexion, token JWT, stockage sécurisé
│   └── frais_service.dart   # Appels API fiches de frais (forfaits, hors-forfait, etc.)
└── screens/
    ├── login_screen.dart
    ├── profil_screen.dart
    ├── aide_screen.dart
    ├── visiteur/             # Dashboard, saisie, consultation
    ├── manager/              # Dashboard, liste visiteurs, fiches, stats
    └── comptable/            # Dashboard, validation, paiements, paramètres

test/
├── models/
│   └── utilisateur_test.dart # Tests unitaires du modèle Utilisateur
└── widget_test.dart          # Tests widget (écran de connexion)
```

## Tests

```bash
flutter test
```

Les tests couvrent la désérialisation du modèle `Utilisateur` et l’affichage de l’écran de connexion (titres, champs, bouton).

## Dépendances principales

- `http` – appels API  
- `flutter_secure_storage` – stockage du token JWT et des infos utilisateur  
- `intl` – formatage des dates  
- `image_picker` – prise de photo pour les justificatifs  
- `url_launcher` – ouverture du mail et du téléphone (écran Aide)

---

*SOURMAIL Léa - Projet BTS SIO SLAM – GSB Frais*
