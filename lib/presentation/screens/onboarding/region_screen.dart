import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/location_service.dart';
import '../../ui/components.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 2: where the farm is (for weather and the district vet).
class RegionScreen extends StatefulWidget {
  const RegionScreen({super.key});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  String _selectedDistrict = AppConstants.defaultDistrict;
  String? _autoDetectedDistrict;
  UzbekistanLocality? _selectedLocality;
  String? _gpsStatus;
  bool _gpsFailed = false;
  bool _detecting = false;
  String _query = '';
  String _lang = 'uz';

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      final saved = prefs.getString('farmer_district');
      if (saved != null && AppConstants.districts.contains(saved)) {
        _selectedDistrict = saved;
      }
      _selectedLocality = LocationService.findLocalityByName(
        prefs.getString('farmer_locality'),
      );
    });
  }

  Future<void> _detect() async {
    if (_detecting) return;
    setState(() {
      _detecting = true;
      _gpsStatus = null;
    });
    final result = await LocationService().detectAndSaveLocation();
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _gpsFailed = !result.success;
      if (result.success) {
        _selectedDistrict = result.district;
        _autoDetectedDistrict = result.district;
        _selectedLocality = LocationService.findLocalityByName(result.locality);
        final label = LocationService.formatLocationLabel(
          district: result.district,
          locality: result.locality,
          lang: _lang,
        );
        _gpsStatus = _t(
          'Aniqlandi: $label',
          'Определено: $label',
          'Detected: $label',
        );
      } else {
        _gpsStatus = _t(
          "GPS aniqlanmadi — ro'yxatdan tanlang",
          'GPS не определён — выберите из списка',
          'GPS unavailable — pick from the list',
        );
      }
    });
  }

  Future<void> _proceed() async {
    if (_selectedLocality != null) {
      await LocationService.saveManualLocality(_selectedLocality!);
    } else if (_autoDetectedDistrict != _selectedDistrict) {
      await LocationService.saveManualDistrict(_selectedDistrict);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('farmer_district', _selectedDistrict);
      await prefs.setBool('location_prompt_resolved', true);
    }
    if (!mounted) return;
    context.go('/onboarding/batch');
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final districts = AppConstants.districts
        .where((d) => q.isEmpty || d.toLowerCase().contains(q))
        .toList();
    final towns = q.isEmpty
        ? const <UzbekistanLocality>[]
        : LocationService.uzbekistanLocalities
              .where((l) => l.matchesQuery(_query))
              .take(6)
              .toList();

    return OnboardingScaffold(
      step: 2,
      icon: Icons.location_on_rounded,
      accent: AppColors.primary,
      onBack: () => context.go('/onboarding/language'),
      title: _t('Fermangiz qayerda?', 'Где ваша ферма?', 'Where is your farm?'),
      subtitle: _t(
        "Ob-havo maslahatlari va tuman veterinari shu hududga qarab tanlanadi.",
        'По району подбираются советы по погоде и районный ветеринар.',
        'Weather advice and your district vet are matched to this area.',
      ),
      buttonLabel: AppStrings.next(_lang),
      onNext: _proceed,
      children: [
        AppCard(
          onTap: _detecting ? null : _detect,
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.glow(AppColors.info),
                ),
                child: _detecting
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'GPS orqali aniqlash',
                        'Определить по GPS',
                        'Detect with GPS',
                      ),
                      style: AppText.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _gpsStatus ??
                          _t(
                            "Eng aniq ob-havo uchun",
                            'Для самой точной погоды',
                            'For the most accurate weather',
                          ),
                      style: AppText.caption.copyWith(
                        color: _gpsStatus == null
                            ? AppColors.inkMuted
                            : (_gpsFailed
                                  ? AppColors.warning
                                  : AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
        const Gap(AppSpace.lg),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: _t(
              'Viloyat yoki shahar…',
              'Область или город…',
              'Region or town…',
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
                  label: Text(town.fullLabel(_lang)),
                  selected: _selectedLocality?.nameUz == town.nameUz,
                  onSelected: (_) => setState(() {
                    _selectedLocality = town;
                    _selectedDistrict = town.district;
                  }),
                ),
            ],
          ),
        ],
        const Gap(),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < districts.length; i++) ...[
                if (i > 0) const Divider(indent: AppSpace.lg),
                ListTile(
                  title: Text(districts[i], style: AppText.body),
                  selectedTileColor: AppColors.primarySoft,
                  leading: Icon(
                    districts[i] == _selectedDistrict
                        ? Icons.location_on_rounded
                        : Icons.location_on_outlined,
                  ),
                  trailing: districts[i] == _selectedDistrict
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  selected: districts[i] == _selectedDistrict,
                  onTap: () => setState(() {
                    _selectedDistrict = districts[i];
                    _selectedLocality = null;
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
