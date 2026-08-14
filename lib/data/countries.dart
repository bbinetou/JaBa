/// Indicatifs téléphoniques internationaux, pour le sélecteur de pays de
/// l'écran de connexion et de l'inscription.
class Country {
  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.minLength,
    required this.maxLength,
    this.mobilePrefixes = const [],
    this.exampleNumber = '',
  });

  /// Code ISO 3166-1 alpha-2 (« SN », « FR »…).
  final String code;
  final String name;

  /// Indicatif international, sans le « + ».
  final String dialCode;

  /// Longueur attendue du numéro national (hors indicatif).
  final int minLength;
  final int maxLength;

  /// Préfixes d'opérateurs mobiles connus, quand la vérification a du sens.
  final List<String> mobilePrefixes;

  final String exampleNumber;

  /// Drapeau calculé à partir du code ISO : chaque lettre est convertie en
  /// symbole indicateur régional (A → 🇦), ce qui évite de coder en dur
  /// 40 émojis et garantit qu'ils correspondent toujours au bon pays.
  String get flag => String.fromCharCodes(
        code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
      );

  String get label => '+$dialCode';

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class Countries {
  Countries._();

  /// Pays par défaut de l'application.
  static const Country senegal = Country(
    code: 'SN',
    name: 'Sénégal',
    dialCode: '221',
    minLength: 9,
    maxLength: 9,
    mobilePrefixes: ['70', '75', '76', '77', '78'],
    exampleNumber: '77 123 45 67',
  );

  /// Le Sénégal en tête (marché principal), puis l'ordre alphabétique.
  static const List<Country> all = [
    senegal,
    Country(code: 'DZ', name: 'Algérie', dialCode: '213', minLength: 9, maxLength: 9, exampleNumber: '551 23 45 67'),
    Country(code: 'DE', name: 'Allemagne', dialCode: '49', minLength: 10, maxLength: 11, exampleNumber: '151 23456789'),
    Country(code: 'SA', name: 'Arabie saoudite', dialCode: '966', minLength: 9, maxLength: 9, exampleNumber: '51 234 5678'),
    Country(code: 'BE', name: 'Belgique', dialCode: '32', minLength: 9, maxLength: 9, exampleNumber: '470 12 34 56'),
    Country(code: 'BJ', name: 'Bénin', dialCode: '229', minLength: 8, maxLength: 10, exampleNumber: '90 01 12 34'),
    Country(code: 'BF', name: 'Burkina Faso', dialCode: '226', minLength: 8, maxLength: 8, exampleNumber: '70 12 34 56'),
    Country(code: 'CM', name: 'Cameroun', dialCode: '237', minLength: 9, maxLength: 9, exampleNumber: '6 71 23 45 67'),
    Country(code: 'CA', name: 'Canada', dialCode: '1', minLength: 10, maxLength: 10, exampleNumber: '514 123 4567'),
    Country(code: 'CV', name: 'Cap-Vert', dialCode: '238', minLength: 7, maxLength: 7, exampleNumber: '991 12 34'),
    Country(code: 'CN', name: 'Chine', dialCode: '86', minLength: 11, maxLength: 11, exampleNumber: '131 2345 6789'),
    Country(code: 'CG', name: 'Congo', dialCode: '242', minLength: 9, maxLength: 9, exampleNumber: '06 123 4567'),
    Country(code: 'CD', name: 'Congo (RDC)', dialCode: '243', minLength: 9, maxLength: 9, exampleNumber: '991 234 567'),
    Country(code: 'CI', name: 'Côte d\'Ivoire', dialCode: '225', minLength: 8, maxLength: 10, exampleNumber: '01 23 45 67 89'),
    Country(code: 'AE', name: 'Émirats arabes unis', dialCode: '971', minLength: 9, maxLength: 9, exampleNumber: '50 123 4567'),
    Country(code: 'ES', name: 'Espagne', dialCode: '34', minLength: 9, maxLength: 9, exampleNumber: '612 34 56 78'),
    Country(code: 'US', name: 'États-Unis', dialCode: '1', minLength: 10, maxLength: 10, exampleNumber: '201 555 0123'),
    Country(code: 'FR', name: 'France', dialCode: '33', minLength: 9, maxLength: 9, exampleNumber: '6 12 34 56 78'),
    Country(code: 'GA', name: 'Gabon', dialCode: '241', minLength: 7, maxLength: 8, exampleNumber: '06 03 12 34'),
    Country(code: 'GM', name: 'Gambie', dialCode: '220', minLength: 7, maxLength: 7, exampleNumber: '301 2345'),
    Country(code: 'GH', name: 'Ghana', dialCode: '233', minLength: 9, maxLength: 9, exampleNumber: '23 123 4567'),
    Country(code: 'GN', name: 'Guinée', dialCode: '224', minLength: 8, maxLength: 9, exampleNumber: '601 12 34 56'),
    Country(code: 'GW', name: 'Guinée-Bissau', dialCode: '245', minLength: 7, maxLength: 9, exampleNumber: '955 012 345'),
    Country(code: 'GQ', name: 'Guinée équatoriale', dialCode: '240', minLength: 9, maxLength: 9, exampleNumber: '222 123 456'),
    Country(code: 'IT', name: 'Italie', dialCode: '39', minLength: 9, maxLength: 10, exampleNumber: '312 345 6789'),
    Country(code: 'KE', name: 'Kenya', dialCode: '254', minLength: 9, maxLength: 9, exampleNumber: '712 123456'),
    Country(code: 'ML', name: 'Mali', dialCode: '223', minLength: 8, maxLength: 8, exampleNumber: '65 01 23 45'),
    Country(code: 'MA', name: 'Maroc', dialCode: '212', minLength: 9, maxLength: 9, exampleNumber: '650 123456'),
    Country(code: 'MR', name: 'Mauritanie', dialCode: '222', minLength: 8, maxLength: 8, exampleNumber: '22 12 34 56'),
    Country(code: 'NE', name: 'Niger', dialCode: '227', minLength: 8, maxLength: 8, exampleNumber: '93 12 34 56'),
    Country(code: 'NG', name: 'Nigeria', dialCode: '234', minLength: 10, maxLength: 10, exampleNumber: '802 123 4567'),
    Country(code: 'PT', name: 'Portugal', dialCode: '351', minLength: 9, maxLength: 9, exampleNumber: '912 345 678'),
    Country(code: 'CF', name: 'République centrafricaine', dialCode: '236', minLength: 8, maxLength: 8, exampleNumber: '70 01 23 45'),
    Country(code: 'GB', name: 'Royaume-Uni', dialCode: '44', minLength: 10, maxLength: 10, exampleNumber: '7400 123456'),
    Country(code: 'ZA', name: 'Afrique du Sud', dialCode: '27', minLength: 9, maxLength: 9, exampleNumber: '71 123 4567'),
    Country(code: 'CH', name: 'Suisse', dialCode: '41', minLength: 9, maxLength: 9, exampleNumber: '78 123 45 67'),
    Country(code: 'TD', name: 'Tchad', dialCode: '235', minLength: 8, maxLength: 8, exampleNumber: '63 01 23 45'),
    Country(code: 'TG', name: 'Togo', dialCode: '228', minLength: 8, maxLength: 8, exampleNumber: '90 11 23 45'),
    Country(code: 'TN', name: 'Tunisie', dialCode: '216', minLength: 8, maxLength: 8, exampleNumber: '20 123 456'),
    Country(code: 'TR', name: 'Turquie', dialCode: '90', minLength: 10, maxLength: 10, exampleNumber: '501 234 5678'),
  ];

  static Country byCode(String code) => all.firstWhere(
        (c) => c.code == code.toUpperCase(),
        orElse: () => senegal,
      );

  /// Recherche par nom ou par indicatif, pour le champ du sélecteur.
  static List<Country> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return all.where((c) {
      if (_normalize(c.name).contains(_normalize(q))) return true;
      if (c.code.toLowerCase().contains(q)) return true;
      if (digits.isNotEmpty && c.dialCode.startsWith(digits)) return true;
      return false;
    }).toList();
  }

  /// Ignore les accents pour que « senegal » trouve « Sénégal ».
  static String _normalize(String value) {
    const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
    const to = 'aaaaaceeeeiiiinooooouuuuyy';
    var result = value.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }
}
