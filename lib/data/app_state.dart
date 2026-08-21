import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/models.dart';
import 'demo_catalog.dart';
import 'local_store.dart';

/// État applicatif partagé : catalogue, favoris, recherche/filtres, messagerie.
/// Persisté sur l'appareil via [LocalStore], sous une clé propre à chaque
/// compte connecté.
class AppState extends ChangeNotifier {
  AppState(this._store) {
    _listings = DemoData.listings();
    _conversations = DemoData.conversations();
    _favoriteIds = <String>{};
  }

  final LocalStore _store;

  /// Compte actuellement chargé (voir [loadForAccount]) : `null` tant que
  /// personne n'est connecté, auquel cas rien n'est persisté.
  String? _accountKey;

  late List<Listing> _listings;
  late List<Conversation> _conversations;
  late Set<String> _favoriteIds;

  ListingFilters _filters = const ListingFilters();
  bool _refreshing = false;
  final List<String> _recentSearches = ['robe wax', 'thinkpad'];
  final _random = Random();

  // ---------------------------------------------------------------- lecture

  List<Listing> get allListings => List.unmodifiable(_listings);
  ListingFilters get filters => _filters;
  bool get isRefreshing => _refreshing;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  bool isFavorite(String listingId) => _favoriteIds.contains(listingId);
  int get favoritesCount => _favoriteIds.length;

