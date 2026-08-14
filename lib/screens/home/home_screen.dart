import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/auth_controller.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/JaBa_mark.dart';
import '../listing/listing_detail_screen.dart';
import '../messaging/conversations_screen.dart';
import 'filter_sheet.dart';

/// Écran d'accueil : recherche textuelle instantanée + filtres cumulables
/// (catégorie, prix, état, distance) + tri — section 5.4 du cahier des charges.
///
/// Tout ce qui est affiché vient de [AppState] : la saisie filtre le feed au
/// fil de la frappe, les favoris se répercutent aussitôt dans l'onglet dédié,
/// et une annonce publiée apparaît en tête de liste.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _showSuggestions = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openListing(Listing listing, String heroPrefix) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(
          listingId: listing.id,
          heroPrefix: heroPrefix,
        ),
      ),
    );
  }

  void _applySearch(String value) {
    AppScope.read(context).setQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    AppScope.read(context).setQuery('');
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final auth = AuthScope.of(context);
    final listings = state.visibleListings;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: state.refresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        edgeOffset: topPadding + 140,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                topPadding: topPadding,
                userName: auth.user?.displayName.split(' ').first ?? '',
                unreadCount: state.unreadCount,
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _applySearch,
                onSubmitted: (value) {
                  state.submitSearch(value);
                  _searchFocus.unfocus();
                },
                onClear: _clearSearch,
                onNotifications: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConversationsScreen()),
                ),
              ),
            ),
            if (_showSuggestions && state.recentSearches.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecentSearches(
                  searches: state.recentSearches,
                  onSelect: (value) {
                    _searchController.text = value;
                    state.setQuery(value);
                    _searchFocus.unfocus();
                  },
                  onClear: state.clearRecentSearches,
                ),
              ),
            SliverToBoxAdapter(
              child: _CategoryStrip(
                categories: state.availableCategories,
                selected: state.filters.category,
                onSelected: state.setCategory,
              ),
            ),
            // Le carrousel « Coups de cœur » ne s'affiche que sur le feed
            // complet : il n'aurait pas de sens au-dessus d'un résultat filtré.
            if (state.filters.activeCount == 0 && state.filters.query.isEmpty)
              SliverToBoxAdapter(
                child: _FeaturedCarousel(
                  listings: listings.take(4).toList(),
                  onTap: (l) => _openListing(l, 'featured'),
                ),
              ),
            SliverToBoxAdapter(
              child: _ResultsBar(
                count: listings.length,
                filters: state.filters,
                onOpenFilters: () => _openFilterSheet(context, state),
                onOpenSort: () => _openSortSheet(context, state),
                onRemoveChip: state.applyFilters,
                onReset: state.resetFilters,
              ),
            ),
            if (listings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Aucune annonce trouvée',
                  message: state.filters.query.isNotEmpty
                      ? 'Aucun résultat pour « ${state.filters.query} ». '
                          'Essayez un autre mot-clé ou élargissez vos filtres.'
                      : 'Aucune annonce ne correspond à ces filtres.',
                  actionLabel: 'Réinitialiser',
                  onAction: () {
                    _searchController.clear();
                    state.resetFilters();
                    state.setQuery('');
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.60,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = listings[index];
                      return FadeInUp(
                        // Décalage progressif : les cartes se posent en cascade.
                        key: ValueKey('card-${listing.id}'),
                        delay: Duration(milliseconds: 40 * (index % 6)),
                        child: ListingCard(
                          listing: listing,
                          isFavorite: state.isFavorite(listing.id),
                          onTap: () => _openListing(listing, 'feed'),
                          onFavoriteToggle: () => _toggleFavorite(state, listing),
                        ),
                      );
                    },
                    childCount: listings.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(AppState state, Listing listing) {
    final wasFavorite = state.isFavorite(listing.id);
    state.toggleFavorite(listing.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(wasFavorite
              ? 'Retiré de vos favoris'
              : '« ${listing.title} » ajouté aux favoris'),
          action: SnackBarAction(
            label: 'Annuler',
            textColor: AppColors.background,
            onPressed: () => state.toggleFavorite(listing.id),
          ),
        ),
      );
  }

  void _openFilterSheet(BuildContext context, AppState state) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => FilterSheet(
        initial: state.filters,
        // Aperçu du nombre de résultats avant validation.
        countFor: state.countFor,
        onApply: state.applyFilters,
        onReset: state.resetFilters,
      ),
    );
  }

  void _openSortSheet(BuildContext context, AppState state) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Trier par',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final option in SortOption.values)
              _SortTile(
                option: option,
                selected: state.filters.sort == option,
                onTap: () {
                  state.setSort(option);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Ligne du panneau de tri : coche animée sur l'option retenue.
class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SortOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        option.icon,
        size: 18,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        option.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: AnimatedScale(
        duration: AppMotion.fast,
        scale: selected ? 1 : 0,
        child: const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
      ),
    );
  }
}

