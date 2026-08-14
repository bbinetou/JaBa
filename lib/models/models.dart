import 'package:flutter/material.dart';

/// Modèles alignés sur les collections Firestore décrites section 6.4
/// du cahier des charges (users, listings, conversations, messages, reviews).

enum ItemCondition { neufAvecEtiquette, tresBonEtat, bonEtat, satisfaisant }

extension ItemConditionLabel on ItemCondition {
  String get label {
    switch (this) {
      case ItemCondition.neufAvecEtiquette:
        return 'Neuf avec étiquette';
      case ItemCondition.tresBonEtat:
        return 'Très bon état';
      case ItemCondition.bonEtat:
        return 'Bon état';
      case ItemCondition.satisfaisant:
        return 'Satisfaisant';
    }
  }

  /// Version courte, pour les badges posés sur les vignettes du feed.
  String get shortLabel {
    switch (this) {
      case ItemCondition.neufAvecEtiquette:
        return 'Neuf';
      case ItemCondition.tresBonEtat:
        return 'Très bon';
      case ItemCondition.bonEtat:
        return 'Bon état';
      case ItemCondition.satisfaisant:
        return 'Correct';
    }
  }
}

enum ListingCategory {
  femme,
  homme,
  chaussures,
  accessoires,
  enfants,
  maison,
  electronique,
  autres,
}

extension ListingCategoryLabel on ListingCategory {
  String get label {
    switch (this) {
      case ListingCategory.femme:
        return 'Vêtements femme';
      case ListingCategory.homme:
        return 'Vêtements homme';
      case ListingCategory.chaussures:
        return 'Chaussures';
      case ListingCategory.accessoires:
        return 'Accessoires';
      case ListingCategory.enfants:
        return 'Enfants';
      case ListingCategory.maison:
        return 'Maison';
      case ListingCategory.electronique:
        return 'Électronique';
      case ListingCategory.autres:
        return 'Autres';
    }
  }

  /// Libellé compact utilisé par les puces de catégorie de l'accueil.
  String get chipLabel {
    switch (this) {
      case ListingCategory.femme:
        return 'Femme';
      case ListingCategory.homme:
        return 'Homme';
      case ListingCategory.electronique:
        return 'High-tech';
      default:
        return label;
    }
  }

  IconData get icon {
    switch (this) {
      case ListingCategory.femme:
        return Icons.checkroom_outlined;
      case ListingCategory.homme:
        return Icons.dry_cleaning_outlined;
      case ListingCategory.chaussures:
        return Icons.ice_skating_outlined;
      case ListingCategory.accessoires:
        return Icons.watch_outlined;
      case ListingCategory.enfants:
        return Icons.child_care_outlined;
      case ListingCategory.maison:
        return Icons.chair_outlined;
      case ListingCategory.electronique:
        return Icons.laptop_mac_outlined;
      case ListingCategory.autres:
        return Icons.category_outlined;
    }
  }
}

/// Critères de tri du feed (section 5.4 : « tri par pertinence, prix,
/// date ou distance »).
enum SortOption { recent, priceAsc, priceDesc, distance, rating }

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.recent:
        return 'Plus récentes';
      case SortOption.priceAsc:
        return 'Prix croissant';
      case SortOption.priceDesc:
        return 'Prix décroissant';
      case SortOption.distance:
        return 'Les plus proches';
      case SortOption.rating:
        return 'Vendeurs les mieux notés';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.recent:
        return Icons.schedule;
      case SortOption.priceAsc:
        return Icons.arrow_upward;
      case SortOption.priceDesc:
        return Icons.arrow_downward;
      case SortOption.distance:
        return Icons.near_me_outlined;
      case SortOption.rating:
        return Icons.star_outline;
    }
  }
}

