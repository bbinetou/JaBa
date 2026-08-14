import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../data/auth_controller.dart';
import '../../data/demo_catalog.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_picker_sheet.dart';
import 'listing_detail_screen.dart';

/// Parcours de publication en 3 étapes courtes (photos → détails → prix & zone),
/// pensé pour être complété en moins de deux minutes — section 5.3.
///
/// À la validation, l'annonce est réellement créée dans [AppState] : elle
/// apparaît aussitôt en tête du feed et dans « Mes annonces ».
class PublishListingScreen extends StatefulWidget {
  const PublishListingScreen({super.key});

  @override
  State<PublishListingScreen> createState() => _PublishListingScreenState();
}

class _PublishListingScreenState extends State<PublishListingScreen> {
  static const _stepTitles = ['Photos', 'Détails', 'Prix & zone'];
  static const _maxPhotos = 5;

  int _step = 0;
  final _selectedPhotos = <String>[];

  final _detailsKey = GlobalKey<FormState>();
  final _priceKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();

  ListingCategory _category = ListingCategory.femme;
  ItemCondition _condition = ItemCondition.tresBonEtat;
  bool _negotiable = true;
  String _zone = DemoData.zones.first;
  bool _publishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Ouvre le parcours d'ajout de photo (appareil ou galerie).
  Future<void> _addPhotos() async {
    final picked = await PhotoPicker.show(
      context,
      alreadySelected: _selectedPhotos,
      remainingSlots: _maxPhotos - _selectedPhotos.length,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() => _selectedPhotos.addAll(picked));
  }

  void _removePhoto(String path) {
    setState(() => _selectedPhotos.remove(path));
  }

  /// Promeut une photo en couverture : c'est elle qui s'affichera dans le feed.
  void _makeCover(String path) {
    setState(() {
      _selectedPhotos.remove(path);
      _selectedPhotos.insert(0, path);
    });
  }

