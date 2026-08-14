import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';
import '../messaging/chat_screen.dart';

/// Fiche annonce détaillée : carrousel photo, prix, état, profil vendeur avec
/// note de fiabilité, actions « Faire une offre » / « Contacter » — section 5.5.
///
/// L'annonce est relue depuis [AppState] à chaque build (et non reçue figée en
/// paramètre) : le cœur, le compteur de vues ou le statut « vendu » restent
/// synchronisés avec le reste de l'application.
class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.heroPrefix = 'feed',
  });

  final String listingId;
  final String heroPrefix;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _pageController = PageController();
  int _photoIndex = 0;
  bool _viewRegistered = false;

  Timer? _autoScrollTimer;
  int _photoCount = 0;

  /// Le défilement automatique s'arrête définitivement dès que l'utilisateur
  /// prend la main : il regarde alors une photo précise, ce serait pénible
  /// qu'elle change toute seule sous ses yeux.
  bool _userTookOver = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_viewRegistered) {
      _viewRegistered = true;
      final state = AppScope.read(context);
      state.registerView(widget.listingId);
      _photoCount = state.listingById(widget.listingId)?.photos.length ?? 0;
      _startAutoScroll();
    }
  }

  /// Fait défiler les angles de l'objet toutes les 3,5 s : sur une fiche
  /// produit, c'est ce qui montre d'emblée qu'il y a plusieurs vues.
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_photoCount < 2) return;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted || _userTookOver || !_pageController.hasClients) return;
      _pageController.animateToPage(
        (_photoIndex + 1) % _photoCount,
        duration: const Duration(milliseconds: 650),
        curve: AppMotion.emphasized,
      );
    });
  }

  void _stopAutoScroll() {
    if (_userTookOver) return;
    setState(() => _userTookOver = true);
    _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final listing = state.listingById(widget.listingId);

    // L'annonce peut avoir été supprimée depuis « Mes annonces ».
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Annonce indisponible',
          message: 'Cette annonce n\'est plus en ligne.',
        ),
      );
    }

    final seller = state.sellerOf(listing);
    final isFavorite = state.isFavorite(listing.id);
    final similar = state.similarTo(listing);
    final isMine = listing.sellerId == 'me';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildPhotoHeader(listing, isFavorite, state),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(listing),
                  const SizedBox(height: 12),
                  _buildTags(listing),
                  const SizedBox(height: 16),
                  _buildStatsRow(listing),
                  if (listing.photos.length > 1) ...[
                    const SizedBox(height: 18),
                    _buildAngleStrip(listing),
                  ],
                  const Divider(height: 32),
                  const Text('Description',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    listing.description.isEmpty
                        ? 'Article en très bon état, peu porté, à récupérer sur ${listing.zone}.'
                        : listing.description,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                  ),
                  const Divider(height: 32),
                  const Text('Vendeur',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _SellerCard(seller: seller, isMine: isMine),
                  const SizedBox(height: 14),
                  _buildLocationCard(listing),
                  const SizedBox(height: 10),
                  _buildSafetyNotice(),
                ],
              ),
            ),
          ),
          if (similar.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 26, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 18),
                      child: SectionHeader(title: 'Vous aimerez aussi'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 186,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 18),
                        itemCount: similar.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => ListingTile(
                          listing: similar[i],
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(
                                listingId: similar[i].id,
                                heroPrefix: 'similar',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomSheet: _buildActionBar(context, listing, state, isMine),
    );
  }

  /// En-tête photo : carrousel plein cadre, pastilles de progression, accès
  /// à la visionneuse plein écran.
  Widget _buildPhotoHeader(Listing listing, bool isFavorite, AppState state) {
    final photos = listing.photos;

    return SliverAppBar(
      backgroundColor: AppColors.primary,
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      leading: _CircleAction(
        icon: Icons.arrow_back,
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _CircleAction(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.accent : null,
          onTap: () => state.toggleFavorite(listing.id),
        ),
        _CircleAction(
          icon: Icons.flag_outlined,
          onTap: () => _showReportDialog(context),
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (photos.isEmpty)
              const ListingPhoto(path: null)
            else
              // Un glissement manuel coupe le défilement automatique.
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) _stopAutoScroll();
                  return false;
                },
                child: PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _photoIndex = i),
                itemBuilder: (context, i) {
                  final photo = ListingPhoto(
                    path: photos[i],
                    alignment: Alignment.center,
                  );
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullScreenGallery(
                          photos: photos,
                          initialIndex: i,
                        ),
                      ),
                    ),
                    // Seule la première photo porte le Hero : c'est elle qui
                    // était visible sur la vignette du feed.
                    child: i == 0
                        ? Hero(
                            tag: '${widget.heroPrefix}-photo-${listing.id}',
                            child: photo,
                          )
                        : photo,
                  );
                },
                ),
              ),
            // Voile discret sous les icônes, pour qu'elles restent lisibles
            // quelle que soit la photo.
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Colors.transparent],
                  ),
                ),
              ),
            ),
            if (listing.isSold)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VENDU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            if (photos.length > 1)
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: PageDots(count: photos.length, index: _photoIndex),
                ),
              ),
            if (photos.length > 1)
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_photoIndex + 1}/${photos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            const Positioned(
              left: 14,
              bottom: 14,
              child: _ZoomHint(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(Listing listing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
              ),
              if (listing.brand != null) ...[
                const SizedBox(height: 4),
                Text(
                  listing.brand!,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              listing.formattedPrice,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            if (listing.negotiable)
              const Text(
                'négociable',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTags(Listing listing) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppTag(label: listing.condition.label, icon: Icons.verified_outlined),
        if (listing.size != null)
          AppTag(label: 'Taille ${listing.size}', icon: Icons.straighten),
        AppTag(label: listing.category.label, icon: listing.category.icon),
        if (listing.negotiable)
          const AppTag(label: 'Négociable', icon: Icons.swap_horiz, accent: true),
      ],
    );
  }

  /// Petits indicateurs de vie de l'annonce (vues, date, favoris).
  Widget _buildStatsRow(Listing listing) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _Stat(
            icon: Icons.visibility_outlined,
            value: '${listing.views}',
            label: 'vues',
          ),
          const _StatDivider(),
          _Stat(
            icon: Icons.schedule,
            value: listing.publishedLabel.replaceFirst('il y a ', ''),
            label: 'en ligne',
          ),
          const _StatDivider(),
          _Stat(
            icon: Icons.near_me_outlined,
            value: '${listing.distanceKm.toStringAsFixed(listing.distanceKm < 10 ? 1 : 0)} km',
            label: 'de vous',
          ),
        ],
      ),
    );
  }

  /// Bandeau des différents angles de l'objet : on voit d'un coup d'œil
  /// combien de vues existent, et on saute directement à celle qu'on veut.
  Widget _buildAngleStrip(Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Autres vues de l\'article',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
            if (!_userTookOver) ...[
              const SizedBox(width: 8),
              const Icon(Icons.play_circle_outline,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'défilement auto',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: listing.photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final active = i == _photoIndex;
              return GestureDetector(
                onTap: () {
                  _stopAutoScroll();
                  _pageController.animateToPage(
                    i,
                    duration: AppMotion.medium,
                    curve: AppMotion.emphasized,
                  );
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: active ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListingPhoto(path: listing.photos[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Listing listing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Remise en main propre',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Zone ${listing.zone} · à convenir avec le vendeur',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Privilégiez un lieu public pour la remise et vérifiez l\'article '
              'avant de payer. Ne communiquez jamais vos codes personnels.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  /// Barre d'action fixe en bas de la fiche, adaptée au contexte : ses propres
  /// annonces ne proposent évidemment pas de « contacter le vendeur ».
  Widget _buildActionBar(
    BuildContext context,
    Listing listing,
    AppState state,
    bool isMine,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          if (isMine) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => state.markAsSold(listing.id, sold: !listing.isSold),
                icon: Icon(
                  listing.isSold ? Icons.undo : Icons.check_circle_outline,
                  size: 17,
                ),
                label: Text(listing.isSold ? 'Remettre en vente' : 'Marquer vendu'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmDelete(context, listing, state),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Supprimer'),
              ),
            ),
          ] else if (listing.isSold) ...[
            const Expanded(
              child: Center(
                child: Text(
                  'Cet article a déjà été vendu',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          ] else ...[
            if (listing.negotiable) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openChat(context, listing, state, offer: true),
                  child: const Text('Faire une offre'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context, listing, state, offer: false),
                icon: const Icon(Icons.chat_bubble_outline, size: 17),
                label: const Text('Contacter'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openChat(
    BuildContext context,
    Listing listing,
    AppState state, {
    required bool offer,
  }) {
    final conversation = state.conversationForListing(listing);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          openOfferSheet: offer,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Listing listing, AppState state) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette annonce ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              state.deleteListing(listing.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    const motifs = [
      'Contenu inapproprié',
      'Contrefaçon',
      'Comportement suspect',
      'Article déjà vendu',
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Signaler cette annonce'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: motifs
              .map((motif) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.outlined_flag, size: 18),
                    title: Text(motif, style: const TextStyle(fontSize: 13)),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signalement transmis à la modération'),
                        ),
                      );
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(icon, key: ValueKey(icon), size: 19, color: color ?? Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ZoomHint extends StatelessWidget {
  const _ZoomHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.zoom_in, size: 13, color: Colors.white),
          SizedBox(width: 4),
          Text('Appuyez pour agrandir',
              style: TextStyle(color: Colors.white, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.border);
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller, required this.isMine});

  final UserProfile seller;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          InitialsAvatar(
            initials: seller.initials,
            seed: seller.id,
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMine ? 'Vous' : seller.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                    if (seller.verified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified, size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                RatingStars(
                  rating: seller.averageRating,
                  reviewCount: seller.reviewCount,
                  size: 12,
                ),
                const SizedBox(height: 3),
                Text(
                  '${seller.activeListingsCount} annonces · ${seller.zone}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!isMine)
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
