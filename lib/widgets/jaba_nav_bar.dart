import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Barre de navigation flottante, arrondie, détachée du bord de l'écran,
/// avec un bouton central "Publier" surélevé — un parti pris visuel plus
/// affirmé que la BottomNavigationBar Material par défaut, et qui met en
/// évidence l'action la plus importante du produit : publier une annonce.
class JaBaNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Pastilles de notification : nombre de favoris et de messages non lus.
  final int favoritesCount;
  final int unreadCount;

  const JaBaNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.favoritesCount = 0,
    this.unreadCount = 0,
  });

  static const _items = [
    (icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Marché'),
    (icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Favoris'),
    (icon: Icons.add, activeIcon: Icons.add, label: 'Publier'), // géré à part (bouton central)
    (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // --- Socle de la barre ---
            Container(
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(color: AppColors.ink.withValues(alpha:0.28), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  if (i == 2) return const SizedBox(width: 46); // espace réservé au bouton central
                  final item = _items[i];
                  final active = currentIndex == i;
                  return _NavIcon(
                    icon: active ? item.activeIcon : item.icon,
                    active: active,
                    badge: switch (i) {
                      1 => favoritesCount,
                      3 => unreadCount,
                      _ => 0,
                    },
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
            // --- Bouton central surélevé ---
            Positioned(
              top: -14,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 4),
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withValues(alpha:0.5), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final int badge;
  final VoidCallback onTap;
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.background.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            // L'icône grossit légèrement à la sélection.
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              scale: active ? 1.1 : 1,
              child: Icon(
                icon,
                color: active
                    ? AppColors.background
                    : AppColors.background.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 15),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
