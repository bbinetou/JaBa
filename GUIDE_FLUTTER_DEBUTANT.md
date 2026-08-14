# Guide Flutter débutant — apprendre avec le projet Vinted.sn

Ce guide ne t'apprend pas "à utiliser ce code", il t'apprend **Flutter**, en utilisant ce projet comme terrain d'exercice. Chaque notion est expliquée puis reliée à un fichier réel du projet, que tu peux ouvrir en parallèle pour voir la théorie appliquée. L'objectif est que tu puisses, à la fin, écrire un écran Flutter par toi-même sans copier-coller.

Prends ton temps sur les sections 1 à 5 : elles conditionnent la compréhension de tout le reste. Les sections suivantes peuvent être lues dans l'ordre qui t'intéresse.

---

## 1. Dart et Flutter, deux choses différentes

**Dart** est le langage de programmation. **Flutter** est un framework, c'est-à-dire une grosse bibliothèque de composants visuels et d'outils, écrite en Dart, qui te permet de construire une interface. C'est la même relation qu'entre JavaScript et React, ou entre Kotlin et Jetpack Compose.

Concrètement, quand tu écris du Flutter, tu écris du Dart à 100 %. Il n'y a pas de langage à balises séparé comme en HTML/CSS : la mise en page, le style et la logique sont dans le même fichier `.dart`, sous forme d'objets Dart imbriqués les uns dans les autres.

