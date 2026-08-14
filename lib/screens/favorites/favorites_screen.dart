import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';
import '../listing/listing_detail_screen.dart';

/// Espace favoris : annonces sauvegardées, accessibles indépendamment
/// d'une nouvelle recherche — section 5.5.
///
/// La liste est directement dérivée de [AppState] : un cœur coché depuis le
/// feed ou la fiche produit apparaît ici sans le moindre rechargement.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final favorites = state.favorites;
    final total = favorites.fold<int>(0, (sum, l) => sum + l.price);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes favoris'),
        actions: [
          if (favorites.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${favorites.length} article${favorites.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.background.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'Aucun favori pour le moment',
              message: 'Appuyez sur le cœur d\'une annonce pour la retrouver '
                  'ici, même après une nouvelle recherche.',
            )
          : Column(
              children: [
                // Récapitulatif : petit repère utile quand on compare
                // plusieurs articles avant d'acheter.
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Total de la sélection',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ),
                      Text(
                        '${formatAmount(total)} F',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
                    itemCount: favorites.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.60,
                    ),
                    itemBuilder: (context, index) {
                      final listing = favorites[index];
                      return FadeInUp(
                        key: ValueKey('fav-${listing.id}'),
                        delay: Duration(milliseconds: 40 * (index % 6)),
                        child: ListingCard(
                          listing: listing,
                          heroPrefix: 'fav',
                          isFavorite: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(
                                listingId: listing.id,
                                heroPrefix: 'fav',
                              ),
                            ),
                          ),
                          onFavoriteToggle: () {
                            state.toggleFavorite(listing.id);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 3),
                                  content: const Text('Retiré de vos favoris'),
                                  action: SnackBarAction(
                                    label: 'Annuler',
                                    textColor: AppColors.background,
                                    onPressed: () =>
                                        state.toggleFavorite(listing.id),
                                  ),
                                ),
                              );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