  /// Chaque étape valide ses champs avant de laisser passer à la suivante.
  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (_selectedPhotos.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Ajoutez au moins une photo'),
              backgroundColor: AppColors.danger,
            ));
          return false;
        }
        return true;
      case 1:
        return _detailsKey.currentState?.validate() ?? false;
      default:
        return _priceKey.currentState?.validate() ?? false;
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _publish() async {
    final state = AppScope.read(context);
    final user = AuthScope.read(context).user;
    if (user == null) return;

    // Références capturées avant l'attente : cet écran est retiré de la pile
    // juste après, son `context` ne doit plus servir.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _publishing = true);
    // Latence simulée : à remplacer par l'envoi Firestore + upload des photos.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final listing = state.publishListing(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      size: _sizeController.text,
      condition: _condition,
      price: int.parse(_priceController.text),
      negotiable: _negotiable,
      photos: List.of(_selectedPhotos),
      zone: _zone,
      author: user,
    );

    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Annonce publiée !'),
          action: SnackBarAction(
            label: 'Voir',
            textColor: AppColors.background,
            onPressed: () => navigator.push(
              MaterialPageRoute(
                builder: (_) => ListingDetailScreen(
                  listingId: listing.id,
                  heroPrefix: 'published',
                ),
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Publier — ${_stepTitles[_step]}'),
        leading: IconButton(
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
          onPressed: _publishing ? null : _back,
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.emphasized,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Padding(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: _buildStepContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _publishing ? null : _next,
              child: _publishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.background),
                    )
                  : Text(_step < 2 ? 'Continuer' : 'Publier l\'annonce'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _step;
          return Expanded(
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildPhotosStep();
      case 1:
        return _buildDetailsStep();
      default:
        return _buildPriceStep();
    }
  }

  /// Étape 1 — ajout des photos de l'article.
  ///
  /// Chaque photo ajoutée est une vue de l'objet : la première sert de
  /// couverture dans le feed, les suivantes alimentent le carrousel de la
  /// fiche produit.
  Widget _buildPhotosStep() {
    final canAddMore = _selectedPhotos.length < _maxPhotos;

    return ListView(
      children: [
        const Text('Photos de l\'article',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'Ajoutez jusqu\'à 5 vues du même objet (face, dos, détail…). '
          'La première sera la couverture de l\'annonce.',
          style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 18),
        if (_selectedPhotos.isEmpty)
          _buildEmptyDropZone()
        else ...[
          _buildCoverPreview(),
          const SizedBox(height: 12),
          _buildThumbnails(canAddMore),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              _selectedPhotos.isEmpty
                  ? Icons.info_outline
                  : Icons.check_circle_outline,
              size: 15,
              color: _selectedPhotos.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.success,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${_selectedPhotos.length}/$_maxPhotos photo(s) ajoutée(s)'
                '${_selectedPhotos.length > 1 ? ' · appuyez longuement sur une vignette pour la définir en couverture' : ''}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Zone d'ajout affichée tant qu'aucune photo n'a été choisie.
  Widget _buildEmptyDropZone() {
    return GestureDetector(
      onTap: _addPhotos,
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  size: 26, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Ajouter une photo',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Appareil photo ou galerie',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Grand aperçu de la photo de couverture.
  Widget _buildCoverPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ListingPhoto(path: _selectedPhotos.first, alignment: Alignment.center),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.photoScrim),
            ),
            Positioned(
              left: 12,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'Couverture',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bande de vignettes : retrait au bouton, couverture par appui long.
  Widget _buildThumbnails(bool canAddMore) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedPhotos.length + (canAddMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == _selectedPhotos.length) {
            return GestureDetector(
              onTap: _addPhotos,
              child: Container(
                width: 66,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20, color: AppColors.primary),
                    SizedBox(height: 2),
                    Text('Ajouter',
                        style: TextStyle(fontSize: 9, color: AppColors.primary)),
                  ],
                ),
              ),
            );
          }

          final path = _selectedPhotos[i];
          final isCover = i == 0;

          return GestureDetector(
            onLongPress: isCover ? null : () => _makeCover(path),
            child: SizedBox(
              width: 66,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 66,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCover ? AppColors.primary : AppColors.border,
                        width: isCover ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListingPhoto(path: path),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(path),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Étape 2 — informations descriptives.
  Widget _buildDetailsStep() {
    return Form(
      key: _detailsKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'Donnez un titre à votre annonce';
              if (v.length < 5) return 'Titre trop court';
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Robe wax imprimée, taille M',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'Décrivez brièvement votre article';
              if (v.length < 15) {
                return 'Ajoutez un peu plus de détails (15 caractères min.)';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'État, taille, raison de la vente…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<ListingCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: ListingCategory.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _sizeController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Taille (si applicable)',
              hintText: 'M, 42, unique…',
            ),
          ),
          const SizedBox(height: 18),
          const Text('État de l\'article',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ItemCondition.values
                .map((c) => ChoiceChip(
                      label: Text(c.label),
                      selected: _condition == c,
                      onSelected: (_) => setState(() => _condition = c),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: _condition == c
                            ? AppColors.background
                            : AppColors.textSecondary,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Étape 3 — prix, négociabilité et zone de remise.
  Widget _buildPriceStep() {
    return Form(
      key: _priceKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              final amount = int.tryParse(value ?? '');
              if (amount == null || amount <= 0) return 'Indiquez un prix valide';
              if (amount > ListingFilters.priceCeiling) {
                return 'Prix maximum : '
                    '${formatAmount(ListingFilters.priceCeiling)} F';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Prix',
              hintText: '8000',
              suffixText: 'FCFA',
            ),
          ),
          // Aperçu du prix mis en forme, tel qu'il apparaîtra sur l'annonce.
          if ((int.tryParse(_priceController.text) ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.visibility_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Affiché : ${formatAmount(int.parse(_priceController.text))} F',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _negotiable,
            onChanged: (v) => setState(() => _negotiable = v),
            activeThumbColor: AppColors.primary,
            title: const Text('Prix négociable', style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              'Les acheteurs pourront vous faire une offre',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _zone,
            decoration: const InputDecoration(
              labelText: 'Zone de remise en main propre',
              prefixIcon: Icon(Icons.place_outlined, size: 18),
            ),
            items: DemoData.zones
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(),
            onChanged: (value) => setState(() => _zone = value ?? _zone),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'L\'adresse exacte n\'est jamais demandée : seule la zone '
                    'est visible avant le rendez-vous.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildRecap(),
        ],
      ),
    );
  }

  /// Récapitulatif avant publication : l'utilisateur voit ce qu'il s'apprête
  /// à mettre en ligne sans avoir à revenir en arrière.
  Widget _buildRecap() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ListingPhoto(
                path: _selectedPhotos.isEmpty ? null : _selectedPhotos.first,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.trim().isEmpty
                      ? 'Votre annonce'
                      : _titleController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_category.label} · ${_condition.label}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_selectedPhotos.length} photo(s) · $_zone',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