class UserProfile {
  final String id;
  final String displayName;
  final String? photoUrl;
  final String zone; // quartier / commune de référence
  final double averageRating;
  final int reviewCount;
  final int activeListingsCount;
  final int salesCount;
  final DateTime memberSince;
  final String? phone;
  final String? email;
  final List<String> badges;
  final bool verified;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.zone,
    required this.averageRating,
    required this.reviewCount,
    required this.activeListingsCount,
    this.salesCount = 0,
    required this.memberSince,
    this.phone,
    this.email,
    this.badges = const [],
    this.verified = false,
  });

  /// Initiales affichées dans les pastilles d'avatar (aucune photo de profil
  /// n'est fournie dans les assets).
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  UserProfile copyWith({
    String? displayName,
    String? zone,
    int? activeListingsCount,
    int? salesCount,
    List<String>? badges,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl,
      zone: zone ?? this.zone,
      averageRating: averageRating,
      reviewCount: reviewCount,
      activeListingsCount: activeListingsCount ?? this.activeListingsCount,
      salesCount: salesCount ?? this.salesCount,
      memberSince: memberSince,
      phone: phone,
      email: email,
      badges: badges ?? this.badges,
      verified: verified,
    );
  }
}

class Listing {
  final String id;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final String title;
  final String description;
  final ListingCategory category;
  final String? size;
  final ItemCondition condition;
  final int price; // en FCFA
  final bool negotiable;

  /// Chemins des images dans `assets/images/`. La première photo sert de
  /// couverture dans le feed, les suivantes alimentent le carrousel de la fiche.
  final List<String> photos;

  final String zone;
  final double distanceKm;
  final bool isSold;
  final DateTime publishedAt;
  final int views;
  final String? brand;

  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    required this.title,
    required this.description,
    required this.category,
    this.size,
    required this.condition,
    required this.price,
    required this.negotiable,
    required this.photos,
    required this.zone,
    required this.distanceKm,
    this.isSold = false,
    required this.publishedAt,
    this.views = 0,
    this.brand,
  });

  String get formattedPrice => '${formatAmount(price)} F';

  String? get coverPhoto => photos.isEmpty ? null : photos.first;

  /// « il y a 3 h », « hier », « il y a 4 j » — un feed daté paraît vivant,
  /// là où une liste sans horodatage paraît figée.
  String get publishedLabel {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    final weeks = diff.inDays ~/ 7;
    if (weeks < 5) return 'il y a $weeks sem.';
    return 'il y a ${diff.inDays ~/ 30} mois';
  }

  Listing copyWith({
    String? title,
    String? description,
    ListingCategory? category,
    String? size,
    ItemCondition? condition,
    int? price,
    bool? negotiable,
    List<String>? photos,
    String? zone,
    double? distanceKm,
    bool? isSold,
    int? views,
    String? brand,
  }) {
    return Listing(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerRating: sellerRating,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      negotiable: negotiable ?? this.negotiable,
      photos: photos ?? this.photos,
      zone: zone ?? this.zone,
      distanceKm: distanceKm ?? this.distanceKm,
      isSold: isSold ?? this.isSold,
      publishedAt: publishedAt,
      views: views ?? this.views,
      brand: brand ?? this.brand,
    );
  }
}

/// Sépare les milliers par une espace : 12500 → « 12 500 ».
String formatAmount(int amount) {
  return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
}

/// Filtres cumulables de l'accueil — section 5.4.
class ListingFilters {
  final String query;
  final ListingCategory? category;
  final Set<ItemCondition> conditions;
  final int minPrice;
  final int maxPrice;
  final double maxDistanceKm;
  final bool negotiableOnly;
  final bool hideSold;
  final SortOption sort;

  static const int priceFloor = 0;
  static const int priceCeiling = 400000;
  static const double distanceCeiling = 30;

  const ListingFilters({
    this.query = '',
    this.category,
    this.conditions = const {},
    this.minPrice = priceFloor,
    this.maxPrice = priceCeiling,
    this.maxDistanceKm = distanceCeiling,
    this.negotiableOnly = false,
    this.hideSold = false,
    this.sort = SortOption.recent,
  });

  bool get hasPriceFilter => minPrice > priceFloor || maxPrice < priceCeiling;
  bool get hasDistanceFilter => maxDistanceKm < distanceCeiling;