  Listing? listingById(String id) {
    for (final l in _listings) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<Listing> get favorites =>
      _listings.where((l) => _favoriteIds.contains(l.id)).toList();

  List<Listing> get myListings =>
      _listings.where((l) => l.sellerId == 'me').toList();

  /// Catégories réellement représentées dans le catalogue : les puces de
  /// l'accueil ne proposent ainsi jamais un filtre qui ne renverrait rien.
  List<ListingCategory> get availableCategories {
    final present = _listings.map((l) => l.category).toSet();
    return ListingCategory.values.where(present.contains).toList();
  }

  /// Feed filtré + trié. Recalculé à chaque `notifyListeners`, ce qui rend la
  /// recherche instantanée au fil de la frappe.
  List<Listing> get visibleListings => listingsFor(_filters);

  /// Nombre de résultats pour un jeu de filtres donné, sans l'appliquer :
  /// le panneau de filtres peut ainsi annoncer « Voir 5 articles » avant
  /// même que l'utilisateur ne valide.
  int countFor(ListingFilters filters) => listingsFor(filters).length;

  List<Listing> listingsFor(ListingFilters filters) {
    final q = filters.query.trim().toLowerCase();
    final result = _listings.where((l) {
      if (filters.category != null && l.category != filters.category) {
        return false;
      }
      if (filters.conditions.isNotEmpty &&
          !filters.conditions.contains(l.condition)) {
        return false;
      }
      if (l.price < filters.minPrice || l.price > filters.maxPrice) {
        return false;
      }
      if (l.distanceKm > filters.maxDistanceKm) return false;
      if (filters.negotiableOnly && !l.negotiable) return false;
      if (filters.hideSold && l.isSold) return false;
      if (q.isEmpty) return true;

      final haystack = [
        l.title,
        l.description,
        l.zone,
        l.category.label,
        l.brand ?? '',
        l.size ?? '',
        l.sellerName,
      ].join(' ').toLowerCase();
      // Chaque mot de la requête doit être présent : « robe m » trouve la
      // robe en taille M sans ramener tout le catalogue.
      return q.split(RegExp(r'\s+')).every(haystack.contains);
    }).toList();

    switch (filters.sort) {
      case SortOption.recent:
        result.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      case SortOption.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.distance:
        result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case SortOption.rating:
        result.sort((a, b) => b.sellerRating.compareTo(a.sellerRating));
    }
    return result;
  }

  /// Profil du vendeur d'une annonce. Les vendeurs du catalogue de départ ont
  /// une fiche complète ; pour une annonce publiée depuis l'application, on
  /// reconstitue un profil minimal à partir de l'annonce elle-même.
  UserProfile sellerOf(Listing listing) {
    final known = DemoData.sellerById(listing.sellerId);
    if (known != null) return known;
    return UserProfile(
      id: listing.sellerId,
      displayName: listing.sellerName,
      zone: listing.zone,
      averageRating: listing.sellerRating,
      reviewCount: 0,
      activeListingsCount:
          _listings.where((l) => l.sellerId == listing.sellerId).length,
      memberSince: DateTime.now(),
    );
  }

  /// Annonces proches d'une annonce donnée (même catégorie), pour le bloc
  /// « Vous aimerez aussi » de la fiche produit.
  List<Listing> similarTo(Listing listing, {int limit = 6}) {
    final same = _listings
        .where((l) =>
            l.id != listing.id && l.category == listing.category && !l.isSold)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return same.take(limit).toList();
  }

  // ------------------------------------------------------------- messagerie

  List<Conversation> get conversations {
    final sorted = [..._conversations]
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return sorted;
  }

  int get unreadCount =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  Conversation? conversationById(String id) {
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Récupère la conversation rattachée à une annonce, ou la crée si l'on
  /// contacte ce vendeur pour la première fois.
  Conversation conversationForListing(Listing listing) {
    final existing =
        _conversations.where((c) => c.listingId == listing.id).toList();
    if (existing.isNotEmpty) return existing.first;

    final conversation = Conversation(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      listingId: listing.id,
      otherUser: sellerOf(listing),
      messages: const [],
    );
    _conversations = [..._conversations, conversation];
    _persist();
    // Création pendant un build possible (ouverture depuis la fiche) : on
    // diffère la notification pour ne pas déclencher un setState en plein build.
    _notifyAfterFrame();
    return conversation;
  }

  void markConversationRead(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1 || _conversations[index].unreadCount == 0) return;
    _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
    _notifyAfterFrame();
  }

  void sendMessage(String conversationId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _appendMessage(
      conversationId,
      ChatMessage(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        senderId: 'me',
        type: MessageType.texte,
        content: trimmed,
        timestamp: DateTime.now(),
      ),
    );
  }

  void sendOffer(String conversationId, int amount) {
    if (amount <= 0) return;
    _appendMessage(
      conversationId,
      ChatMessage(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        senderId: 'me',
        type: MessageType.offre,
        offerAmount: amount,
        offerStatus: OfferStatus.enAttente,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Réponse entrante de l'interlocuteur (démonstration : voir
  /// `ChatScreen`, qui simule une réponse du vendeur après quelques secondes).
  void receiveMessage(String conversationId, String senderId, String text) {
    _appendMessage(
      conversationId,
      ChatMessage(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        senderId: senderId,
        type: MessageType.texte,
        content: text,
        timestamp: DateTime.now(),
      ),
    );
  }

  void sendSystemMessage(String conversationId, String content) {
    _appendMessage(
      conversationId,
      ChatMessage(
        id: 's${DateTime.now().microsecondsSinceEpoch}',
        senderId: 'systeme',
        type: MessageType.systeme,
        content: content,
        timestamp: DateTime.now(),
      ),
    );
  }

  void respondToOffer(String conversationId, String messageId, OfferStatus status) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;
    final conversation = _conversations[index];
    final messages = conversation.messages
        .map((m) => m.id == messageId ? m.copyWith(offerStatus: status) : m)
        .toList();

    messages.add(ChatMessage(
      id: 'm${DateTime.now().microsecondsSinceEpoch}',
      senderId: 'systeme',
      type: MessageType.systeme,
      content: status.label,
      timestamp: DateTime.now(),
    ));

    _conversations[index] = conversation.copyWith(messages: messages);
    _persist();
    notifyListeners();
  }

  void _appendMessage(String conversationId, ChatMessage message) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;
    _conversations[index] = _conversations[index].copyWith(
      messages: [..._conversations[index].messages, message],
      unreadCount: 0,
    );
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------- actions

  void toggleFavorite(String listingId) {
    if (!_favoriteIds.add(listingId)) _favoriteIds.remove(listingId);
    _persist();
    notifyListeners();
  }

  void setQuery(String query) {
    if (query == _filters.query) return;
    _filters = _filters.copyWith(query: query);
    notifyListeners();
  }

  void submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches
      ..removeWhere((s) => s.toLowerCase() == trimmed.toLowerCase())
      ..insert(0, trimmed);
    if (_recentSearches.length > 6) _recentSearches.removeLast();
    _persist();
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    _persist();
    notifyListeners();
  }

  void setCategory(ListingCategory? category) {
    _filters = category == null
        ? _filters.copyWith(clearCategory: true)
        : _filters.copyWith(category: category);
    notifyListeners();
  }

  void setSort(SortOption sort) {
    _filters = _filters.copyWith(sort: sort);
    notifyListeners();
  }

  void applyFilters(ListingFilters filters) {
    _filters = filters;
    notifyListeners();
  }

  void resetFilters() {
    _filters = ListingFilters(query: _filters.query);
    notifyListeners();
  }

  /// Publication depuis le parcours en 3 étapes : l'annonce rejoint réellement
  /// le feed, en tête de liste.
  Listing publishListing({
    required String title,
    required String description,
    required ListingCategory category,
    String? size,
    required ItemCondition condition,
    required int price,
    required bool negotiable,
    required List<String> photos,
    required String zone,
    required UserProfile author,
  }) {
    final listing = Listing(
      id: 'new${DateTime.now().microsecondsSinceEpoch}',
      sellerId: author.id,
      sellerName: author.displayName,
      sellerRating: author.averageRating,
      title: title,
      description: description,
      category: category,
      size: (size == null || size.trim().isEmpty) ? null : size.trim(),
      condition: condition,
      price: price,
      negotiable: negotiable,
      photos: photos,
      zone: zone,
      distanceKm: 0,
      publishedAt: DateTime.now(),
    );
    _listings = [listing, ..._listings];
    _persist();
    notifyListeners();
    return listing;
  }

  void markAsSold(String listingId, {bool sold = true}) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index == -1) return;
    _listings[index] = _listings[index].copyWith(isSold: sold);
    _persist();
    notifyListeners();
  }

