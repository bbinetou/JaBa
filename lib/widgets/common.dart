import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/photo_platform.dart';
import '../theme/app_theme.dart';

/// Avatar à initiales : aucune photo de profil n'existe dans les assets, on
/// génère donc une pastille colorée déterministe à partir du nom — deux
/// vendeurs différents n'ont jamais la même couleur d'un écran à l'autre.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    required this.seed,
    this.radius = 22,
    this.fontSize,
  });

  final String initials;
  final String seed;
  final double radius;
  final double? fontSize;

  static const _palette = [
    AppColors.primary,
    AppColors.accent,
    Color(0xFF2E5E4E),
    Color(0xFF8A4B2A),
    Color(0xFF3F6B8A),
    Color(0xFF6B4E8A),
  ];

  Color get _color {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? radius * 0.72,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Note du vendeur sous forme d'étoiles pleines / à moitié / vides.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 13,
    this.showValue = true,
    this.reviewCount,
  });

  final double rating;
  final double size;
  final bool showValue;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star
                : (rating >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: size,
            color: AppColors.gold,
          ),
        if (showValue) ...[
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1).replaceAll('.', ','),
            style: TextStyle(
              fontSize: size - 1,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(fontSize: size - 2, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Étiquette arrondie utilisée pour l'état, la taille, la négociabilité…
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.icon,
    this.accent = false,
    this.filled = false,
    this.color,
  });

  final String label;
  final IconData? icon;
  final bool accent;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? (accent ? AppColors.accent : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled
            ? tone
            : (accent ? AppColors.accentLight : AppColors.surface),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: filled ? tone : (accent ? tone : AppColors.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : tone),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: filled ? Colors.white : tone,
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran vide illustré, avec une action de sortie — plus utile qu'une simple
/// ligne de texte centrée.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Photo d'annonce : asset embarqué, photo importée (fichier local ou data
/// URI sur le web), avec repli visuel si la source venait à manquer.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  });

  final String? path;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return const _PhotoFallback();

    if (p.startsWith('data:')) {
      final bytes = _decodeDataUri(p);
      if (bytes == null) return const _PhotoFallback();
      return Image.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const _PhotoFallback(),
      );
    }

    if (p.startsWith('assets/')) {
      return Image.asset(
        p,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => const _PhotoFallback(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: AppMotion.medium,
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }

    return buildFilePhoto(
      p,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => const _PhotoFallback(),
    );
  }
}

Uint8List? _decodeDataUri(String uri) {
  final comma = uri.indexOf(',');
  if (comma == -1) return null;
  try {
    return base64Decode(uri.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.placeholder,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined,
          size: 28, color: Colors.white70),
    );
  }
}

/// Visionneuse plein écran : glissement horizontal entre les photos et
/// pincement pour zoomer.
class FullScreenGallery extends StatefulWidget {
  const FullScreenGallery({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.heroPrefix,
  });

  final List<String> photos;
  final int initialIndex;
  final String? heroPrefix;

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: ListingPhoto(
                  path: widget.photos[i],
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur de page du carrousel : la pastille active s'allonge.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.index,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x80FFFFFF),
  });

  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Titre de section avec action facultative à droite.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Les titres longs se tronquent au lieu de déborder sur les
        // écrans étroits.
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
