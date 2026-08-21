import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'data/auth_controller.dart';
import 'data/local_store.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  runApp(JaBaApp(store: store));
}

class JaBaApp extends StatefulWidget {
  const JaBaApp({super.key, required this.store});

  final LocalStore store;

  @override
  State<JaBaApp> createState() => _JaBaAppState();
}

class _JaBaAppState extends State<JaBaApp> {
  late final _appState = AppState(widget.store);
  late final _auth = AuthController(widget.store);

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