/// En-tête incurvé qui se rétracte au défilement : le bandeau de bienvenue
/// s'efface progressivement et seule la barre de recherche reste épinglée.
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.topPadding,
    required this.userName,
    required this.unreadCount,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onNotifications,
  });

  final double topPadding;
  final String userName;
  final int unreadCount;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onNotifications;

  static const _greetingHeight = 46.0;
  static const _gapHeight = 14.0;

  @override
  double get maxExtent => topPadding + 8 + _greetingHeight + _gapHeight + 48 + 30;

  @override
  double get minExtent => topPadding + 8 + 48 + 30;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return ClipPath(
      clipper: _CurvedHeaderClipper(),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Column(
          children: [
            SizedBox(height: topPadding + 8),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1 - t,
                child: Opacity(
                  opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                  child: SizedBox(
                    height: _greetingHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          const JaBaWordmark(fontSize: 18),
                          const Spacer(),
                          _NotificationBell(
                            count: unreadCount,
                            onTap: onNotifications,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: _gapHeight * (1 - t)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Robe wax, ThinkPad, taille M…',
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: onClear,
                              tooltip: 'Effacer',
                            ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.userName != userName ||
        oldDelegate.unreadCount != unreadCount ||
        oldDelegate.topPadding != topPadding;
  }
}

/// Découpe le bas de l'en-tête en une courbe douce plutôt qu'une ligne droite.
class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 26);
    path.quadraticBezierTo(size.width * 0.5, size.height + 14, size.width, size.height - 26);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.background, size: 20),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 17),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Recherches récentes, proposées quand la barre de recherche prend le focus.
class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.searches,
    required this.onSelect,
    required this.onClear,
  });

  final List<String> searches;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recherches récentes',
            actionLabel: 'Effacer',
            onAction: onClear,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searches
                .map((s) => ActionChip(
                      avatar: const Icon(Icons.history,
                          size: 14, color: AppColors.textSecondary),
                      label: Text(s),
                      onPressed: () => onSelect(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Bandeau de catégories : seules celles réellement présentes au catalogue
/// sont proposées, pour ne jamais aboutir à une liste vide.
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<ListingCategory> categories;
  final ListingCategory? selected;
  final ValueChanged<ListingCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        children: [
          _CategoryChip(
            label: 'Tout',
            icon: Icons.apps,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories)
            _CategoryChip(
              label: category.chipLabel,
              icon: category.icon,
              selected: selected == category,
              onTap: () => onSelected(selected == category ? null : category),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: selected ? AppShadows.card : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? AppColors.background : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.background : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carrousel « Coups de cœur » : défile tout seul toutes les 4 secondes et
/// met les photos en valeur en grand format.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.listings, required this.onTap});

  final List<Listing> listings;
  final ValueChanged<Listing> onTap;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _controller = PageController(viewportFraction: 0.88);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.listings.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.listings.length;
      _controller.animateToPage(
        next,
        duration: AppMotion.slow,
        curve: AppMotion.emphasized,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: SectionHeader(title: 'Coups de cœur près de chez vous'),
        ),
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.listings.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final listing = widget.listings[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onTap(listing),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'featured-photo-${listing.id}',
                          child: ListingPhoto(
                            path: listing.coverPhoto,
                            alignment: Alignment.center,
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(gradient: AppColors.photoScrim),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      listing.formattedPrice,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${listing.zone} · ${listing.publishedLabel}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11),
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
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(child: PageDots(
          count: widget.listings.length,
          index: _index,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
        )),
      ],
    );
  }
}

/// Barre de résultats : compteur, filtres actifs retirables, accès au tri.
class _ResultsBar extends StatelessWidget {
  const _ResultsBar({
    required this.count,
    required this.filters,
    required this.onOpenFilters,
    required this.onOpenSort,
    required this.onRemoveChip,
    required this.onReset,
  });

  final int count;
  final ListingFilters filters;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;
  final ValueChanged<ListingFilters> onRemoveChip;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final chips = filters.chips;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Le compteur se met à jour à chaque frappe : le feed n'a plus
              // rien d'une liste figée.
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Text(
                    key: ValueKey(count),
                    count == 0
                        ? 'Aucun article'
                        : '$count article${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              _BarButton(
                icon: Icons.swap_vert,
                label: 'Trier',
                onTap: onOpenSort,
              ),
              const SizedBox(width: 8),
              _BarButton(
                icon: Icons.tune,
                label: 'Filtres',
                badge: filters.activeCount,
                onTap: onOpenFilters,
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final chip in chips)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(chip.label),
                        backgroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        labelStyle: const TextStyle(
                            color: AppColors.background, fontSize: 11),
                        deleteIcon: const Icon(Icons.close,
                            size: 14, color: AppColors.background),
                        onDeleted: () => onRemoveChip(chip.removed()),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ActionChip(
                    label: const Text('Tout effacer'),
                    onPressed: onReset,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: badge > 0 ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: badge > 0 ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: badge > 0 ? AppColors.background : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badge > 0 ? AppColors.background : AppColors.textSecondary,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
