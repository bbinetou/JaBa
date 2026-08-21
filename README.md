# JaBa — Guide de test (authentification → publication d'article)

JaBa est une marketplace de seconde main (Sénégal). Ce document explique
comment lancer l'application et tester l'ensemble du parcours, de la
création de compte jusqu'à la publication d'une annonce, avec le backend
local actuellement en place.

## 1. État du backend

Il n'y a **pas encore de serveur distant** (Firebase arrivera plus tard,
voir les dépendances commentées dans `pubspec.yaml`). En attendant,
l'authentification et les données sont **réellement fonctionnelles en
local**, persistées sur l'appareil via `shared_preferences` :

| Élément | Fichier | Comportement |
|---|---|---|
| Comptes & session | [lib/data/auth_controller.dart](lib/data/auth_controller.dart) | Inscription e-mail/mot de passe et téléphone/OTP réelles. Mots de passe hachés (SHA-256), jamais stockés en clair. Aucun compte n'est pré-enregistré — il faut en créer un. |
| Catalogue, favoris, recherches, conversations | [lib/data/app_state.dart](lib/data/app_state.dart) | Isolés **par compte connecté** : deux comptes sur le même appareil ne voient jamais les annonces ou favoris l'un de l'autre. |
| Stockage | [lib/data/local_store.dart](lib/data/local_store.dart) | Wrapper `shared_preferences` (JSON), seule classe à changer le jour où un vrai backend est branché. |

Conséquence : ce que tu crées survit à un redémarrage complet de
l'application. Pour repartir de zéro, désinstalle l'app (ou vide le
stockage de l'app sur l'appareil/émulateur).

## 2. Installer et lancer

```bash
flutter pub get
flutter run
```

Vérifie qu'un appareil est détecté avec `flutter devices`. L'app démarre
sur un splash puis, selon la session restaurée, sur l'écran de connexion
ou directement sur le feed.

## 3. Parcours de test — authentification

