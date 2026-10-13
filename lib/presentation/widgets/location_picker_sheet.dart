import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../services/location_service.dart';
import '../ui/components.dart';

/// Bottom sheet to pick the farm's town or region (or detect it by GPS).
/// Saves the choice and returns `true` when the location changed.
Future<bool> showLocationPicker(
  BuildContext context, {
  required String lang,
  String? currentDistrict,
  String? currentLocality,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LocationPicker(
      lang: lang,
      currentDistrict: currentDistrict,
      currentLocality: currentLocality,
    ),
  );
  return changed ?? false;
}

class _LocationPicker extends StatefulWidget {
  final String lang;
  final String? currentDistrict;
  final String? currentLocality;

  const _LocationPicker({
    required this.lang,
    this.currentDistrict,
    this.currentLocality,
  });

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  String _query = '';
  bool _detecting = false;
  String? _error;

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: widget.lang, uz: uz, ru: ru, en: en);

  Future<void> _detect() async {
    setState(() {
      _detecting = true;
      _error = null;
    });
    final result = await LocationService().detectAndSaveLocation();
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _detecting = false;
        _error = _t(
          "GPS aniqlanmadi — ro'yxatdan tanlang",
          'GPS не определён — выберите из списка',
          'GPS unavailable — pick from the list',
        );
      });
    }
  }

  Future<void> _pickTown(UzbekistanLocality town) async {
    await LocationService.saveManualLocality(town);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDistrict(String district) async {
    await LocationService.saveManualDistrict(district);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final towns = q.isEmpty
        ? <UzbekistanLocality>[
            LocationService.chartakLocality,
            ...LocationService.uzbekistanLocalities
                .where((l) => l.nameUz != LocationService.chartakLocality.nameUz)
                .take(5),
          ]
        : LocationService.uzbekistanLocalities
            .where((l) => l.matchesQuery(_query))
            .take(8)
            .toList();
    final districts = AppConstants.districts
        .where((d) => q.isEmpty || d.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            0,
            AppSpace.screen,
            AppSpace.xl,
          ),
          children: [
            Text(
              _t('Fermangiz qayerda?', 'Где ваша ферма?', 'Where is your farm?'),
              style: AppText.section,
            ),
            const Gap(),
            OutlinedButton.icon(
              onPressed: _detecting ? null : _detect,
              icon: _detecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(_t('GPS orqali aniqlash', 'Определить по GPS', 'Detect with GPS')),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(_error!, style: AppText.caption.copyWith(color: AppColors.warning)),
            ],
            const Gap(),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: _t(
                  'Qidirish: Chortoq, Namangan…',
                  'Поиск: Чартак, Наманган…',
                  'Search: Chartak, Namangan…',
                ),
              ),
            ),
            if (towns.isNotEmpty) ...[
              const Gap(),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final town in towns)
                    ChoiceChip(
                      label: Text(town.fullLabel(widget.lang)),
                      selected: town.nameUz == widget.currentLocality,
                      onSelected: (_) => _pickTown(town),
                    ),
                ],
              ),
            ],
            const Gap(),
            for (final district in districts)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                leading: const Icon(Icons.location_on_outlined),
                title: Text(district, style: AppText.body),
                trailing: district == widget.currentDistrict &&
                        (widget.currentLocality == null ||
                            widget.currentLocality == district)
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () => _pickDistrict(district),
              ),
          ],
        ),
      ),
    );
  }
}
