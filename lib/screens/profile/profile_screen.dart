import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/auth_controller.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import '../favorites/favorites_screen.dart';
import '../listing/listing_detail_screen.dart';
import '../listing/publish_listing_screen.dart';

/// Profil utilisateur : identité, réputation (note moyenne, badges),
/// annonces actives et paramètres — section 5.2 du cahier des charges.
///
/// Les chiffres affichés proviennent de la session en cours et de [AppState] :
/// publier ou supprimer une annonce met le compteur à jour immédiatement.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final state = AppScope.of(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.person_outline,
          title: 'Session expirée',
          message: 'Reconnectez-vous pour accéder à votre profil.',
        ),
      );
    }

    final myListings = state.myListings;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader(user: user)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${myListings.length}',
                          label: 'Annonces actives',
                          icon: Icons.sell_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${user.salesCount}',
                          label: 'Ventes réalisées',
                          icon: Icons.local_shipping_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${state.favoritesCount}',
                          label: 'Favoris',
                          icon: Icons.favorite_border,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SectionHeader(
                    title: 'Mes annonces',
                    actionLabel: 'Publier',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PublishListingScreen(),
                        fullscreenDialog: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          if (myListings.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  'Vous n\'avez encore rien mis en vente. Appuyez sur « Publier » '
                  'pour créer votre première annonce.',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 194,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  itemCount: myListings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _MyListingTile(
                    listing: myListings[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(
                          listingId: myListings[i].id,
                          heroPrefix: 'mine',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Évaluations reçues'),
                  const SizedBox(height: 8),
                  // Un compte fraîchement créé n'a évidemment aucune
                  // évaluation : la réputation se construit à la première vente.
                  if (user.reviewCount == 0)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star_border,
                              size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aucune évaluation pour l\'instant. Vos acheteurs '
                              'pourront vous noter après une vente.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Paramètres'),
                  const SizedBox(height: 4),
                  _SectionTile(
                    icon: Icons.favorite_border,
                    label: 'Mes favoris',
                    trailing: '${state.favoritesCount}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    ),
                  ),
                  _SectionTile(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    onTap: () => _showComingSoon(context, 'Notifications'),
                  ),
                  _SectionTile(
                    icon: Icons.lock_outline,
                    label: 'Confidentialité et sécurité',
                    onTap: () => _showComingSoon(context, 'Confidentialité'),
                  ),
                  _SectionTile(
                    icon: Icons.help_outline,
                    label: 'Aide et support',
                    onTap: () => _showComingSoon(context, 'Aide et support'),
                  ),
                  const SizedBox(height: 8),
                  _SectionTile(
                    icon: Icons.logout,
                    label: 'Se déconnecter',
                    isDestructive: true,
                    onTap: () => _confirmSignOut(context, auth),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'JaBa — version de démonstration',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('« $label » sera disponible dans une prochaine version')),
      );
  }

  void _confirmSignOut(BuildContext context, AuthController auth) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez saisir à nouveau vos identifiants pour revenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              auth.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'identité sur fond dégradé, avec la note de réputation.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 26),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
      ),
      child: FadeInUp(
        offset: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background.withValues(alpha: 0.35),
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: InitialsAvatar(
                    initials: user.initials,
                    seed: user.id,
                    radius: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                          if (user.verified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                size: 16, color: AppColors.accent),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (user.reviewCount > 0)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              '${user.averageRating.toStringAsFixed(1).replaceAll('.', ',')} · '
                              '${user.reviewCount} évaluations',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.background.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Nouveau membre',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.background.withValues(alpha: 0.85),
                          ),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        '${user.zone} · membre depuis ${_monthYear(user.memberSince)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.background.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.email != null || user.phone != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14, color: AppColors.background),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.email ?? user.phone!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.background.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (user.badges.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.badges
                    .map((badge) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.background,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _monthYear(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Vignette d'une annonce personnelle, avec son statut de vente.
class _MyListingTile extends StatelessWidget {
  const _MyListingTile({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 132,
                    height: 124,
                    child: ListingPhoto(path: listing.coverPhoto),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: listing.isSold ? AppColors.textSecondary : AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      listing.isSold ? 'Vendu' : 'En ligne',
                      style: const TextStyle(
                          fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  listing.formattedPrice,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent),
                ),
                const Spacer(),
                const Icon(Icons.visibility_outlined,
                    size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text(
                  '${listing.views}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: color),
      title: Text(label, style: TextStyle(fontSize: 13, color: color)),
      trailing: isDestructive
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  Text(
                    trailing!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
      onTap: onTap,
    );
  }
}
