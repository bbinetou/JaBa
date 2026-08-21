import '../models/models.dart';

/// Jeu de données de démonstration.
///
/// Les photos de `assets/images/` correspondent à **cinq objets réellement
/// photographiés**, chacun sous plusieurs angles :
///  - `robe_wax1/2/3.png`     → une robe wax bleue, vue de trois façons ;
///  - `boubouhomme1/2/3.jpeg` → un grand boubou homme brodé, trois vues ;
///  - `chaussures1/2.jpeg`    → une paire de baskets en cuir, deux vues ;
///  - `sac1/2.jpeg`           → un sac cabas monogrammé, deux vues ;
///  - `ordi1/2.jpeg`          → un ThinkPad T14s, deux vues.
///
/// Le catalogue reflète donc exactement la réalité : **une annonce par objet**,
/// la première photo servant de couverture dans le feed, les suivantes
/// alimentant le carrousel de la fiche produit.
///
/// `ordi3.jpeg` n'est volontairement rattaché à aucune annonce : il reste
/// disponible dans la galerie de l'appareil pour la démonstration d'ajout
/// de photo lors de la publication d'une annonce.
class Assets {
  static const robeWax1 = 'assets/images/robe_wax1.png';
  static const robeWax2 = 'assets/images/robe_wax2.png';
  static const robeWax3 = 'assets/images/robe_wax3.png';
  static const boubou1 = 'assets/images/boubouhomme1.jpeg';
  static const boubou2 = 'assets/images/boubouhomme2.jpeg';
  static const boubou3 = 'assets/images/boubouhomme3.jpeg';
  static const chaussures1 = 'assets/images/chaussures1.jpeg';
  static const chaussures2 = 'assets/images/chaussures2.jpeg';
  static const sac1 = 'assets/images/sac1.jpeg';
  static const sac2 = 'assets/images/sac2.jpeg';
  static const ordi1 = 'assets/images/ordi1.jpeg';
  static const ordi2 = 'assets/images/ordi2.jpeg';
  static const ordi3 = 'assets/images/ordi3.jpeg';

  /// Photos de la robe wax : couverture puis angles complémentaires.
  static const robeWax = [robeWax1, robeWax2, robeWax3];

  /// Photos du grand boubou : buste brodé, puis vues d'ensemble.
  static const boubou = [boubou1, boubou2, boubou3];

  /// Photos des baskets : profil puis second angle.
  static const chaussures = [chaussures1, chaussures2];

  /// Photos du sac cabas.
  static const sac = [sac1, sac2];

  /// Photos du ThinkPad : couverture puis second angle.
  static const thinkpad = [ordi1, ordi2];

  /// Photos non rattachées à une annonce, proposées comme « galerie de
  /// l'appareil » au moment de publier.
  static const galleryOnly = [ordi3];

  static const all = [
    robeWax1,
    robeWax2,
    robeWax3,
    boubou1,
    boubou2,
    boubou3,
    chaussures1,
    chaussures2,
    sac1,
    sac2,
    ordi1,
    ordi2,
    ordi3,
  ];
}

DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
    DateTime.now().subtract(Duration(days: days, hours: hours, minutes: minutes));

class DemoData {
  DemoData._();

  /// Vendeurs du catalogue. L'utilisateur connecté est toujours quelqu'un
  /// d'autre : il peut donc réellement contacter ces vendeurs et négocier.
  static final UserProfile fatou = UserProfile(
    id: 'u1',
    displayName: 'Fatou Ndiaye',
    zone: 'Sacré-Cœur',
    averageRating: 4.9,
    reviewCount: 41,
    activeListingsCount: 1,
    salesCount: 52,
    memberSince: DateTime(2025, 11, 4),
    badges: const ['Super vendeuse', 'Réponses rapides'],
    verified: true,
    phone: '+221 77 111 22 33',
  );

  static final UserProfile moussa = UserProfile(
    id: 'u2',
    displayName: 'Moussa Sow',
    zone: 'Plateau',
    averageRating: 4.6,
    reviewCount: 18,
    activeListingsCount: 1,
    salesCount: 21,
    memberSince: DateTime(2026, 1, 22),
    verified: true,
    phone: '+221 78 222 33 44',
  );

  static final UserProfile cheikh = UserProfile(
    id: 'u3',
    displayName: 'Cheikh Fall',
    zone: 'Ouakam',
    averageRating: 4.7,
    reviewCount: 26,
    activeListingsCount: 1,
    salesCount: 30,
    memberSince: DateTime(2025, 9, 15),
    badges: const ['Réponses rapides'],
    verified: true,
    phone: '+221 76 333 44 55',
  );

