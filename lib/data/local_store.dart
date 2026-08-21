import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale (sur l'appareil) : comptes, catalogue, messages.
///
/// `shared_preferences` a été choisi pour cette première version car il ne
/// demande aucune configuration (pas de projet cloud, pas de base native à
/// initialiser) tout en fonctionnant sur toutes les cibles du projet
/// (Windows, Android, iOS, web). Le jour où l'application migre vers un vrai
/// service (Firebase ou autre, section 6.3 du cahier des charges), seule
/// cette classe change : le reste du code ne connaît que `getJson`/`setJson`.
class LocalStore {
  LocalStore._(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore._(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  /// Lit une valeur JSON, ou `null` si absente ou corrompue.
  T? getJson<T>(String key, T Function(dynamic decoded) decode) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return decode(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Object? value) =>
      _prefs.setString(key, jsonEncode(value));
}
