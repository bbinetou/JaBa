import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/photo_platform.dart';
import '../theme/app_theme.dart';

/// Ajout de photos à une annonce : appareil photo ou galerie réelle de
/// l'appareil, via `image_picker`. Les photos importées sont copiées dans le
/// stockage de l'application (sur le web : encodées en data URI) pour rester
/// disponibles après redémarrage.
class PhotoPicker {
  PhotoPicker._();

  static final _picker = ImagePicker();

  static Future<List<String>?> show(
    BuildContext context, {
    required int remainingSlots,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ajouter une photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              title: 'Prendre une photo',
              onTap: () async {
                final path = await _capture(context);
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext, path == null ? null : [path]);
                }
              },
            ),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Choisir dans la galerie',
              onTap: () async {
                final paths = await _pickMultiple(context, remainingSlots);
                if (sheetContext.mounted) Navigator.pop(sheetContext, paths);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Future<String?> _capture(BuildContext context) async {
    try {
      final file =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file == null) return null;
      return persistPickedPhoto(file);
    } catch (_) {
      if (context.mounted) _showError(context);
      return null;
    }
  }

  static Future<List<String>?> _pickMultiple(
      BuildContext context, int remainingSlots) async {
    try {
      final files =
          await _picker.pickMultiImage(imageQuality: 85, limit: remainingSlots);
      if (files.isEmpty) return null;
      final paths = <String>[];
      for (final file in files.take(remainingSlots)) {
        paths.add(await persistPickedPhoto(file));
      }
      return paths;
    } catch (_) {
      if (context.mounted) _showError(context);
      return null;
    }
  }

  static void _showError(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Accès à la photo impossible'),
        backgroundColor: AppColors.danger,
      ));
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
    );
  }
}
