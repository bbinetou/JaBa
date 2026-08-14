import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'data/auth_controller.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const JaBaApp());
}

/// Racine de l'application.
///
/// Deux `ChangeNotifier` sont installés au-dessus de l'arbre de widgets :
///  - [AuthController] (via `AuthScope`) : session, connexion, inscription ;
///  - [AppState] (via `AppScope`)        : catalogue, favoris, filtres, messages.
///
/// Tous les écrans lisent et modifient cet état partagé, ce qui rend
/// l'application réellement réactive : un favori, une annonce publiée ou un
/// message envoyé se répercutent immédiatement partout où l'information
/// apparaît.
///
/// Écrans disponibles (dossier lib/screens) :
///  - auth/auth_gate.dart               → aiguillage session ↔ application
///  - auth/login_screen.dart            → connexion téléphone/OTP ou e-mail
///  - auth/signup_screen.dart           → création de compte
///  - root_shell.dart                   → coquille de navigation (5 sections)
///  - home/home_screen.dart             → feed, recherche, filtres, tri
///  - listing/listing_detail_screen.dart→ fiche annonce, carrousel photo
///  - listing/publish_listing_screen.dart → publication en 3 étapes
///  - messaging/conversations_screen.dart → liste des conversations
///  - messaging/chat_screen.dart        → chat + négociation intégrée
///  - favorites/favorites_screen.dart   → favoris
///  - profile/profile_screen.dart       → profil & réputation
class JaBaApp extends StatefulWidget {
  const JaBaApp({super.key});

  @override
  State<JaBaApp> createState() => _JaBaAppState();
}

class _JaBaAppState extends State<JaBaApp> {
  final _appState = AppState();
  final _auth = AuthController();

  @override
  void dispose() {
    _appState.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _appState,
      child: AuthScope(
        controller: _auth,
        child: MaterialApp(
          title: 'JaBa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const SessionResetListener(child: AuthGate()),
        ),
      ),
    );
  }
}
