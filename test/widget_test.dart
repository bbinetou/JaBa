// Tests de l'application JaBa.
//
// Ils couvrent les points sensibles de la refonte : l'inscription (aucun
// compte n'est pré-enregistré, celui que l'on crée doit servir à se
// reconnecter), la validation des numéros selon le pays, la structure du
// catalogue (une annonce = un objet, plusieurs angles) et la réactivité de
// l'état partagé.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:JaBa/data/app_state.dart';
import 'package:JaBa/data/auth_controller.dart';
import 'package:JaBa/data/countries.dart';
import 'package:JaBa/data/demo_catalog.dart';
import 'package:JaBa/data/local_store.dart';
import 'package:JaBa/main.dart';
import 'package:JaBa/models/models.dart';

/// Identifiants utilisés par les tests d'inscription.
const _name = 'Awa Diop';
const _email = 'awa.diop@exemple.sn';
const _password = 'motdepasse1';
const _phone = '771234567';

/// Un [LocalStore] vierge par test : aucune donnée persistée d'un test ne
/// doit fuiter vers le suivant.
Future<LocalStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore.open();
}

void main() {
  group('AuthController', () {
    test('démarre déconnecté, sans aucun compte pré-enregistré', () async {
      final auth = AuthController(await _freshStore());
      expect(auth.status, AuthStatus.checking);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.hasAccounts, isFalse);
    });

    test('se connecter sans compte existant échoue', () async {
      final auth = AuthController(await _freshStore());
      final ok = await auth.signInWithEmail(_email, _password);
      expect(ok, isFalse);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.error, contains('Aucun compte'));
    });

    test('le compte créé permet ensuite de se reconnecter', () async {
      final auth = AuthController(await _freshStore());

      final created = await auth.signUp(
        name: _name,
        email: _email,
        password: _password,
        zone: 'Yoff',
        phone: _phone,
        country: Countries.senegal,
      );
      expect(created, isTrue);
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user?.displayName, _name);
      expect(auth.user?.phone, '+221 77 123 45 67');

      auth.signOut();
      expect(auth.status, AuthStatus.signedOut);

      expect(await auth.signInWithEmail(_email, _password), isTrue);
      expect(auth.user?.email, _email);
    });

    test('un mauvais mot de passe est refusé avec un message', () async {
      final auth = AuthController(await _freshStore());
      await auth.signUp(
        name: _name,
        email: _email,
        password: _password,
        zone: 'Yoff',
      );
      auth.signOut();

      expect(await auth.signInWithEmail(_email, 'incorrect'), isFalse);
      expect(auth.error, 'Mot de passe incorrect');
    });

    test('une adresse déjà utilisée est refusée', () async {
      final auth = AuthController(await _freshStore());
      await auth.signUp(
        name: _name, email: _email, password: _password, zone: 'Yoff');
      auth.signOut();

      final again = await auth.signUp(
        name: 'Autre', email: _email, password: 'unautrepass', zone: 'Yoff');
      expect(again, isFalse);
      expect(auth.error, contains('existe déjà'));
    });

    test('le parcours téléphone envoie un code puis le vérifie', () async {
      final auth = AuthController(await _freshStore());

      // Numéro invalide : on reste à l'étape de saisie.
      expect(await auth.requestOtp('12345', Countries.senegal), isFalse);
      expect(auth.phoneStep, PhoneStep.number);

      expect(await auth.requestOtp(_phone, Countries.senegal), isTrue);
      expect(auth.phoneStep, PhoneStep.code);
      expect(auth.otpSecondsLeft, greaterThan(0));

      final code = auth.sentCode;
      expect(code, isNotNull);
      expect(code!.length, 6);

      // Un code erroné décrémente le nombre d'essais.
      expect(await auth.verifyOtp(code == '000000' ? '111111' : '000000'),
          isFalse);
      expect(auth.remainingOtpAttempts, 2);

      expect(await auth.verifyOtp(code), isTrue);
      expect(auth.status, AuthStatus.signedIn);
    });

    test('validation adaptée au pays sélectionné', () {
      const sn = Countries.senegal;
      final fr = Countries.byCode('FR');

      expect(AuthController.validatePhone('771234567', sn), isNull);
      expect(AuthController.validatePhone('+221 77 123 45 67', sn), isNull);
      // Préfixe opérateur inconnu au Sénégal.
      expect(AuthController.validatePhone('601234567', sn), isNotNull);
      expect(AuthController.validatePhone('7712345', sn), isNotNull);

      // Le même numéro « 6… » est en revanche valide en France.
      expect(AuthController.validatePhone('612345678', fr), isNull);
      expect(AuthController.validatePhone('0612345678', fr), isNull);

      expect(AuthController.formatPhone('771234567', sn), '+221 77 123 45 67');
    });

    test('la liste des pays est cohérente et recherchable', () {
      expect(Countries.all.length, greaterThan(30));
      expect(Countries.senegal.flag, '🇸🇳');
      expect(Countries.byCode('FR').flag, '🇫🇷');
      expect(Countries.byCode('FR').dialCode, '33');

      // Recherche sans accent, par code ISO et par indicatif.
      expect(Countries.search('senegal').first.code, 'SN');
      expect(Countries.search('CI').any((c) => c.code == 'CI'), isTrue);
      expect(Countries.search('+33').any((c) => c.code == 'FR'), isTrue);
      expect(Countries.search('zzzzz'), isEmpty);
    });
  });

  group('Catalogue', () {
    test('une annonce par objet réel, avec ses différents angles', () {
      final listings = DemoData.listings();
      expect(listings.length, 5);

      final attendu = {
        DemoData.robeListingId: Assets.robeWax,
        DemoData.boubouListingId: Assets.boubou,
        DemoData.chaussuresListingId: Assets.chaussures,
        DemoData.sacListingId: Assets.sac,
        DemoData.pcListingId: Assets.thinkpad,
      };

      for (final entry in attendu.entries) {
        final listing = listings.firstWhere((l) => l.id == entry.key);
        expect(listing.photos, entry.value,
            reason: '${entry.key} doit porter toutes les vues de son objet');
        expect(listing.coverPhoto, entry.value.first);
      }
    });

    test('aucune photo n\'est partagée entre deux annonces', () {
      final vues = <String, String>{};
      for (final listing in DemoData.listings()) {
        for (final photo in listing.photos) {
          expect(vues.containsKey(photo), isFalse,
              reason: '$photo apparaît déjà dans « ${vues[photo]} »');
          vues[photo] = listing.title;
        }
      }
    });

    test('chaque catégorie du feed est représentée une seule fois', () {
      final categories = DemoData.listings().map((l) => l.category).toList();
      expect(categories.toSet().length, categories.length);
      expect(
        categories.toSet(),
        {
          ListingCategory.femme,
          ListingCategory.homme,
          ListingCategory.chaussures,
          ListingCategory.accessoires,
          ListingCategory.electronique,
        },
      );
    });

    test('une photo reste libre pour la démonstration d\'ajout', () {
      final used = DemoData.listings().expand((l) => l.photos).toSet();
      for (final path in Assets.galleryOnly) {
        expect(used.contains(path), isFalse,
            reason: '$path doit rester disponible dans la galerie');
      }
      expect(Assets.galleryOnly, contains(Assets.ordi3));
    });

    test('toutes les photos pointent vers des assets déclarés', () {
      for (final listing in DemoData.listings()) {
        expect(listing.photos, isNotEmpty);
        for (final photo in listing.photos) {
          expect(photo, startsWith('assets/images/'));
          expect(Assets.all, contains(photo));
        }
      }
    });
  });

  group('AppState', () {
    test('démarre sur le catalogue, sans favori ni annonce personnelle',
        () async {
      final state = AppState(await _freshStore());
      expect(state.allListings.length, 5);
      expect(state.favorites, isEmpty);
      expect(state.myListings, isEmpty);
      // Les puces de catégorie ne proposent que ce qui existe réellement.
      expect(state.availableCategories.length, 5);
    });

    test('la recherche filtre sur plusieurs mots', () async {
      final state = AppState(await _freshStore())..setQuery('robe wax');
      expect(state.visibleListings.length, 1);

      state.setQuery('zzzz introuvable');
      expect(state.visibleListings, isEmpty);
    });

    test('les filtres se cumulent et le tri s\'applique', () async {
      final state = AppState(await _freshStore());
      state.applyFilters(const ListingFilters(
        category: ListingCategory.electronique,
        sort: SortOption.priceAsc,
      ));

      final results = state.visibleListings;
      expect(results, isNotEmpty);
      expect(
        results.every((l) => l.category == ListingCategory.electronique),
        isTrue,
      );
      for (var i = 1; i < results.length; i++) {
        expect(results[i].price, greaterThanOrEqualTo(results[i - 1].price));
      }
    });

    test('countFor annonce le résultat sans modifier l\'état courant',
        () async {
      final state = AppState(await _freshStore());
      final before = state.visibleListings.length;
      final count = state.countFor(
        const ListingFilters(category: ListingCategory.femme),
      );
      expect(count, lessThan(before));
      expect(state.visibleListings.length, before);
    });

    test('un favori bascule et notifie ses auditeurs', () async {
      final state = AppState(await _freshStore());
      var notified = 0;
      state.addListener(() => notified++);

      final id = state.allListings.first.id;
      state.toggleFavorite(id);

      expect(state.isFavorite(id), isTrue);
      expect(notified, 1);
      expect(state.favorites.single.id, id);
    });

    test('publier ajoute réellement l\'annonce en tête du feed', () async {
      final state = AppState(await _freshStore());
      final before = state.allListings.length;
      final author = UserProfile(
        id: 'me',
        displayName: _name,
        zone: 'Mermoz',
        averageRating: 0,
        reviewCount: 0,
        activeListingsCount: 0,
        memberSince: DateTime.now(),
      );

      final listing = state.publishListing(
        title: 'Robe wax test',
        description: 'Description de test suffisamment longue.',
        category: ListingCategory.femme,
        size: 'M',
        condition: ItemCondition.bonEtat,
        price: 7500,
        negotiable: true,
        // Photo laissée libre exprès pour la démonstration d'ajout.
        photos: Assets.galleryOnly,
        zone: 'Mermoz',
        author: author,
      );

      expect(state.allListings.length, before + 1);
      expect(state.allListings.first.id, listing.id);
      expect(state.myListings.single.id, listing.id);
      expect(state.sellerOf(listing).displayName, _name);
    });

    test('un message envoyé remonte la conversation', () async {
      final state = AppState(await _freshStore());
      final conversation = state.conversations.last;
      final before = conversation.messages.length;

      state.sendMessage(conversation.id, 'Bonjour !');

      final updated = state.conversationById(conversation.id)!;
      expect(updated.messages.length, before + 1);
      expect(updated.messages.last.content, 'Bonjour !');
      expect(state.conversations.first.id, conversation.id);
    });

    test('répondre à une offre met son statut à jour', () async {
      final state = AppState(await _freshStore());
      final conversation = state.conversations.firstWhere(
        (c) => c.messages.any((m) => m.type == MessageType.offre),
      );
      final offer =
          conversation.messages.firstWhere((m) => m.type == MessageType.offre);

      state.respondToOffer(conversation.id, offer.id, OfferStatus.acceptee);

      final updated = state.conversationById(conversation.id)!;
      expect(
        updated.messages.firstWhere((m) => m.id == offer.id).offerStatus,
        OfferStatus.acceptee,
      );
      expect(updated.messages.last.type, MessageType.systeme);
    });
  });

  group('Parcours applicatif', () {
    /// Viewport de téléphone : les formulaires tiennent alors à l'écran
    /// comme sur un vrai appareil.
    void usePhoneViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    /// Démarre l'application et attend l'écran de connexion.
    Future<void> launch(WidgetTester tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(JaBaApp(store: await _freshStore()));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    }

    /// Va jusqu'au feed en créant un compte depuis l'écran de connexion.
    Future<void> signUpAndEnter(WidgetTester tester) async {
      await launch(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Créer un compte'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('signup-name')), _name);
      await tester.enterText(find.byKey(const Key('signup-email')), _email);
      await tester.enterText(find.byKey(const Key('signup-phone')), _phone);
      await tester.enterText(find.byKey(const Key('signup-password')), _password);
      await tester.enterText(find.byKey(const Key('signup-confirm')), _password);
      await tester.pumpAndSettle();

      // Acceptation des conditions d'utilisation.
      final terms = find.byKey(const Key('signup-terms'));
      await tester.ensureVisible(terms);
      await tester.pumpAndSettle();
      await tester.tap(terms);
      await tester.pumpAndSettle();

      final submit = find.byKey(const Key('signup-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
    }

    testWidgets('l\'écran de connexion met en avant la création de compte',
        (tester) async {
      await launch(tester);

      expect(find.text('Vous n\'avez pas encore de compte ?'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Créer un compte'),
          findsOneWidget);
      // Plus aucun identifiant de démonstration n'est affiché.
      expect(find.textContaining('démonstration'), findsNothing);
    });

    testWidgets('le sélecteur d\'indicatif permet de changer de pays',
        (tester) async {
      await launch(tester);

      expect(find.text('+221'), findsOneWidget);
      await tester.tap(find.text('+221'));
      await tester.pumpAndSettle();
      expect(find.text('Indicatif du pays'), findsOneWidget);

      // Recherche sans accent, puis sélection.
      await tester.enterText(find.byKey(const Key('country-search')), 'france');
      await tester.pumpAndSettle();
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();

      expect(find.text('+33'), findsOneWidget);
      expect(find.text('+221'), findsNothing);
    });

    testWidgets('inscription puis affichage du feed avec les photos',
        (tester) async {
      await signUpAndEnter(tester);

      expect(find.text('Coups de cœur près de chez vous'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('la recherche filtre le feed au fil de la frappe',
        (tester) async {
      await signUpAndEnter(tester);

      await tester.enterText(find.byType(TextField).first, 'thinkpad');
      await tester.pumpAndSettle();

      // Le carrousel de mise en avant disparaît dès qu'une requête est active.
      expect(find.text('Coups de cœur près de chez vous'), findsNothing);
      expect(find.text('1 article'), findsOneWidget);
    });

    testWidgets('ouvrir une annonce montre ses différents angles',
        (tester) async {
      await signUpAndEnter(tester);

      // La robe wax porte trois vues du même article.
      await tester.tap(find.text('Robe wax longue, motif éventail').first);
      await tester.pumpAndSettle();

      expect(find.text('Autres vues de l\'article'), findsOneWidget);
      expect(find.text('défilement auto'), findsOneWidget);
      expect(find.text('12 500 F'), findsWidgets);
    });
  });
}
