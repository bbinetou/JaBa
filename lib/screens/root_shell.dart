import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'listing/publish_listing_screen.dart';
import 'messaging/conversations_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/JaBa_nav_bar.dart';

/// Coquille racine de l'application : héberge la barre de navigation et
/// bascule entre les sections. C'est ce widget qui manquait dans la V1 —
/// les écrans existaient déjà mais rien ne les reliait entre eux, ce qui
/// rendait "Publier" et les autres onglets inaccessibles.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _tabs = const [
    HomeScreen(),
    FavoritesScreen(),
    SizedBox.shrink(), // l'onglet "Publier" n'a pas de contenu : il ouvre un flux dédié
    ConversationsScreen(),
    ProfileScreen(),
  ];

  void _onTap(int i) {
    if (i == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublishListingScreen(), fullscreenDialog: true),
      );
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      // Les pastilles suivent l'état réel : un favori ajouté ou un message
      // reçu se voit immédiatement dans la barre.
      bottomNavigationBar: JaBaNavBar(
        currentIndex: _index,
        onTap: _onTap,
        favoritesCount: state.favoritesCount,
        unreadCount: state.unreadCount,
      ),
    );
  }
}
