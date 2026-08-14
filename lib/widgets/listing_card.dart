import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'animations.dart';
import 'common.dart';

/// Vignette d'annonce du feed.
///
/// La photo est le sujet de la carte : elle occupe la majorité de la surface,
/// le prix est posé en pilule à cheval sur son bord inférieur, et l'état de
/// l'article s'affiche discrètement en haut à gauche. La photo est enveloppée
/// dans un `Hero` : à l'ouverture de la fiche, elle grandit à sa place au lieu
/// que l'écran soit remplacé d'un coup.
class ListingCard extends StatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    this.heroPrefix = 'feed',
  });

  final Listing listing;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final String heroPrefix;

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        // Léger enfoncement au toucher : la carte réagit sous le doigt.
        scale: _pressed ? 0.97 : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPhoto(listing)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${listing.zone} · ${listing.distanceKm.toStringAsFixed(listing.distanceKm < 10 ? 1 : 0)} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (listing.size != null) ...[
                          Text(
                            'T. ${listing.size}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            listing.publishedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(Listing listing) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Hero(
          tag: '${widget.heroPrefix}-photo-${listing.id}',
          child: ListingPhoto(path: listing.coverPhoto),
        ),
        if (listing.isSold)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: -0.15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VENDU',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              listing.condition.shortLabel,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: FavoriteButton(
            isFavorite: widget.isFavorite,
            onToggle: widget.onFavoriteToggle,
            size: 15,
            padding: 6,
          ),
        ),
        if (listing.photos.length > 1)
          Positioned(
            right: 8,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 10, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    '${listing.photos.length}',
                    style: const TextStyle(fontSize: 9.5, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        // Badge prix à cheval sur le bas de la photo.
        Positioned(
          left: 8,
          bottom: -13,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: listing.isSold ? AppColors.textSecondary : AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: (listing.isSold ? AppColors.ink : AppColors.accent)
                      .withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing.formattedPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (listing.negotiable && !listing.isSold) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_horiz, size: 12, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Variante horizontale compacte, pour les listes (« Vous aimerez aussi »,
/// annonces du vendeur).
class ListingTile extends StatelessWidget {
  const ListingTile({
    super.key,
    required this.listing,
    required this.onTap,
    this.width = 140,
  });

  final Listing listing;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AspectRatio(
                aspectRatio: 1,
                child: ListingPhoto(path: listing.coverPhoto),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              listing.formattedPrice,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