  /// Nombre de filtres actifs, affiché en pastille sur le bouton « Filtres ».
  int get activeCount {
    var n = 0;
    if (category != null) n++;
    if (conditions.isNotEmpty) n++;
    if (hasPriceFilter) n++;
    if (hasDistanceFilter) n++;
    if (negotiableOnly) n++;
    if (hideSold) n++;
    if (sort != SortOption.recent) n++;
    return n;
  }

  /// Étiquettes retirables affichées sous la barre de recherche.
  List<({String label, ListingFilters Function() removed})> get chips {
    final result = <({String label, ListingFilters Function() removed})>[];
    if (category != null) {
      result.add((
        label: category!.chipLabel,
        removed: () => copyWith(clearCategory: true),
      ));
    }
    for (final c in conditions) {
      result.add((
        label: c.shortLabel,
        removed: () => copyWith(conditions: {...conditions}..remove(c)),
      ));
    }
    if (hasPriceFilter) {
      result.add((
        label: '${formatAmount(minPrice)} – ${formatAmount(maxPrice)} F',
        removed: () => copyWith(minPrice: priceFloor, maxPrice: priceCeiling),
      ));
    }
    if (hasDistanceFilter) {
      result.add((
        label: '< ${maxDistanceKm.toStringAsFixed(0)} km',
        removed: () => copyWith(maxDistanceKm: distanceCeiling),
      ));
    }
    if (negotiableOnly) {
      result.add((
        label: 'Négociable',
        removed: () => copyWith(negotiableOnly: false),
      ));
    }
    if (hideSold) {
      result.add((
        label: 'Masquer les vendus',
        removed: () => copyWith(hideSold: false),
      ));
    }
    if (sort != SortOption.recent) {
      result.add((
        label: sort.label,
        removed: () => copyWith(sort: SortOption.recent),
      ));
    }
    return result;
  }

  ListingFilters copyWith({
    String? query,
    ListingCategory? category,
    bool clearCategory = false,
    Set<ItemCondition>? conditions,
    int? minPrice,
    int? maxPrice,
    double? maxDistanceKm,
    bool? negotiableOnly,
    bool? hideSold,
    SortOption? sort,
  }) {
    return ListingFilters(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      conditions: conditions ?? this.conditions,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      negotiableOnly: negotiableOnly ?? this.negotiableOnly,
      hideSold: hideSold ?? this.hideSold,
      sort: sort ?? this.sort,
    );
  }
}

enum MessageType { texte, offre, systeme }

enum OfferStatus { enAttente, acceptee, refusee, contreOffre }

extension OfferStatusLabel on OfferStatus {
  String get label {
    switch (this) {
      case OfferStatus.enAttente:
        return 'En attente de réponse';
      case OfferStatus.acceptee:
        return 'Offre acceptée';
      case OfferStatus.refusee:
        return 'Offre refusée';
      case OfferStatus.contreOffre:
        return 'Contre-offre envoyée';
    }
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final MessageType type;
  final String? content;
  final int? offerAmount;
  final OfferStatus? offerStatus;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    this.content,
    this.offerAmount,
    this.offerStatus,
    required this.timestamp,
  });

  String get timeLabel {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ChatMessage copyWith({OfferStatus? offerStatus}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      type: type,
      content: content,
      offerAmount: offerAmount,
      offerStatus: offerStatus ?? this.offerStatus,
      timestamp: timestamp,
    );
  }
}

class Conversation {
  final String id;
  final String listingId;
  final UserProfile otherUser;
  final List<ChatMessage> messages;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.listingId,
    required this.otherUser,
    required this.messages,
    this.unreadCount = 0,
  });

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  DateTime get lastActivity =>
      lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Aperçu affiché dans la liste des conversations.
  String get preview {
    final m = lastMessage;
    if (m == null) return 'Nouvelle conversation';
    switch (m.type) {
      case MessageType.offre:
        return 'Offre proposée : ${formatAmount(m.offerAmount ?? 0)} F';
      case MessageType.systeme:
        return m.content ?? '';
      case MessageType.texte:
        return m.content ?? '';
    }
  }

  Conversation copyWith({List<ChatMessage>? messages, int? unreadCount}) {
    return Conversation(
      id: id,
      listingId: listingId,
      otherUser: otherUser,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class Review {
  final String id;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime date;

  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
