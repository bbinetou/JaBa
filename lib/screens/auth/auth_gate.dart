import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/JaBa_mark.dart';
import '../root_shell.dart';
import 'login_screen.dart';

/// Aiguillage entre l'écran de connexion et l'application, selon l'état
/// d'authentification. Un seul endroit décide de ce qui est affiché : plus
/// besoin de `pushReplacement` dispersés dans les écrans.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AnimatedSwitcher(
      duration: AppMotion.slow,
      switchInCurve: AppMotion.emphasized,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: switch (auth.status) {
        AuthStatus.checking => const _SplashScreen(key: ValueKey('splash')),
        AuthStatus.signedOut => const LoginScreen(key: ValueKey('login')),
        AuthStatus.signedIn => const RootShell(key: ValueKey('shell')),
      },
    );
  }
}

/// Écran d'ouverture affiché le temps de restaurer la session.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({super.key});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(parent: _controller, curve: AppMotion.springy),
              child: const JaBaMark(size: 76),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.4, 1),
              ),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(text: 'Ja', style: TextStyle(color: AppColors.background)),
                    TextSpan(text: 'BA', style: TextStyle(color: AppColors.accent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.background.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écoute la déconnexion pour remettre le catalogue à zéro : sans cela, les
/// favoris et conversations d'une session survivraient à la suivante.
class SessionResetListener extends StatefulWidget {
  const SessionResetListener({super.key, required this.child});

  final Widget child;

  @override
  State<SessionResetListener> createState() => _SessionResetListenerState();
}

class _SessionResetListenerState extends State<SessionResetListener> {
  AuthStatus? _previous;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = AuthScope.of(context).status;
    if (_previous == AuthStatus.signedIn && status == AuthStatus.signedOut) {
      final state = AppScope.read(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => state.reset());
    }
    _previous = status;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
