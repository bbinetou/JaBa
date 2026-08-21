import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

import '../models/models.dart';
import 'countries.dart';
import 'local_store.dart';

/// Authentification locale, persistée sur l'appareil via [LocalStore].
/// Mots de passe jamais stockés en clair (hachage SHA-256, [_hashPassword]).
/// Aucun compte n'est pré-enregistré.
enum AuthStatus { checking, signedOut, signedIn }

/// Étapes du parcours téléphone : numéro, code, puis nom pour un nouveau
/// compte (un compte existant saute directement à la connexion).
enum PhoneStep { number, code, name }

/// Empreinte du mot de passe : jamais stocké en clair sur l'appareil.
String _hashPassword(String password) =>
    sha256.convert(utf8.encode('jaba::$password')).toString();

class _Account {
  _Account({
    required this.passwordHash,
    required this.profile,
    required this.phone,
  });

  final String passwordHash;
  final String phone;
  UserProfile profile;

  Map<String, dynamic> toJson() => {
        'passwordHash': passwordHash,
        'phone': phone,
        'profile': profile.toJson(),
      };

  factory _Account.fromJson(Map<String, dynamic> json) => _Account(
        passwordHash: json['passwordHash'] as String,
        phone: json['phone'] as String? ?? '',
        profile: UserProfile.fromJson(
          Map<String, dynamic>.from(json['profile'] as Map),
        ),
      );
}

class AuthController extends ChangeNotifier {
  AuthController(this._store) {
    _restoreSession();
  }

  static const _accountsKey = 'auth.accounts.v1';
  static const _sessionKey = 'auth.session.v1';

  final LocalStore _store;

  /// Durée de validité du code OTP — section 5.1 du cahier des charges.
  static const otpValidity = Duration(minutes: 5);
  static const _maxOtpAttempts = 3;

  /// Comptes enregistrés, indexés par adresse e-mail en minuscules.
  final Map<String, _Account> _accounts = {};

  final _random = Random();

  AuthStatus _status = AuthStatus.checking;
  UserProfile? _user;
  bool _busy = false;
  String? _error;

  PhoneStep _phoneStep = PhoneStep.number;
  String? _pendingPhone;
  Country _pendingCountry = Countries.senegal;
  String? _sentCode;
  DateTime? _otpSentAt;
  int _otpAttempts = 0;

  /// Clé du compte connecté (`email:...` ou `phone:...`), utilisée par
  /// [AppState] pour isoler le catalogue/favoris/messages de chaque compte.
  String? _currentAccountKey;

  // ---------------------------------------------------------------- lecture

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  bool get busy => _busy;
  String? get error => _error;
  PhoneStep get phoneStep => _phoneStep;
  String? get pendingPhone => _pendingPhone;
  Country get pendingCountry => _pendingCountry;
  int get remainingOtpAttempts => _maxOtpAttempts - _otpAttempts;
  bool get hasAccounts => _accounts.isNotEmpty;

  /// Clé stable du compte connecté, utilisée pour isoler ses données dans
  /// [AppState] (`null` tant que personne n'est connecté).
  String? get currentAccountKey => _currentAccountKey;

  /// Code réellement « envoyé ».
  ///
  /// Faute de passerelle SMS, l'écran de vérification l'affiche dans une
  /// notification imitant un SMS entrant : le parcours reste testable sans
  /// exposer de mot de passe en dur sur l'écran de connexion.
  String? get sentCode => _sentCode;

  /// Secondes restantes avant expiration du code, pour le compte à rebours
  /// affiché sous les cases de saisie.
  int get otpSecondsLeft {
    if (_otpSentAt == null) return 0;
    final left = otpValidity - DateTime.now().difference(_otpSentAt!);
    return left.isNegative ? 0 : left.inSeconds;
  }

  bool get otpExpired => _otpSentAt != null && otpSecondsLeft == 0;

  /// Numéro affiché en clair pendant la saisie du code.
  String get pendingPhoneLabel =>
      formatPhone(_pendingPhone ?? '', _pendingCountry);

  // ------------------------------------------------------------- validation