  static final UserProfile awa = UserProfile(
    id: 'u4',
    displayName: 'Awa Ba',
    zone: 'Almadies',
    averageRating: 4.8,
    reviewCount: 33,
    activeListingsCount: 1,
    salesCount: 39,
    memberSince: DateTime(2025, 8, 9),
    badges: const ['Super vendeuse'],
    verified: true,
    phone: '+221 70 444 55 66',
  );

  static final UserProfile ndeye = UserProfile(
    id: 'u5',
    displayName: 'Ndeye Gueye',
    zone: 'Point E',
    averageRating: 4.5,
    reviewCount: 14,
    activeListingsCount: 1,
    salesCount: 17,
    memberSince: DateTime(2026, 2, 3),
    phone: '+221 77 555 66 77',
  );

  static final List<UserProfile> sellers = [fatou, moussa, cheikh, awa, ndeye];

  static UserProfile? sellerById(String id) {
    for (final seller in sellers) {
      if (seller.id == id) return seller;
    }
    return null;
  }

  /// Identifiants des annonces de départ.
  static const robeListingId = 'robe-wax-bleue';
  static const boubouListingId = 'boubou-homme-brode';
  static const chaussuresListingId = 'baskets-cuir-marine';
  static const sacListingId = 'sac-cabas-monogramme';
  static const pcListingId = 'thinkpad-t14s';

  static List<Listing> listings() => [
        Listing(
          id: robeListingId,
          sellerId: fatou.id,
          sellerName: fatou.displayName,
          sellerRating: fatou.averageRating,
          title: 'Robe wax longue, motif éventail',
          description:
              "Robe longue en wax authentique, motif éventail bleu roi et turquoise. "
              "Taille M, portée deux fois pour un baptême. Coupe cintrée à la taille "
              "avec ceinture nouée et fente sur le côté. Le haut se noue de deux "
              "façons : avec petites manches ou en bustier — les photos montrent "
              "les deux versions ainsi qu'un plan rapproché du tissu.\n\n"
              "Tissu épais, coutures nettes, aucune décoloration. Lavée et repassée, "
              "prête à porter.",
          category: ListingCategory.femme,
          size: 'M',
          condition: ItemCondition.tresBonEtat,
          price: 6500,
          negotiable: true,
          photos: Assets.robeWax,
          zone: fatou.zone,
          distanceKm: 2.4,
          publishedAt: _ago(hours: 3),
          views: 128,
        ),
        Listing(
          id: boubouListingId,
          sellerId: cheikh.id,
          sellerName: cheikh.displayName,
          sellerRating: cheikh.averageRating,
          title: 'Grand boubou homme brodé, bleu ciel',
          description:
              "Grand boubou trois pièces en bazin bleu ciel, avec broderie argentée "
              "au plastron et sur le col. Taille L, porté deux fois pour des "
              "cérémonies. Coupe ample traditionnelle, tissu qui tombe bien.\n\n"
              "Les photos montrent le plastron brodé de près puis l'ensemble porté. "
              "Aucune tache ni fil tiré, repassé et prêt à porter.",
          category: ListingCategory.homme,
          size: 'L',
          condition: ItemCondition.tresBonEtat,
          price: 35000,
          negotiable: true,
          photos: Assets.boubou,
          zone: cheikh.zone,
          distanceKm: 8.3,
          publishedAt: _ago(hours: 7),
          views: 84,
        ),
        Listing(
          id: chaussuresListingId,
          sellerId: ndeye.id,
          sellerName: ndeye.displayName,
          sellerRating: ndeye.averageRating,
          title: 'Baskets en cuir bleu marine, pointure 42',
          description:
              "Baskets basses en cuir bleu marine, semelle épaisse blanche, empeigne "
              "à effet croco sur le côté et marquage « 1895 Paris » sur le flanc. "
              "Pointure 42, portées une saison.\n\n"
              "Cuir en bon état, quelques marques d'usage sur la semelle visibles "
              "sur la seconde photo. Aucune couture décousue. Vendues sans boîte, "
              "authenticité non garantie — à voir sur place.",
          category: ListingCategory.chaussures,
          size: '42',
          condition: ItemCondition.bonEtat,
          price: 8000,
          negotiable: true,
          photos: Assets.chaussures,
          zone: ndeye.zone,
          distanceKm: 3.6,
          publishedAt: _ago(days: 1, hours: 5),
          views: 176,
        ),
        Listing(
          id: sacListingId,
          sellerId: awa.id,
          sellerName: awa.displayName,
          sellerRating: awa.averageRating,
          title: 'Sac cabas noir, motif monogramme embossé',
          description:
              "Grand sac cabas noir en simili cuir, motif monogramme embossé sur "
              "toute la surface, poche zippée à l'avant et anses longues portées "
              "épaule. Intérieur propre, doublure intacte.\n\n"
              "Très pratique pour le bureau ou les cours : un ordinateur 14 pouces "
              "y rentre sans problème. Article de mode, sans certificat "
              "d'authenticité.",
          category: ListingCategory.accessoires,
          condition: ItemCondition.bonEtat,
          price: 1500,
          negotiable: false,
          photos: Assets.sac,
          zone: awa.zone,
          distanceKm: 6.1,
          publishedAt: _ago(days: 2),
          views: 211,
        ),
        Listing(
          id: pcListingId,
          sellerId: moussa.id,
          sellerName: moussa.displayName,
          sellerRating: moussa.averageRating,
          title: 'Lenovo ThinkPad T14s — i7, 16 Go',
          description:
              "ThinkPad T14s, Core i7 de 10e génération, 16 Go de RAM, SSD 512 Go. "
              "Clavier rétroéclairé impeccable, TrackPoint et lecteur d'empreintes "
              "fonctionnels. Batterie qui tient environ 5 h en bureautique. "
              "Chargeur d'origine inclus.\n\n"
              "Les photos montrent la machine ouverte de face et de côté : "
              "quelques micro-rayures sur le capot, rien sur l'écran.",
          category: ListingCategory.electronique,
          condition: ItemCondition.tresBonEtat,
          price: 185000,
          negotiable: true,
          photos: Assets.thinkpad,
          zone: moussa.zone,
          distanceKm: 4.8,
          publishedAt: _ago(days: 1, hours: 2),
          views: 96,
          brand: 'Lenovo',
        ),
      ];

