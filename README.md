# JaBa

Marketplace mobile de seconde main entre particuliers (Sénégal) : publier une
annonce, échanger avec un vendeur, négocier ou acheter directement.

## Technologies utilisées

- **Flutter / Dart** — application mobile (Android, iOS, web, desktop)
- `shared_preferences` — persistance locale (comptes, annonces, messages)
- `crypto` — hachage des mots de passe
- `image_picker` — photo depuis l'appareil (caméra ou galerie)
- `path_provider` — stockage des photos importées
- `url_launcher` — ouverture de WhatsApp depuis le chat
- `font_awesome_flutter` — icônes additionnelles (WhatsApp)

## Pages de l'application

| Page | Fichier | Rôle |
|---|---|---|
| Connexion | `screens/auth/login_screen.dart` | Connexion par téléphone (code SMS) ou e-mail/mot de passe |
| Inscription | `screens/auth/signup_screen.dart` | Création de compte |
| Accueil / Feed | `screens/home/home_screen.dart` | Catalogue d'annonces, recherche, filtres, tri |
| Fiche annonce | `screens/listing/listing_detail_screen.dart` | Détail d'un article, achat, offre, contact, favoris |
| Publication | `screens/listing/publish_listing_screen.dart` | Créer une annonce en 3 étapes (photos, détails, prix & adresse) |
| Conversations | `screens/messaging/conversations_screen.dart` | Liste des discussions en cours |
| Chat | `screens/messaging/chat_screen.dart` | Messagerie avec négociation intégrée, relais WhatsApp |
| Favoris | `screens/favorites/favorites_screen.dart` | Annonces sauvegardées |
| Profil | `screens/profile/profile_screen.dart` | Identité, réputation, annonces publiées, paramètres |
| Coquille de navigation | `screens/root_shell.dart` | Barre de navigation entre les sections ci-dessus |

## Démarrage

1. Installer le SDK Flutter : [flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install)
2. Vérifier l'installation :
   ```bash
   flutter doctor
   ```
3. Installer les dépendances du projet :
   ```bash
   flutter pub get
   ```
4. Lancer l'application (choisis un appareil/émulateur/Chrome connecté) :
   ```bash
   flutter run
   ```

Pour lancer les tests automatisés :
```bash
flutter test
```
