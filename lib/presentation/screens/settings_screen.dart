import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../app.dart';
import '../../services/daily_counters.dart';
import '../../services/flock_context_service.dart';
import '../../services/location_service.dart';
import '../widgets/agro_icons.dart';
import '../widgets/language_selector.dart';
import '../widgets/animated_entry.dart';

class SettingsScreen extends StatefulWidget {
  final bool isEmbeddedInPageView;

  const SettingsScreen({
    super.key,
    this.isEmbeddedInPageView = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AppLanguageController<SettingsScreen> {
  String _lang = 'uz';
  String _name = 'Fermer';
  String _district = 'Namangan';
  String? _locality;
  int _currentCount = 500;
  bool _isLoading = true;
  bool _isAutoDetected = false;
  bool _isDetectingGps = false;
  Locale? _observedLocale;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.maybeLocaleOf(context);
    if (_observedLocale != null &&
        currentLocale != null &&
        currentLocale != _observedLocale) {
      _observedLocale = currentLocale;
      _loadState(localeOverride: currentLocale.languageCode);
    } else {
      _observedLocale = currentLocale;
    }
  }

  Future<void> _loadState({String? localeOverride}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? localeOverride ?? 'uz';
      _name = prefs.getString('farmer_name') ?? 'Fermer';
      _district = prefs.getString('farmer_district') ?? 'Namangan';
      _locality = prefs.getString('farmer_locality');
      _currentCount = prefs.getInt('current_count') ?? 500;
      _isAutoDetected = prefs.getBool('location_auto_detected') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _changeLanguage(String newLang) async {
    final normalized = newLang == 'ru' ? 'ru' : (newLang == 'en' ? 'en' : 'uz');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', normalized);
    if (!mounted) return;
    setState(() => _lang = normalized);
    // Rebuild the whole app so every screen (not just Settings) follows.
    changeAppLanguage(normalized);
  }

  Future<void> _changeDistrictManually(String newDistrict) async {
    await LocationService.saveManualDistrict(newDistrict);
    if (!mounted) return;
    setState(() {
      _district = newDistrict;
      _locality = null;
      _isAutoDetected = false;
    });
  }

  Future<void> _changeLocalityManually(UzbekistanLocality locality) async {
    await LocationService.saveManualLocality(locality);
    if (!mounted) return;
    setState(() {
      _district = locality.district;
      _locality = locality.nameUz;
      _isAutoDetected = false;
    });
  }

  Future<void> _detectDistrictWithGps() async {
    if (_isDetectingGps) return;
    setState(() => _isDetectingGps = true);
    final result = await _locationService.detectAndSaveLocation();
    if (!mounted) return;
    setState(() {
      _isDetectingGps = false;
      if (result.success) {
        _district = result.district;
        _locality = result.locality;
        _isAutoDetected = true;
      }
    });
  }

  Future<void> _openRegionPickerModal() async {
    final isRu = _lang == 'ru';
    final isEn = _lang == 'en';
    String searchQuery = '';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E291A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final matchedTowns = searchQuery.trim().isEmpty
                ? <UzbekistanLocality>[
                    LocationService.chartakLocality,
                    ...LocationService.uzbekistanLocalities
                        .where((l) => l.nameUz != 'Chortoq')
                        .take(5),
                  ]
                : LocationService.uzbekistanLocalities
                    .where((l) => l.matchesQuery(searchQuery))
                    .toList();
            final matchedDistricts = AppConstants.districts
                .where(
                  (d) =>
                      searchQuery.trim().isEmpty ||
                      d.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 14,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(60),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isRu
                          ? 'Выберите город или регион фермы'
                          : (isEn
                              ? 'Select Farm Town or Region'
                              : 'Shahar/tuman yoki viloyatni tanlang'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (val) =>
                          setModalState(() => searchQuery = val),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: isRu
                            ? 'Поиск (напр. Чартак, Наманган)...'
                            : (isEn
                                ? 'Search (e.g. Chartak, Namangan)...'
                                : 'Qidirish (masalan: Chortoq, Chartak)...'),
                        hintStyle: TextStyle(
                          color: Colors.white.withAlpha(130),
                          fontSize: 12.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6EE7B7),
                          size: 18,
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha(18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(35),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(35),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final town in matchedTowns.take(6))
                          ActionChip(
                            backgroundColor: _locality == town.nameUz
                                ? const Color(0xFF10B981)
                                : Colors.white.withAlpha(18),
                            side: BorderSide(
                              color: _locality == town.nameUz
                                  ? const Color(0xFF6EE7B7)
                                  : Colors.white.withAlpha(35),
                            ),
                            label: Text(
                              town.fullLabel(_lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _changeLocalityManually(town);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: matchedDistricts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, idx) {
                            final item = matchedDistricts[idx];
                            final isSelected =
                                item == _district && _locality == null;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  await _changeDistrictManually(item);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF34D399).withAlpha(45)
                                        : Colors.white.withAlpha(12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF34D399)
                                          : Colors.white.withAlpha(24),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: isSelected
                                            ? const Color(0xFF6EE7B7)
                                            : Colors.white.withAlpha(170),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: Color(0xFF6EE7B7),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _resetBatch() async {
    final isRu = _lang == 'ru';
    final isEn = _lang == 'en';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRu
            ? 'Начать новую партию?'
            : (isEn ? 'Start New Flock?' : 'Yangi partiya boshlash?')),
        content: Text(
          isRu
              ? 'Все текущие данные будут сброшены для запуска нового 42-дневного цикла.'
              : (isEn
                  ? 'All current cycle metrics will be reset to begin a new 42-day flock.'
                  : "Yangi 42 kunlik sikl boshlash uchun joriy ma'lumotlar qayta sozlanadi."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isRu ? 'Отмена' : (isEn ? 'Cancel' : 'Bekor qilish')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(isRu ? 'Да, начать' : (isEn ? 'Yes, Reset' : 'Ha, boshlash')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('arrival_date');
      await prefs.remove('last_weight');
      await DailyCounters.resetAll(prefs);
      FlockContextService().clearHistory();
      if (!mounted) return;
      context.go('/onboarding/batch');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRu = _lang == 'ru';
    final isEn = _lang == 'en';

    final birdsSuffix = isRu ? 'голов' : (isEn ? 'birds' : 'bosh');

    final bodyContent = _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          )
        : ListView(
            padding: EdgeInsets.only(
              left: 18.0,
              right: 18.0,
              top: widget.isEmbeddedInPageView ? 8.0 : 16.0,
              bottom: widget.isEmbeddedInPageView ? 110.0 : 30.0,
            ),
            children: [
              if (widget.isEmbeddedInPageView) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRu ? 'Настройки' : (isEn ? 'Settings' : 'Sozlamalar'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isRu
                                ? 'Профиль и параметры фермы'
                                : (isEn ? 'Farm profile and preferences' : 'Ferma profili va sozlamalar'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Profile Section with real Photo Avatar
              StaggeredSlideFade(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF22C55E), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withAlpha(50),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Image.asset(
                                'assets/images/farmer_avatar.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5ED),
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Text(
                                '$_district | $_currentCount $birdsSuffix',
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Farm Location & Geolocation Settings Card
              StaggeredSlideFade(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D7A4C).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1B5E20),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRu
                                      ? 'Локация фермы и погода'
                                      : (isEn ? 'Farm Location & Weather' : 'Ferma joylashuvi va ob-havo'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: Color(0xFF1B2A1E),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  _isAutoDetected
                                      ? (isRu
                                          ? 'Автоопределено по GPS: ${LocationService.formatLocationLabel(district: _district, locality: _locality, lang: _lang)}'
                                          : (isEn
                                              ? 'Auto-detected via GPS: ${LocationService.formatLocationLabel(district: _district, locality: _locality, lang: _lang)}'
                                              : 'GPS orqali aniqlangan: ${LocationService.formatLocationLabel(district: _district, locality: _locality, lang: _lang)}'))
                                      : (isRu
                                          ? 'Текущий регион: ${LocationService.formatLocationLabel(district: _district, locality: _locality, lang: _lang)}'
                                          : (isEn
                                              ? 'Current region: ${LocationService.formatLocationLabel(district: _district, locality: _locality, lang: _lang)}'
                                              : 'Joriy hudud: ${LocationService.formatLocationLabel(district: _district, locality: _locality, lang: _lang)}')),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openRegionPickerModal,
                              icon: const Icon(Icons.edit_location_alt_rounded, size: 17),
                              label: Text(
                                isRu
                                    ? 'Сменить регион'
                                    : (isEn ? 'Change Region' : 'Hududni tanlash'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B5E20),
                                side: const BorderSide(color: Color(0xFF2D7A4C), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _detectDistrictWithGps,
                              icon: _isDetectingGps
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded, size: 17),
                              label: Text(
                                isRu ? 'GPS Авто' : (isEn ? 'Auto GPS' : 'GPS orqali'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Language Setting Section
              StaggeredSlideFade(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D7A4C).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.language_rounded, color: Color(0xFF1B5E20), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isRu ? 'Язык приложения' : (isEn ? 'App Language' : 'Ilova tili'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: Color(0xFF1B2A1E),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: LanguageSelector(
                          currentLanguage: _lang,
                          onLanguageChanged: _changeLanguage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Reset batch
              StaggeredSlideFade(
                index: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.orange.withAlpha(70), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withAlpha(10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restart_alt_rounded, color: Color(0xFFE65100), size: 22),
                      ),
                      title: Text(
                        isRu ? 'Начать новую партию' : (isEn ? 'Start New Flock' : 'Yangi partiya boshlash'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1B2A1E)),
                      ),
                      subtitle: Text(
                        isRu
                            ? 'Сбросить дату завоза и счетчики'
                            : (isEn ? 'Reset chick arrival date and counters' : "Keltirilgan sana va hisoblagichlarni yangilash"),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      onTap: _resetBatch,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // About section with rounded photographic AgroZen logo
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AgroChickIcon(size: 32),
                        const SizedBox(width: 10),
                        const Text('AgroZen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isRu
                          ? 'Разработано специально для птицеводов Узбекистана к StudEXPO-2026: ИИ-консультации, журнал партии, нормы Ross-308 и связь с ветеринарами.'
                          : (isEn
                              ? 'Built for poultry farmers in Uzbekistan for StudEXPO-2026: AI advising, flock diary, Ross-308 standards, and regional vet access.'
                              : "O'zbekiston parrandachilari uchun StudEXPO-2026 tanloviga maxsus ishlab chiqilgan sun'iy intellekt yordamchisi: Ross-308 me'yorlari, kredit tahlili va veterinar aloqasi."),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          );

    if (widget.isEmbeddedInPageView) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(isRu ? 'Настройки' : (isEn ? 'Settings' : 'Sozlamalar')),
      ),
      body: bodyContent,
    );
  }
}