Dart est un langage à typage statique (les types sont vérifiés avant l'exécution) et orienté objet (tout est une classe, y compris les nombres). Si tu as déjà fait un peu de Java, de C# ou de TypeScript, la syntaxe te sera familière.

## 2. Tout est un Widget

C'est la phrase la plus importante à comprendre en Flutter : **tout ce qui s'affiche à l'écran est un widget**. Un texte est un widget (`Text`). Une image est un widget (`Image`). Un espacement vide est un widget (`SizedBox`). Un bouton est un widget. Et un écran entier, qui regroupe des dizaines de widgets, est lui-même... un widget.

Un widget Flutter est une classe Dart qui décrit à quoi doit ressembler une portion de l'interface, en fonction de son état actuel. Il possède une méthode `build()` qui retourne d'autres widgets. On obtient ainsi un **arbre de widgets** : un widget racine qui contient des widgets enfants, qui contiennent eux-mêmes des widgets enfants, et ainsi de suite.

Ouvre `lib/widgets/listing_card.dart`. Tu verras que la méthode `build()` retourne un `GestureDetector`, qui contient un `Container`, qui contient une `Column`, qui contient elle-même un `Stack`, une `Padding`, etc. C'est un arbre typique : chaque widget a une responsabilité précise (détecter un tap, dessiner un fond, empiler des éléments, organiser verticalement).

Cette philosophie a une conséquence pratique importante : en Flutter, on ne "modifie" jamais un widget existant à la manière d'un `document.getElementById(...).style.color = 'red'` en JavaScript. On **reconstruit** un nouveau widget avec les nouvelles valeurs, et Flutter se charge de comparer l'ancien et le nouvel arbre pour ne redessiner que ce qui a changé. Retiens simplement : décrire l'état actuel, pas donner des ordres de modification.

## 3. StatelessWidget vs StatefulWidget

C'est la deuxième notion fondamentale, et celle qui bloque le plus les débutants.

Un **`StatelessWidget`** est un widget qui ne change jamais une fois affiché, sauf si son parent lui fournit de nouvelles données. Il n'a pas de mémoire interne. Regarde `lib/widgets/vinted_nav_bar.dart` : c'est un `StatelessWidget`. Il reçoit `currentIndex` et `onTap` de l'extérieur, et se contente d'afficher une barre de navigation en fonction de ces valeurs. Il ne décide jamais lui-même de changer d'onglet actif.

Un **`StatefulWidget`** est un widget qui a une mémoire interne, une donnée qui peut changer au fil du temps *sans que le parent n'intervienne*. Regarde `lib/screens/auth/phone_login_screen.dart` : la variable `_codeSent` (vrai ou faux) détermine si on affiche le champ "numéro de téléphone" ou le champ "code reçu par SMS". Cette variable change quand l'utilisateur appuie sur un bouton, à l'intérieur même de l'écran. C'est donc un `StatefulWidget`.

Un `StatefulWidget` est en réalité composé de **deux classes** : la classe du widget elle-même (immuable), et une classe `State` associée qui, elle, peut changer. C'est pour cela que tu vois toujours ce schéma :

```dart
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  bool _codeSent = false; // ceci est la mémoire interne

  @override
  Widget build(BuildContext context) {
    // ce qui s'affiche, en fonction de _codeSent
  }
}
```

Retiens la règle de décision simple : **si un écran doit se souvenir de quelque chose entre deux interactions de l'utilisateur (un texte saisi, une case cochée, une étape en cours), c'est un `StatefulWidget`. Sinon, c'est un `StatelessWidget`.** La grande majorité des petits composants visuels (une carte, un badge, un bouton personnalisé) sont `Stateless` ; les écrans avec formulaire ou interaction sont souvent `Stateful`.

## 4. `setState()` : comment un widget se met à jour lui-même

Modifier une variable Dart classique (`_codeSent = true;`) ne suffit pas à rafraîchir l'écran. Flutter ne sait pas qu'il doit redessiner quoi que ce soit. Il faut l'en informer explicitement avec `setState()` :

```dart
setState(() {
  _codeSent = true;
});
```

`setState()` fait deux choses : il exécute le code que tu lui donnes (ici, changer la variable), puis il dit à Flutter "cette portion de l'interface doit être reconstruite". Flutter appelle alors à nouveau la méthode `build()` de ce widget, qui va cette fois lire `_codeSent = true` et donc afficher autre chose.

Cherche `setState` dans `lib/screens/messaging/chat_screen.dart` : tu le trouveras à chaque endroit où un nouveau message ou une nouvelle offre est ajouté à la conversation. À chaque fois, le principe est le même : on modifie une liste ou une variable, on appelle `setState`, et Flutter réaffiche automatiquement la liste des messages avec le nouvel élément.

**Limite importante à connaître** : `setState()` ne fonctionne que pour l'état local d'*un seul* widget. Si plusieurs écrans différents ont besoin de connaître la même information (par exemple, le nombre d'articles favoris, affiché à la fois sur l'écran d'accueil et sur l'écran de profil), `setState()` ne suffit plus : il faut un système de gestion d'état partagé. Le cahier des charges du projet mentionne Riverpod ou Bloc pour cet usage — retiens simplement que ce sont des outils qui répondent au même besoin que `setState`, mais à l'échelle de toute l'application plutôt que d'un seul écran. Tu n'as pas besoin de les maîtriser pour valider les bases : `setState` suffit largement pour un MVP.

## 5. Les briques de mise en page (layout)

Flutter ne fonctionne pas comme le CSS où l'on positionne des éléments avec des propriétés sur un seul élément (`position`, `float`...). En Flutter, la mise en page se fait en **emboîtant des widgets de structure** les uns dans les autres. Voici les six que tu utiliseras 90 % du temps.

**`Container`** est le widget "boîte à tout faire" : il peut avoir une couleur de fond, un padding interne, une marge externe, une largeur, une hauteur, des coins arrondis. C'est l'équivalent d'une `<div>` stylée en CSS.

**`Row`** aligne ses enfants horizontalement, **`Column`** les aligne verticalement. Ce sont les deux widgets que tu utiliseras le plus. Regarde `lib/screens/listing/listing_detail_screen.dart` : la ligne titre + prix utilise une `Row`, tandis que l'ensemble de la fiche (titre, tags, description, vendeur) est organisé dans une grande `Column`.

**`Padding`** ajoute un espace vide autour d'un widget enfant. **`SizedBox`** sert à deux choses : donner une taille fixe à un widget, ou — utilisé sans enfant, juste avec une `height` ou une `width` — créer un espacement vide entre deux widgets dans une `Row` ou une `Column`. Tu verras `const SizedBox(height: 8)` un peu partout dans le projet : c'est simplement "laisser 8 pixels de vide ici".

**`Expanded`** s'utilise à l'intérieur d'une `Row` ou d'une `Column` pour dire à un enfant "prends tout l'espace restant disponible". Regarde la zone des boutons en bas de `listing_detail_screen.dart` : les deux boutons "Faire une offre" et "Contacter" sont chacun enveloppés dans un `Expanded`, ce qui les fait partager l'espace horizontal à parts égales.

**`Stack`** superpose des widgets les uns sur les autres, comme des calques en Photoshop, au lieu de les aligner. Regarde `listing_card.dart` : la photo de l'annonce et le petit cœur "favori" en haut à droite sont dans un `Stack`, avec le cœur positionné par-dessus la photo grâce à un widget `Positioned`.

La meilleure façon de progresser sur ces widgets est de les casser volontairement dans le projet : change un `Column` en `Row` dans un écran, ajoute un `Container` avec une couleur vive autour d'un widget pour voir précisément l'espace qu'il occupe, augmente une valeur de `SizedBox`. Le hot reload te donne un retour instantané.

## 6. Afficher des listes : `ListView` et `GridView`

Dès qu'il faut afficher un nombre variable d'éléments (une liste de messages, une grille d'annonces), on utilise `ListView` ou `GridView`, avec leur constructeur `.builder`.

Le principe du `.builder` est de ne décrire qu'**un seul élément type**, et de dire à Flutter combien de fois le répéter. Flutter se charge ensuite de la boucle, et surtout, il n'affiche réellement à l'écran que les éléments visibles à un instant donné (les autres sont construits seulement quand ils apparaissent en scrollant), ce qui rend les listes performantes même avec des milliers d'éléments.

```dart
GridView.builder(
  itemCount: _mockListings.length,   // combien d'éléments au total
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,               // 2 colonnes
  ),
  itemBuilder: (context, index) {
    final listing = _mockListings[index];
    return ListingCard(listing: listing, ...); // à quoi ressemble UN élément
  },
)
```

Ce code exact se trouve dans `lib/screens/home/home_screen.dart`. Tu retrouveras le même principe avec `ListView.builder` dans `conversations_screen.dart` (une colonne de conversations) et `ListView.separated` (une variante qui ajoute un séparateur visuel entre chaque élément, comme la ligne grise entre deux conversations).

## 7. Naviguer entre les écrans

Flutter gère la navigation avec une **pile d'écrans** (une "stack" au sens informatique) : chaque nouvel écran est empilé par-dessus le précédent, et le bouton retour dépile l'écran du dessus.

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
);
```

Ce code, présent dans `home_screen.dart`, fait deux choses : `MaterialPageRoute` décrit *quel* écran afficher (avec une transition standard, glissement horizontal sur Android par exemple), et `Navigator.push` l'empile par-dessus l'écran actuel. Pour revenir en arrière depuis le nouvel écran, on utilise `Navigator.pop(context)`, comme dans le bouton "Annuler" de la boîte de dialogue de signalement dans `listing_detail_screen.dart`.

Remarque comment les données circulent : `ListingDetailScreen(listing: listing)` passe l'objet `Listing` complet en paramètre du constructeur du nouvel écran. C'est la manière la plus simple et la plus courante de transmettre des données entre deux écrans en Flutter, tant que le projet reste de taille modeste. (Pour une application plus grande avec des liens profonds ou des URLs, on utilise un package comme `go_router`, mentionné en commentaire dans `pubspec.yaml`, mais ce n'est pas nécessaire pour apprendre les bases.)

## 8. Les formulaires : `TextField` et `TextEditingController`

Un `TextField` affiche un champ de saisie. Pour **lire** ce que l'utilisateur y tape, il faut lui associer un `TextEditingController` :

```dart
final _phoneController = TextEditingController();

TextField(
  controller: _phoneController,
  decoration: const InputDecoration(hintText: '77 123 45 67'),
)

// plus tard, pour récupérer la valeur saisie :
final texteSaisi = _phoneController.text;
```

Tu retrouveras ce mécanisme dans `chat_screen.dart` (le champ pour écrire un message) et dans la feuille d'offre de négociation (le champ pour saisir un montant). Le `controller` doit être déclaré comme variable de la classe `State` (pas recréé à chaque `build()`), sinon le texte tapé serait perdu à chaque reconstruction du widget.

La `decoration: InputDecoration(...)` permet de personnaliser l'apparence du champ (texte indicatif, libellé, bordures). Remarque que dans ce projet, le style de base des champs (couleur de bordure, arrondi) n'est pas répété à chaque `TextField` : il est défini une seule fois dans `inputDecorationTheme`, à l'intérieur de `lib/theme/app_theme.dart`, et s'applique automatiquement partout. C'est le sujet de la section suivante.

## 9. Centraliser le style avec `ThemeData`

Plutôt que d'écrire `color: Color(0xFF0B3D2E)` à chaque bouton du projet, on définit une seule fois un thème global, et chaque widget standard (boutons, champs, barre du haut...) va automatiquement piocher dedans.

Ouvre `lib/theme/app_theme.dart`. Tu y trouveras une classe `AppColors` qui ne fait que déclarer des constantes de couleur (le vert `primary`, le terracotta `accent`...), et une classe `AppTheme` qui construit un objet `ThemeData` en s'appuyant sur ces constantes. Ce `ThemeData` est ensuite branché une seule fois, dans `main.dart` :

```dart
MaterialApp(
  theme: AppTheme.light,
  home: const PhoneLoginScreen(),
)
```

À partir de ce moment, tous les `ElevatedButton` de l'application prennent automatiquement le style défini dans `elevatedButtonTheme`, sans qu'on ait besoin de le répéter. C'est ce qui garantit la cohérence visuelle d'une application, et c'est une bonne pratique à adopter dès tes premiers projets : centraliser les couleurs et les styles plutôt que les répéter dans chaque widget.

## 10. Modéliser les données avec des classes Dart

Un écran ne doit jamais manipuler des données "en vrac" (des `String`, des `int` isolés) quand ces données représentent un concept métier clair. On crée une classe.

Ouvre `lib/models/models.dart`. La classe `Listing` regroupe tous les champs d'une annonce (`title`, `price`, `condition`, `zone`...) dans un seul objet cohérent. Le mot-clé `final` devant chaque champ signifie que, une fois l'objet créé, ces valeurs ne changent plus (on dit que l'objet est *immuable*) — si le prix change, on crée un nouvel objet `Listing`, on ne modifie pas l'ancien.

```dart
class Listing {
  final String title;
  final int price;
  final ItemCondition condition;
  // ...

  const Listing({
    required this.title,
    required this.price,
    required this.condition,
    // ...
  });
}
```

Ce style de constructeur, avec des paramètres nommés (`title: ...`, `price: ...`) et le mot-clé `required`, est la convention standard en Dart : elle rend le code lisible à l'appel (`Listing(title: 'Robe', price: 8000, ...)`, on voit immédiatement à quoi correspond chaque valeur) et évite les erreurs d'ordre des paramètres.

Remarque aussi l'usage d'un `enum` pour `ItemCondition` (neuf avec étiquette, très bon état, bon état, satisfaisant) plutôt qu'une simple chaîne de caractères libre. Un `enum` limite les valeurs possibles à une liste fermée et connue à l'avance, ce qui évite qu'une faute de frappe ("Bonétat" au lieu de "Bon état") ne casse silencieusement une comparaison quelque part dans le code. C'est un réflexe à prendre dès que tu identifies une donnée qui ne peut prendre qu'un nombre limité de valeurs.

## 11. Lire le projet dans l'ordre le plus pédagogique

Si tu veux parcourir le code pour apprendre plutôt que pour l'utiliser tel quel, voici un ordre de lecture qui construit la compréhension progressivement :

1. `lib/theme/app_theme.dart` — le plus simple, aucune logique, juste des constantes et un objet de configuration.
2. `lib/models/models.dart` — comprendre comment on modélise des données métier en Dart pur, sans Flutter.
3. `lib/widgets/vinted_nav_bar.dart` — ton premier `StatelessWidget` court, pour voir la structure minimale d'un widget.
4. `lib/screens/auth/phone_login_screen.dart` — ton premier `StatefulWidget`, avec un `setState` simple à comprendre (`_codeSent`).
5. `lib/widgets/listing_card.dart` — un widget un peu plus riche, avec `Stack`, `Positioned`, et des callbacks (`onTap`, `onFavoriteToggle`) passés par le parent.
6. `lib/screens/home/home_screen.dart` — assembler plusieurs widgets ensemble, `GridView.builder`, et l'ouverture d'une feuille modale (`showModalBottomSheet`).
7. `lib/screens/messaging/chat_screen.dart` — l'écran le plus complexe du projet : plusieurs `setState`, gestion de liste dynamique, affichage conditionnel selon le type de message.

## 12. Exercices pour t'entraîner sur ce projet

La meilleure façon de valider ces notions est de modifier le code toi-même, avec des objectifs précis :

Ajoute un septième filtre rapide dans `home_screen.dart` (par exemple "Enfants"), en ajoutant simplement une entrée dans la liste `_activeFilters` ou dans les chips proposées.

Ajoute un champ `brand` (marque) à la classe `Listing` dans `models.dart`, puis affiche-le quelque part dans `listing_detail_screen.dart`. Cet exercice te fera toucher trois fichiers différents et comprendre comment une donnée circule du modèle jusqu'à l'écran.

Transforme le badge "vendeuse active" de `profile_screen.dart`, actuellement statique, pour qu'il n'apparaisse que si une variable booléenne `isActiveSeller` vaut `true` — un bon exercice d'affichage conditionnel (`if` dans une liste de widgets, ou opérateur ternaire).

Ajoute un compteur de caractères sous le champ "Description" de `publish_listing_screen.dart`, qui se met à jour à chaque frappe. Cet exercice te force à écouter les changements d'un `TextEditingController` (indice : `controller.addListener(...)` associé à `setState`).

## 13. Pour aller plus loin

La documentation officielle de Flutter est exceptionnellement bien faite et gratuite : [docs.flutter.dev](https://docs.flutter.dev). La section "Widget catalog" y présente chaque widget avec des exemples visuels interactifs — un très bon réflexe est de vérifier systématiquement dans ce catalogue plutôt que de deviner les paramètres d'un widget.

Pour Dart seul, indépendamment de Flutter (null-safety, `async`/`await`, classes, collections), [dart.dev/language](https://dart.dev/language) est la référence.

Une fois les notions de ce guide bien comprises et les exercices de la section 12 réalisés, tu seras en mesure d'aborder sereinement la suite du cahier des charges : la gestion d'état partagée (Riverpod), et la connexion à un vrai backend (Firebase), qui viendront se greffer sur exactement les mêmes écrans que ceux que tu as déjà sous les yeux.