  void deleteListing(String listingId) {
    _listings.removeWhere((l) => l.id == listingId);
    _favoriteIds.remove(listingId);
    _persist();
    notifyListeners();
  }

  /// Consultation d'une fiche : le compteur de vues progresse, comme sur une
  /// vraie place de marché.
  void registerView(String listingId) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index == -1) return;
    _listings[index] =
        _listings[index].copyWith(views: _listings[index].views + 1);
    _notifyAfterFrame();
  }

  /// « Tirer pour rafraîchir » : latence simulée puis légère progression des
  /// compteurs de vues, pour que le geste ait un effet visible.
  Future<void> refresh() async {
    _refreshing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _listings = _listings
        .map((l) => l.copyWith(views: l.views + _random.nextInt(4)))
        .toList();
    _refreshing = false;
    notifyListeners();
  }

  // ------------------------------------------------------------ persistance

  static String _listingsKey(String key) => 'app.$key.listings.v1';
  static String _conversationsKey(String key) => 'app.$key.conversations.v1';
  static String _favoritesKey(String key) => 'app.$key.favorites.v1';
  static String _searchesKey(String key) => 'app.$key.searches.v1';

  /// Charge le catalogue/favoris/conversations de ce compte, ou le jeu de
  /// démonstration lors de sa première connexion.
  Future<void> loadForAccount(String accountKey) async {
    _accountKey = accountKey;

    final storedListings = _store.getJson<List<dynamic>>(
        _listingsKey(accountKey), (j) => j as List<dynamic>);
    final storedConversations = _store.getJson<List<dynamic>>(
        _conversationsKey(accountKey), (j) => j as List<dynamic>);
    final storedFavorites = _store.getJson<List<dynamic>>(
        _favoritesKey(accountKey), (j) => j as List<dynamic>);
    final storedSearches = _store.getJson<List<dynamic>>(
        _searchesKey(accountKey), (j) => j as List<dynamic>);

    _listings = storedListings != null
        ? storedListings
            .map((j) => Listing.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList()
        : DemoData.listings();
    _conversations = storedConversations != null
        ? storedConversations
            .map((j) =>
                Conversation.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList()
        : DemoData.conversations();
    _favoriteIds =
        storedFavorites != null ? storedFavorites.cast<String>().toSet() : {};
    _recentSearches
      ..clear()
      ..addAll(storedSearches?.cast<String>() ?? const ['robe wax', 'thinkpad']);

    _filters = const ListingFilters();
    notifyListeners();
  }

  /// Remet l'état au jeu de démonstration (déconnexion).
  void clearAccountContext() {
    _accountKey = null;
    _listings = DemoData.listings();
    _conversations = DemoData.conversations();
    _favoriteIds = <String>{};
    _recentSearches
      ..clear()
      ..addAll(['robe wax', 'thinkpad']);
    _filters = const ListingFilters();
    notifyListeners();
  }

  /// Sauvegarde l'état courant sous la clé du compte connecté. Sans effet
  /// tant qu'aucun compte n'est chargé (écran de connexion, par exemple).
  void _persist() {
    final key = _accountKey;
    if (key == null) return;
    _store.setJson(
        _listingsKey(key), _listings.map((l) => l.toJson()).toList());
    _store.setJson(_conversationsKey(key),
        _conversations.map((c) => c.toJson()).toList());
    _store.setJson(_favoritesKey(key), _favoriteIds.toList());
    _store.setJson(_searchesKey(key), _recentSearches);
  }

  void _notifyAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}

/// Accès à l'état depuis n'importe quel widget : `AppScope.of(context)`
/// s'abonne aux changements, `AppScope.read(context)` ne fait que lire
/// (à utiliser dans les callbacks).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope introuvable dans l\'arbre de widgets');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope introuvable dans l\'arbre de widgets');
    return scope!.notifier!;
  }
}