  /// Conversations de départ, rattachées à des annonces du catalogue.
  static List<Conversation> conversations() => [
        Conversation(
          id: 'c1',
          listingId: robeListingId,
          otherUser: fatou,
          unreadCount: 2,
          messages: [
            ChatMessage(
              id: 'c1m1',
              senderId: 'me',
              type: MessageType.texte,
              content: 'Bonjour, la robe est toujours disponible ?',
              timestamp: _ago(hours: 2, minutes: 40),
            ),
            ChatMessage(
              id: 'c1m2',
              senderId: 'u1',
              type: MessageType.texte,
              content: 'Bonjour ! Oui elle est toujours dispo 🙂',
              timestamp: _ago(hours: 2, minutes: 22),
            ),
            ChatMessage(
              id: 'c1m3',
              senderId: 'u1',
              type: MessageType.texte,
              content: 'Je suis à Sacré-Cœur, on peut se voir en fin de journée.',
              timestamp: _ago(hours: 2, minutes: 21),
            ),
          ],
        ),
        Conversation(
          id: 'c2',
          listingId: pcListingId,
          otherUser: moussa,
          messages: [
            ChatMessage(
              id: 'c2m1',
              senderId: 'me',
              type: MessageType.texte,
              content: 'Bonsoir, la batterie tient combien de temps exactement ?',
              timestamp: _ago(days: 1, hours: 3),
            ),
            ChatMessage(
              id: 'c2m2',
              senderId: 'u2',
              type: MessageType.texte,
              content: 'Environ 5 h en usage bureautique, écran à 50 %.',
              timestamp: _ago(days: 1, hours: 2),
            ),
            ChatMessage(
              id: 'c2m3',
              senderId: 'me',
              type: MessageType.offre,
              offerAmount: 260000,
              offerStatus: OfferStatus.enAttente,
              timestamp: _ago(days: 1, hours: 1),
            ),
          ],
        ),
        Conversation(
          id: 'c3',
          listingId: boubouListingId,
          otherUser: cheikh,
          unreadCount: 1,
          messages: [
            ChatMessage(
              id: 'c3m1',
              senderId: 'me',
              type: MessageType.texte,
              content: 'Bonjour, le boubou taille bien du L ?',
              timestamp: _ago(hours: 5),
            ),
            ChatMessage(
              id: 'c3m2',
              senderId: 'u3',
              type: MessageType.texte,
              content: 'Oui, coupe ample. Vous pouvez l\'essayer sur place.',
              timestamp: _ago(hours: 4, minutes: 30),
            ),
          ],
        ),
      ];

  static const zones = [
    'Mermoz',
    'Sacré-Cœur',
    'Almadies',
    'Ouakam',
    'Plateau',
    'Point E',
    'Yoff',
    'Thiès centre',
  ];
}
