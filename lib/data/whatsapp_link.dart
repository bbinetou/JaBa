import 'package:url_launcher/url_launcher.dart';

/// Ouvre une conversation WhatsApp avec ce numéro, message pré-rempli
/// optionnel. Renvoie `false` si aucune application ne peut ouvrir le lien.
Future<bool> openWhatsApp(String phone, {String? message}) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return false;
  final uri = Uri.https(
    'wa.me',
    '/$digits',
    message == null || message.isEmpty ? null : {'text': message},
  );
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
