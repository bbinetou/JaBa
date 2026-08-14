# Vinted.sn — Application mobile Flutter

Bienvenue sur le projet Vinted.sn. Ce document t'explique comment installer ton environnement, lancer l'application, et te repérer dans le code. Un second document, **GUIDE_FLUTTER_DEBUTANT.md**, t'explique en profondeur les notions Flutter utilisées ici — à lire en parallèle si tu débutes.

## 1. Installer Flutter

Avant de pouvoir exécuter ce projet, il faut installer le SDK Flutter sur ta machine.

1. Télécharge le SDK depuis [flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install) en choisissant ton système d'exploitation (Windows, macOS ou Linux).
2. Décompresse l'archive et ajoute le dossier `flutter/bin` à la variable d'environnement `PATH` de ton système, pour pouvoir taper `flutter` depuis n'importe quel terminal.
3. Installe un IDE : **VS Code** (léger, recommandé pour débuter) avec l'extension "Flutter", ou **Android Studio** (plus lourd mais inclut l'émulateur Android).
4. Ouvre un terminal et lance la commande suivante, qui vérifie que tout est correctement installé :

```bash
flutter doctor
```

Cette commande liste ce qui manque (Android SDK, Xcode pour iOS, licences à accepter, etc.) avec des instructions précises pour chaque point rouge. Ne passe pas à la suite tant qu'il reste des erreurs critiques (les avertissements liés à un IDE que tu n'utilises pas ne sont pas bloquants).

## 2. Préparer un appareil pour tester l'application

Tu as trois options, de la plus simple à la plus réaliste :

- **Chrome (le plus rapide pour débuter)** : aucune installation supplémentaire, l'application s'ouvre dans un onglet de navigateur. Certaines fonctionnalités natives (caméra, notifications) ne seront pas testables.
- **Émulateur Android** : installe Android Studio, ouvre le "Device Manager" et crée un appareil virtuel (Pixel 6 par exemple). C'est l'option la plus proche d'un usage réel.
- **Ton propre téléphone Android** : active le mode développeur (Paramètres → À propos du téléphone → tape 7 fois sur "Numéro de build"), puis le débogage USB, et connecte le téléphone en USB.

Vérifie qu'un appareil est bien détecté avec :

```bash
flutter devices
```

## 3. Lancer le projet

Depuis un terminal, place-toi dans le dossier du projet puis installe les dépendances déclarées dans `pubspec.yaml` :

```bash
cd vinted_flutter
flutter pub get
```

Lance ensuite l'application :

```bash
flutter run
```

Si plusieurs appareils sont connectés, Flutter te demandera de choisir lequel utiliser. Une fois l'application démarrée, tu arrives directement sur l'écran de connexion par téléphone.

### Le hot reload, ton meilleur ami

Pendant que `flutter run` tourne, modifie n'importe quel fichier `.dart`, enregistre-le, puis appuie sur `r` dans le terminal (ou `Ctrl+S` dans VS Code avec l'extension Flutter). L'application se met à jour en une fraction de seconde, sans perdre son état. C'est ce qui rend Flutter particulièrement agréable pour apprendre : tu modifies une couleur, une marge, un texte, et tu vois le résultat immédiatement.

## 4. Structure du projet

```
vinted_flutter/
├── pubspec.yaml              → dépendances et métadonnées de l'application
└── lib/
    ├── main.dart              → point d'entrée, démarre sur l'écran de connexion
    ├── theme/
    │   └── app_theme.dart     → couleurs, typographie, ThemeData centralisé
    ├── models/
    │   └── models.dart        → classes Dart représentant les données (Listing, UserProfile...)
    ├── widgets/
    │   ├── listing_card.dart      → carte annonce réutilisée dans plusieurs écrans
    │   ├── vinted_nav_bar.dart    → barre de navigation flottante + bouton "Publier"
    │   └── vinted_mark.dart       → monogramme et wordmark de la marque
    └── screens/
        ├── root_shell.dart            → coquille qui héberge la navigation entre onglets
        ├── auth/phone_login_screen.dart
        ├── home/home_screen.dart
        ├── listing/listing_detail_screen.dart
        ├── listing/publish_listing_screen.dart
        ├── messaging/conversations_screen.dart
        ├── messaging/chat_screen.dart
        ├── profile/profile_screen.dart
        └── favorites/favorites_screen.dart
```

Chaque écran correspond à une fonctionnalité décrite dans le cahier des charges. Le dossier `screens` est organisé par domaine métier (auth, home, listing, messaging, profile, favorites) plutôt que par type de fichier, ce qui est une convention courante en Flutter à mesure qu'un projet grossit.

**Point important sur la navigation** : les écrans ne se contiennent pas navigation les uns les autres tout seuls. C'est `root_shell.dart` qui les assemble derrière une unique barre de navigation et qui décide, quand tu appuies sur un onglet, quel écran afficher — ou, pour le bouton central "+", quel écran ouvrir par-dessus les autres (`Navigator.push`). Si tu ajoutes un nouvel écran de premier niveau plus tard, c'est ce fichier qu'il faudra modifier.

## 5. Parcourir l'application

Après l'écran de connexion (n'importe quel bouton fonctionne, aucun backend n'est encore branché), tu arrives sur `RootShell`, qui affiche cinq sections accessibles depuis la barre du bas : Marché (accueil), Favoris, Publier (bouton central surélevé, ouvre le formulaire de publication en plein écran), Messages et Profil.

Pour explorer directement un écran précis pendant que tu apprends, sans repasser par la connexion à chaque relance, modifie temporairement la ligne `home:` dans `main.dart` :

```dart
home: const HomeScreen(), // au lieu de PhoneLoginScreen()
```

N'oublie pas d'importer l'écran correspondant en haut du fichier.

Pour la suite de ton apprentissage, ouvre **GUIDE_FLUTTER_DEBUTANT.md** : il reprend les notions clés de Flutter une par une, en s'appuyant directement sur le code de ce projet.