### 3.1 Inscription e-mail + mot de passe
1. Écran de connexion → **Créer un compte**.
2. Renseigne nom, e-mail, téléphone (optionnel selon l'écran), mot de passe
   (8 caractères min., un indicateur de robustesse s'affiche), confirmation.
3. Coche les conditions d'utilisation puis valide.
4. Tu arrives directement sur le feed, connecté.

**À vérifier** :
- Refaire `flutter run` (ou couper/relancer l'app) → tu retombes
  directement sur le feed, sans repasser par la connexion (session restaurée).
- Se déconnecter (Profil → déconnexion) puis se reconnecter avec le même
  e-mail/mot de passe fonctionne.
- Se réinscrire avec le **même e-mail** → message « Un compte existe déjà
  avec cette adresse ».
- Se connecter avec un mauvais mot de passe → « Mot de passe incorrect ».
- Se connecter avec un e-mail jamais inscrit → « Aucun compte associé à
  cette adresse ».

### 3.2 Connexion par téléphone (OTP)
1. Écran de connexion → onglet/téléphone, sélectionner l'indicatif pays,
   saisir le numéro.
2. Un code à 6 chiffres est généré et affiché dans une notification
   imitant un SMS entrant (il n'y a pas de vraie passerelle SMS).
3. Saisis ce code sur l'écran suivant.
4. **Numéro jamais utilisé** : une étape supplémentaire demande le nom —
   c'est lui qui s'affichera ensuite partout dans l'app (fiche profil,
   annonces publiées), plus de « Nouveau membre » générique.

**À vérifier** :
- Un code erroné décrémente le compteur d'essais (3 max), affiché à
  l'écran ; au bout de 3 échecs le parcours revient à la saisie du numéro.
- Le code expire au bout de 5 minutes (`AuthController.otpValidity`).
- Un numéro déjà utilisé pour un compte le reconnecte directement sur le
  même profil (pas d'étape nom) ; un numéro inconnu demande le nom avant de
  créer le compte et d'entrer dans l'app.
- Le nom saisi apparaît bien dans Profil (en haut, à la place du nom
  complet on affiche le tien).

## 4. Parcours de test — publication d'une annonce

Depuis le feed, bouton central **Publier** (3 étapes) :

1. **Photos** — « Ajouter une photo » ouvre le **vrai** sélecteur de
   l'appareil (`image_picker`) : appareil photo ou galerie système. Sur
   Android/iOS, la première utilisation demande la permission caméra/photos
   (accepte-la). Sur Chrome, la galerie s'ouvre via le sélecteur de fichiers
   du navigateur. Choisis-en au moins une ; la première photo devient la
   couverture (appui long sur une vignette pour la changer).
2. **Détails** — titre (5 car. min.), description (15 car. min.), catégorie,
   taille (optionnelle), état de l'article.
3. **Prix & adresse** — prix (FCFA), négociable ou non, puis **Adresse de
   récupération** : champ texte libre (ex. « Rue 12, Sacré-Cœur, Dakar »),
   5 caractères min.

Valide **Publier l'annonce** : un `SnackBar` de confirmation apparaît avec
un bouton « Voir ».

**À vérifier** :
- L'annonce apparaît immédiatement en tête du feed et dans Profil → Mes
  annonces, avec la vraie photo importée (pas une image de démo).
- L'adresse saisie s'affiche sur la fiche de l'annonce et dans le
  récapitulatif de l'étape 3 pendant la saisie.
- Publier sans photo, sans titre, ou avec une adresse vide/trop courte
  bloque l'étape correspondante avec un message d'erreur.
- Se déconnecter puis se reconnecter sur le **même** compte → l'annonce
  publiée, photo comprise, est toujours là (persistance par compte — sur
  mobile/desktop la photo est copiée dans le stockage de l'app ; sur le web
  elle est conservée encodée, voir limites en fin de document).
- Créer un **second** compte sur le même appareil → il ne voit pas
  l'annonce publiée par le premier (isolation des données).

## 5. Parcours de test — achat direct et messagerie

### 5.1 Achat direct
Sur la fiche d'une annonce qui n'est pas la tienne : bouton **Acheter · prix**
en haut de la barre d'action, au-dessus de « Faire une offre » / « Contacter ».

1. Appuie sur **Acheter** → une boîte de dialogue demande confirmation.
2. Confirme : tu es redirigé directement dans la conversation avec le
   vendeur, qui affiche déjà la confirmation d'achat suivie d'une réponse —
   c'est la notification immédiate au vendeur, simulée puisqu'il n'y a pas
   de second appareil connecté sur ce vendeur de démonstration.

**À vérifier** : la conversation créée apparaît aussi dans l'onglet Messages,
avec le message « 🛒 Achat validé » et la réponse du vendeur.

### 5.2 Chat
- **La messagerie ne contient que ce qui te concerne** : un compte tout
  juste créé a un onglet Messages vide (plus de conversations de
  démonstration pré-remplies) — une conversation n'apparaît que lorsque tu
  contactes, fais une offre, ou achètes une annonce. Les annonces que tu
  publies toi-même n'ajoutent pas de conversation tant que personne ne t'a
  contacté à leur sujet.
- Envoyer un message déclenche une réponse simulée du vendeur après ~2 s
  (indicateur « en train d'écrire… »).
- Icône **WhatsApp** (verte) dans la barre du chat, visible si le vendeur a
  un numéro (le cas pour tous les vendeurs de démonstration) → ouvre
  WhatsApp avec un message pré-rempli, pour poursuivre la conversation hors
  de l'app.
- Les noms affichés (fiche annonce, en-tête du chat, liste des
  conversations) sont anonymisés : prénom + initiale (ex. « Fatou N. »),
  jamais le nom complet.

### 5.3 Favoris
Cœur sur une annonce (feed, favoris, ou fiche détaillée) → un bandeau de
confirmation ("Ajouté à vos favoris" / "Retiré de vos favoris") apparaît en
bas de l'écran et se referme tout seul après 2-3 secondes.

## 6. Autres points rapides à parcourir

- **Recherche/filtres** (accueil) : la recherche filtre au fil de la
  frappe ; les filtres (prix, état, distance, tri) se cumulent.
- **Favoris** : apparaît dans l'onglet Favoris, survit à un redémarrage
  (voir §5.3 pour la confirmation à l'ajout).

## 7. Lancer les tests automatisés

```bash
flutter test
```

`test/widget_test.dart` couvre déjà l'inscription, la validation
téléphone par pays, l'isolation du catalogue par compte, la publication
d'annonce, et un parcours d'intégration (inscription → feed → recherche →
fiche produit).

## 8. Limites actuelles à garder en tête

- Pas de vrai envoi de SMS/e-mail : le code OTP est affiché à l'écran.
- Sur le web, les photos importées sont stockées encodées (base64) dans
  `localStorage` : quelques photos passent, mais la limite de stockage du
  navigateur (~5 Mo) peut être atteinte avec beaucoup d'annonces à
  photos multiples — sur mobile/desktop, les photos sont copiées en fichiers
  dans le stockage de l'app et n'ont pas cette limite.
- L'achat direct notifie le vendeur *dans la conversation*, immédiatement :
  il n'y a pas encore de notification push (nécessiterait un vrai backend,
  voir ci-dessous).
- Tout reste local à l'appareil : rien n'est synchronisé entre appareils
  tant que Firebase n'est pas branché.

## 9. Et Firebase ?

Le code est déjà structuré pour cette bascule : `LocalStore` est le seul
point qui connaît `shared_preferences`, et `AuthController`/`AppState`
n'exposent que des méthodes métier — remplacer le stockage par Firestore/
Firebase Auth ne change aucun écran. Ça vaut le coup dès que tu veux de
vraies notifications push (achat, message reçu) ou un compte utilisable sur
plusieurs appareils ; pour rester uniquement local (tests sur un seul
appareil, pas de notifications), le backend actuel suffit. La bascule
demande un projet Firebase de ton côté (console Firebase + `flutterfire
configure`) : dis-le si tu veux qu'on s'y mette.
