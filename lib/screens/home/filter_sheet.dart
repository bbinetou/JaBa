import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Panneau de filtres avancés.
///
/// Les réglages sont manipulés sur une copie locale : le feed n'est modifié
/// qu'au moment de valider. En revanche, le bouton d'action annonce en direct
/// le nombre d'articles correspondants — on sait ce qu'on obtiendra avant
/// de fermer le panneau.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.countFor,
    required this.onApply,
    required this.onReset,
  });

  final ListingFilters initial;
  final int Function(ListingFilters) countFor;
  final ValueChanged<ListingFilters> onApply;
  final VoidCallback onReset;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late ListingFilters _draft = widget.initial;

  void _update(ListingFilters next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final count = widget.countFor(_draft);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtres avancés',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => _update(ListingFilters(query: _draft.query)),
                  child: const Text('Réinitialiser'),
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
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              children: [
                const _Label('Catégorie'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Choice(
                      label: 'Toutes',
                      selected: _draft.category == null,
                      onTap: () => _update(_draft.copyWith(clearCategory: true)),
                    ),
                    for (final category in ListingCategory.values)
                      _Choice(
                        label: category.chipLabel,
                        icon: category.icon,
                        selected: _draft.category == category,
                        onTap: () => _update(
                          _draft.category == category
                              ? _draft.copyWith(clearCategory: true)
                              : _draft.copyWith(category: category),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const _Label('Prix'),
                    const Spacer(),
                    Text(
                      '${formatAmount(_draft.minPrice)} – '
                      '${formatAmount(_draft.maxPrice)} F',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(
                    _draft.minPrice.toDouble(),
                    _draft.maxPrice.toDouble(),
                  ),
                  min: ListingFilters.priceFloor.toDouble(),
                  max: ListingFilters.priceCeiling.toDouble(),
                  divisions: 40,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  labels: RangeLabels(
                    formatAmount(_draft.minPrice),
                    formatAmount(_draft.maxPrice),
                  ),
                  onChanged: (values) => _update(_draft.copyWith(
                    minPrice: values.start.round(),
                    maxPrice: values.end.round(),
                  )),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const _Label('Distance maximale'),
                    const Spacer(),
                    Text(
                      _draft.maxDistanceKm >= ListingFilters.distanceCeiling
                          ? 'Toute la région'
                          : '${_draft.maxDistanceKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _draft.maxDistanceKm,
                  min: 1,
                  max: ListingFilters.distanceCeiling,
                  divisions: 29,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  onChanged: (value) =>
                      _update(_draft.copyWith(maxDistanceKm: value)),
                ),
                const SizedBox(height: 16),
                const _Label('État de l\'article'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ItemCondition.values.map((condition) {
                    final selected = _draft.conditions.contains(condition);
                    return _Choice(
                      label: condition.label,
                      selected: selected,
                      onTap: () {
                        final next = {..._draft.conditions};
                        if (!next.add(condition)) next.remove(condition);
                        _update(_draft.copyWith(conditions: next));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _SwitchRow(
                  label: 'Prix négociable uniquement',
                  icon: Icons.swap_horiz,
                  value: _draft.negotiableOnly,
                  onChanged: (v) => _update(_draft.copyWith(negotiableOnly: v)),
                ),
                _SwitchRow(
                  label: 'Masquer les articles vendus',
                  icon: Icons.visibility_off_outlined,
                  value: _draft.hideSold,
                  onChanged: (v) => _update(_draft.copyWith(hideSold: v)),
                ),
                const SizedBox(height: 20),
                const _Label('Trier les résultats'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SortOption.values
                      .map((option) => _Choice(
                            label: option.label,
                            icon: option.icon,
                            selected: _draft.sort == option,
                            onTap: () => _update(_draft.copyWith(sort: option)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // Barre d'action : le libellé suit le nombre de résultats en direct.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: count == 0
                    ? null
                    : () {
                        widget.onApply(_draft);
                        Navigator.pop(context);
                      },
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Text(
                    key: ValueKey(count),
                    count == 0
                        ? 'Aucun article ne correspond'
                        : 'Voir $count article${count > 1 ? 's' : ''}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? AppColors.background : AppColors.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.background : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColors.primary,
      dense: true,
      title: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