  /// Ne conserve que les chiffres et retire l'indicatif s'il a été saisi.
  static String normalizePhone(String input, Country country) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length > country.maxLength &&
        digits.startsWith(country.dialCode)) {
      digits = digits.substring(country.dialCode.length);
    }
    // Certains pays notent le mobile avec un 0 initial (France, Belgique…).
    if (digits.length > country.maxLength && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// « +221 77 123 45 67 » : groupes de deux ou trois chiffres selon la
  /// longueur, suffisant pour une lecture confortable.
  static String formatPhone(String raw, Country country) {
    final d = normalizePhone(raw, country);
    if (d.isEmpty) return '';
    final buffer = StringBuffer('+${country.dialCode} ');
    if (d.length == 9) {
      buffer.write('${d.substring(0, 2)} ${d.substring(2, 5)} '
          '${d.substring(5, 7)} ${d.substring(7)}');
    } else {
      for (var i = 0; i < d.length; i += 3) {
        buffer.write(d.substring(i, (i + 3).clamp(0, d.length)));
        if (i + 3 < d.length) buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  /// Validation adaptée au pays sélectionné : longueur attendue, et
  /// préfixes d'opérateurs quand ils sont connus (cas du Sénégal).
  static String? validatePhone(String? input, Country country) {
    final digits = normalizePhone(input ?? '', country);
    if (digits.isEmpty) return 'Entrez votre numéro de téléphone';
    if (digits.length < country.minLength) {
      return country.minLength == country.maxLength
          ? 'Le numéro doit contenir ${country.minLength} chiffres'
          : 'Numéro trop court pour ${country.name}';
    }
    if (digits.length > country.maxLength) {
      return country.minLength == country.maxLength
          ? 'Le numéro doit contenir ${country.maxLength} chiffres'
          : 'Numéro trop long pour ${country.name}';
    }
    if (country.mobilePrefixes.isNotEmpty &&
        !country.mobilePrefixes.any(digits.startsWith)) {
      return 'Opérateur non reconnu '
          '(${country.mobilePrefixes.join(', ')})';
    }
    return null;
  }

  static String? validateEmail(String? input) {
    final value = (input ?? '').trim();
    if (value.isEmpty) return 'Entrez votre adresse e-mail';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(value)) {
      return 'Adresse e-mail invalide';
    }
    return null;
  }

  static String? validatePassword(String? input) {
    final value = input ?? '';
    if (value.isEmpty) return 'Entrez votre mot de passe';
    if (value.length < 8) return 'Au moins 8 caractères';
    return null;
  }

  static String? validateName(String? input) {
    final value = (input ?? '').trim();
    if (value.isEmpty) return 'Entrez votre nom';
    if (value.length < 3) return 'Nom trop court';
    return null;
  }

  /// Indicateur de robustesse du mot de passe (0 → 1) affiché à l'inscription.
  static double passwordStrength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score / 5;
  }

  static String passwordStrengthLabel(String value) {
    final s = passwordStrength(value);
    if (value.isEmpty) return '';
    if (s < 0.4) return 'Faible';
    if (s < 0.7) return 'Moyen';
    return 'Solide';
  }

  // ---------------------------------------------------------------- actions

  static String _emailKey(String email) => 'email:${email.trim().toLowerCase()}';
  static String _phoneKey(String digits) => 'phone:$digits';

  Future<void> _restoreSession() async {
    final stored = _store.getJson<Map<String, dynamic>>(
      _accountsKey,
      (decoded) => Map<String, dynamic>.from(decoded as Map),
    );
    if (stored != null) {
      stored.forEach((key, value) {
        _accounts[key] =
            _Account.fromJson(Map<String, dynamic>.from(value as Map));
      });
    }

    // Emplacement du futur `FirebaseAuth.authStateChanges()` : ici, on se
    // contente d'un court délai pour laisser le splash s'afficher.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final sessionKey = _store.getString(_sessionKey);
    final account = sessionKey == null ? null : _accounts[sessionKey];
    if (account != null) {
      _currentAccountKey = sessionKey;
      _user = account.profile;
      _status = AuthStatus.signedIn;
    } else {
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> _persistAccounts() {
    final json = {for (final e in _accounts.entries) e.key: e.value.toJson()};
    return _store.setJson(_accountsKey, json);
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Connexion e-mail + mot de passe.
  Future<bool> signInWithEmail(String email, String password) async {
    _begin();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final key = _emailKey(email);
    final account = _accounts[key];
    if (account == null) {
      return _fail('Aucun compte associé à cette adresse. Créez-en un.');
    }
    if (account.passwordHash != _hashPassword(password)) {
      return _fail('Mot de passe incorrect');
    }
    _currentAccountKey = key;
    return _succeed(account.profile);
  }

  /// Envoi du code de vérification au numéro saisi.
  Future<bool> requestOtp(String phone, Country country) async {
    _begin();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final invalid = validatePhone(phone, country);
    if (invalid != null) return _fail(invalid);

    _pendingCountry = country;
    _pendingPhone = normalizePhone(phone, country);
    _sentCode = (100000 + _random.nextInt(900000)).toString();
    _otpSentAt = DateTime.now();
    _otpAttempts = 0;
    _phoneStep = PhoneStep.code;
    _busy = false;
    notifyListeners();
    return true;
  }

  Future<bool> resendOtp() async {
    if (_pendingPhone == null) return false;
    return requestOtp(_pendingPhone!, _pendingCountry);
  }

  /// Vérification du code : expiration au bout de 5 minutes et nombre
  /// d'essais limité, comme sur un vrai service OTP.
  Future<bool> verifyOtp(String code) async {
    _begin();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (code.length != 6) {
      return _fail('Le code comporte 6 chiffres');
    }
    if (otpExpired) {
      return _fail('Code expiré, demandez-en un nouveau');
    }
    if (code != _sentCode) {
      _otpAttempts++;
      if (_otpAttempts >= _maxOtpAttempts) {
        _resetPhoneFlow();
        return _fail('Trop de tentatives. Recommencez avec votre numéro.');
      }
      return _fail('Code incorrect — $remainingOtpAttempts essai(s) restant(s)');
    }

    // Un numéro déjà rattaché à un compte le rouvre directement ; un numéro
    // inconnu demande d'abord le nom, avant de créer le compte.
    final phoneKey = _phoneKey(_pendingPhone!);
    final existing = _accounts[phoneKey];
    if (existing != null) {
      _currentAccountKey = phoneKey;
      _resetPhoneFlow();
      return _succeed(existing.profile);
    }

    _busy = false;
    _error = null;
    _phoneStep = PhoneStep.name;
    notifyListeners();
    return true;
  }

  /// Finalise l'inscription par téléphone une fois le nom renseigné.
  Future<bool> completePhoneSignup(String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 3) {
      _error = 'Entrez votre nom';
      notifyListeners();
      return false;
    }

    _begin();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final phoneKey = _phoneKey(_pendingPhone!);
    final profile = _createProfile(
      name: trimmed,
      phone: formatPhone(_pendingPhone!, _pendingCountry),
    );
    _accounts[phoneKey] = _Account(
      passwordHash: '',
      phone: _pendingPhone!,
      profile: profile,
    );
    await _persistAccounts();

    _currentAccountKey = phoneKey;
    _resetPhoneFlow();
    return _succeed(profile);
  }

  /// Inscription : le compte créé est réellement enregistré et permet de se
  /// reconnecter ensuite avec les mêmes identifiants.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String zone,
    String phone = '',
    Country? country,
  }) async {
    _begin();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final key = _emailKey(email);
    if (_accounts.containsKey(key)) {
      return _fail('Un compte existe déjà avec cette adresse');
    }

    final resolvedCountry = country ?? Countries.senegal;
    final normalizedPhone =
        phone.isEmpty ? '' : normalizePhone(phone, resolvedCountry);

    final profile = _createProfile(
      name: name.trim(),
      phone: normalizedPhone.isEmpty
          ? ''
          : formatPhone(normalizedPhone, resolvedCountry),
      email: email.trim().toLowerCase(),
      zone: zone,
    );
    _accounts[key] = _Account(
      passwordHash: _hashPassword(password),
      phone: normalizedPhone,
      profile: profile,
    );
    await _persistAccounts();
    _currentAccountKey = key;
    return _succeed(profile);
  }

  UserProfile _createProfile({
    required String name,
    required String phone,
    String? email,
    String zone = 'Dakar',
  }) {
    return UserProfile(
      id: 'me',
      displayName: name,
      zone: zone,
      averageRating: 0,
      reviewCount: 0,
      activeListingsCount: 0,
      memberSince: DateTime.now(),
      phone: phone.isEmpty ? null : phone,
      email: email,
    );
  }

  void backToPhoneNumber() {
    _resetPhoneFlow();
    _error = null;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _status = AuthStatus.signedOut;
    _currentAccountKey = null;
    _store.remove(_sessionKey);
    _resetPhoneFlow();
    _error = null;
    notifyListeners();
  }

  void _resetPhoneFlow() {
    _phoneStep = PhoneStep.number;
    _pendingPhone = null;
    _sentCode = null;
    _otpSentAt = null;
    _otpAttempts = 0;
  }

  void _begin() {
    _busy = true;
    _error = null;
    notifyListeners();
  }

  bool _fail(String message) {
    _busy = false;
    _error = message;
    notifyListeners();
    return false;
  }

  bool _succeed(UserProfile profile) {
    _busy = false;
    _error = null;
    _user = profile;
    _status = AuthStatus.signedIn;
    if (_currentAccountKey != null) {
      _store.setString(_sessionKey, _currentAccountKey!);
    }
    notifyListeners();
    return true;
  }
}

/// Accès à l'authentification depuis l'arbre de widgets.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope introuvable dans l\'arbre de widgets');
    return scope!.notifier!;
  }

  static AuthController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope introuvable dans l\'arbre de widgets');
    return scope!.notifier!;
  }
}
