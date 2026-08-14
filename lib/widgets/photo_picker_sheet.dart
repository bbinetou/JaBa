import 'package:flutter/material.dart';

import '../data/demo_catalog.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Ajout de photos à une annonce.
///
/// L'application ne dépend pas encore de `image_picker` : la « galerie de
/// l'appareil » est simulée par les images embarquées dans `assets/images/`
/// qui ne sont rattachées à aucune annonce — `ordi3.jpeg` notamment, laissée
/// libre exprès pour cette démonstration. Le parcours (choix de la source,
/// sélection multiple, aperçu, photo de couverture, retrait) est en revanche
/// exactement celui de l'application finale : le jour où `image_picker` sera
/// branché, seule la méthode [pickFromGallery] changera.
class PhotoPicker {
  PhotoPicker._();

  /// Propose les deux sources habituelles, puis renvoie les chemins choisis.
  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> alreadySelected,
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
              padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ajouter une photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Une photo nette et bien éclairée fait vendre deux fois plus vite.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              title: 'Prendre une photo',
              subtitle: 'Appareil photo de l\'appareil',
              onTap: () async {
                final picked = await _openGallery(
                  sheetContext,
                  alreadySelected: alreadySelected,
                  remainingSlots: remainingSlots,
                  fromCamera: true,
                );
                if (sheetContext.mounted) Navigator.pop(sheetContext, picked);
              },
            ),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Choisir dans la galerie',
              subtitle: 'Photos enregistrées sur l\'appareil',
              onTap: () async {
                final picked = await _openGallery(
                  sheetContext,
                  alreadySelected: alreadySelected,
                  remainingSlots: remainingSlots,
                  fromCamera: false,
                );
                if (sheetContext.mounted) Navigator.pop(sheetContext, picked);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Galerie de l'appareil (simulée) : n'affiche que les photos qui ne sont
  /// pas déjà attachées à l'annonce en cours.
  static Future<List<String>?> _openGallery(
    BuildContext context, {
    required List<String> alreadySelected,
    required int remainingSlots,
    required bool fromCamera,
  }) {
    final available = Assets.all
        .where((path) => !alreadySelected.contains(path))
        .toList();

    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _GallerySheet(
        available: available,
        remainingSlots: remainingSlots,
        fromCamera: fromCamera,
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
    );
  }
}

/// Grille de sélection multiple, façon galerie système.
class _GallerySheet extends StatefulWidget {
  const _GallerySheet({
    required this.available,
    required this.remainingSlots,
    required this.fromCamera,
  });

  final List<String> available;
  final int remainingSlots;
  final bool fromCamera;

  @override
  State<_GallerySheet> createState() => _GallerySheetState();
}

class _GallerySheetState extends State<_GallerySheet> {
  final _picked = <String>[];

  void _toggle(String path) {
    setState(() {
      if (_picked.contains(path)) {
        _picked.remove(path);
      } else if (_picked.length < widget.remainingSlots) {
        _picked.add(path);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
              'Vous ne pouvez ajouter que ${widget.remainingSlots} photo(s) de plus',
            ),
          ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => Column(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.fromCamera ? 'Pellicule' : 'Galerie',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.available.isEmpty
                ? const EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: 'Aucune autre photo',
                    message: 'Toutes les photos disponibles sont déjà '
                        'attachées à cette annonce.',
                  )
                : GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: widget.available.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, i) {
                      final path = widget.available[i];
                      final index = _picked.indexOf(path);
                      final selected = index != -1;

                      return GestureDetector(
                        onTap: () => _toggle(path),
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.border,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ListingPhoto(path: path),
                              if (selected)
                                Container(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: AnimatedScale(
                                  duration: AppMotion.fast,
                                  scale: selected ? 1 : 0.6,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary
                                          : Colors.black.withValues(alpha: 0.28),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: selected
                                        ? Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () => Navigator.pop(context, List.of(_picked)),
                child: Text(
                  _picked.isEmpty
                      ? 'Sélectionnez une photo'
                      : 'Ajouter ${_picked.length} photo${_picked.length > 1 ? 's' : ''}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
