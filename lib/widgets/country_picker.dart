import 'package:flutter/material.dart';

import '../data/countries.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Bouton d'indicatif téléphonique : drapeau + code, ouvre la liste des pays.
///
/// Placé en préfixe du champ « numéro », il permet de saisir un numéro
/// étranger sans quitter le formulaire.
class CountryCodeField extends StatelessWidget {
  const CountryCodeField({
    super.key,
    required this.country,
    required this.onChanged,
    this.enabled = true,
  });

  final Country country;
  final ValueChanged<Country> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _openPicker(context) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sur les plateformes sans glyphes de drapeaux (Windows), l'émoji
            // retombe sur le code ISO — l'information reste lisible.
            Text(country.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 7),
            Text(
              country.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondary),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.only(left: 8),
              color: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _CountryPickerSheet(selected: country),
    );
    if (selected != null) onChanged(selected);
  }
}

/// Liste des pays, recherchable par nom ou par indicatif.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});

  final Country selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  late List<Country> _results = Countries.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() => _results = Countries.search(query));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
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
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Indicatif du pays',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                key: const Key('country-search'),
                controller: _searchController,
                onChanged: _search,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Rechercher un pays ou un indicatif…',
                  prefixIcon: const Icon(Icons.search, size: 19),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 17),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _results.isEmpty
                  ? const EmptyState(
                      icon: Icons.public_off,
                      title: 'Aucun pays trouvé',
                      message: 'Vérifiez l\'orthographe ou saisissez '
                          'directement l\'indicatif.',
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 62,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, i) {
                        final country = _results[i];
                        final selected = country == widget.selected;

                        return ListTile(
                          onTap: () => Navigator.pop(context, country),
                          leading: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 26),
                          ),
                          title: Text(
                            country.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                country.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle,
                                    size: 18, color: AppColors.primary),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
