import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrozen/config/theme.dart';
import 'package:agrozen/core/localization/app_strings.dart';
import 'package:agrozen/domain/alerts/alert_engine.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';
import 'package:agrozen/presentation/widgets/animated_entry.dart';
import 'package:agrozen/services/daily_counters.dart';

/// Redesigned Flock Diary Screen:
/// Matches the main screen's ultra-rounded, photographic, minimal-click aesthetic.
class DiaryScreen extends StatefulWidget {
  final bool isEmbeddedInPageView;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const DiaryScreen({
    super.key,
    this.isEmbeddedInPageView = false,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  String _lang = 'uz';
  Locale? _observedLocale;
  int _initialCount = 500;
  int _currentCount = 495;
  int _batchDay = 1;
  int _todayMortality = 0;
  double _todayFeed = 0.0;
  double _lastWeight = 0.0;
  List<AlertResult> _alerts = [];
  Map<String, dynamic>? _vet;
  bool _isLoading = true;

  final KnowledgeRepository _knowledgeRepo = KnowledgeRepository();

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.maybeLocaleOf(context);
    if (_observedLocale != null && currentLocale != _observedLocale) {
      _observedLocale = currentLocale;
      _loadDiary(localeOverride: currentLocale?.languageCode);
    } else {
      _observedLocale = currentLocale;
      _checkLanguageChange();
    }
  }

  Future<void> _checkLanguageChange() async {
    final prefs = await DailyCounters.rolled();
    final savedLang = prefs.getString('app_language') ?? 'uz';
    if (savedLang != _lang && mounted) {
      _loadDiary();
    }
  }

  Future<void> _loadDiary({String? localeOverride}) async {
    setState(() => _isLoading = true);
    final prefs = await DailyCounters.rolled();
    _lang = prefs.getString('app_language') ?? localeOverride ?? 'uz';
    _initialCount = prefs.getInt('initial_count') ?? 500;
    _currentCount = prefs.getInt('current_count') ?? _initialCount;
    _todayMortality = DailyCounters.getMortality(prefs);
    _todayFeed = DailyCounters.getFeed(prefs);
    _lastWeight = prefs.getDouble('last_weight') ?? 0.0;

    final arrivalStr = prefs.getString('arrival_date');
    if (arrivalStr != null) {
      final parsed = DateTime.tryParse(arrivalStr);
      if (parsed != null) {
        final diff = DateTime.now().difference(parsed).inDays + 1;
        _batchDay = diff.clamp(1, 42);
      }
    }

    final district = prefs.getString('farmer_district') ?? 'Toshkent';
    final vets = await _knowledgeRepo.getVetByDistrict(district);
    if (vets.isNotEmpty) {
      _vet = vets.first;
    }

    final norms = await _knowledgeRepo.getParsedNorms();
    final engine = AlertEngine(norms);
    final triggered = <AlertResult>[];

    if (_todayMortality > 0) {
      final mortalityAlert = engine.checkMortality(
        deaths: _todayMortality,
        currentCount: _currentCount + _todayMortality,
      );
      if (mortalityAlert != null) {
        triggered.add(mortalityAlert);
      }
    }

    if (_lastWeight > 0) {
      final weightAlert = engine.checkWeight(
        weightGrams: _lastWeight,
        batchDay: _batchDay,
      );
      if (weightAlert != null) {
        triggered.add(weightAlert);
      }
    }

    _alerts = triggered;

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          )
        : RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: _loadDiary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 18.0,
                right: 18.0,
                top: widget.isEmbeddedInPageView ? 8.0 : 16.0,
                bottom: widget.isEmbeddedInPageView ? 110.0 : 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Title & Subtitle
                  StaggeredSlideFade(
                    index: 0,
                    child: _buildHeaderRow(context),
                  ),
                  const SizedBox(height: 14),

                  // 1. Cinematic Photographic Flock Health Card
                  StaggeredSlideFade(
                    index: 1,
                    child: _buildCinematicFlockHeroCard(),
                  ),
                  const SizedBox(height: 18),

                  // Active Alerts if any
                  if (_alerts.isNotEmpty) ...[
                    for (final alert in _alerts) ...[
                      StaggeredSlideFade(
                        index: 2,
                        child: AlertCard.fromAlertResult(
                          alert: alert,
                          locale: _lang,
                          vetName: _vet?['name'] as String?,
                          vetPhone: _vet?['phone'] as String?,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // 2. Log Action Cards (Yangi yozuv kiritish)
                  StaggeredSlideFade(
                    index: 2,
                    child: Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: 'Yangi yozuv kiritish',
                        ru: 'Новая запись',
                        en: 'Log New Entry',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  StaggeredSlideFade(
                    index: 3,
                    child: _buildLogCard(
                      imageAsset: 'assets/images/chick_starter.jpg',
                      icon: Icons.heart_broken_rounded,
                      accentColor: const Color(0xFFDC2626),
                      title: AppStrings.tr(
                        lang: _lang,
                        uz: 'Nobodlik yozish',
                        ru: 'Записать падёж',
                        en: 'Log Mortality',
                      ),
                      subtitle: AppStrings.tr(
                        lang: _lang,
                        uz: 'Bugun nobud bo\'lgan parrandalar soni',
                        ru: 'Укажите количество погибших птиц за сутки',
                        en: 'Daily mortality count',
                      ),
                      onTap: () async {
                        await context.push('/diary/mortality');
                        _loadDiary();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  StaggeredSlideFade(
                    index: 4,
                    child: _buildLogCard(
                      imageAsset: 'assets/images/feed_grain.jpg',
                      icon: Icons.grain_rounded,
                      accentColor: const Color(0xFFD97706),
                      title: AppStrings.tr(
                        lang: _lang,
                        uz: 'Yem sarfini yozish',
                        ru: 'Записать расход корма',
                        en: 'Log Feed Intake',
                      ),
                      subtitle: AppStrings.tr(
                        lang: _lang,
                        uz: 'Bugun berilgan yem miqdori (kg)',
                        ru: 'Укажите израсходованный комбикорм (кг)',
                        en: 'Daily feed consumption in kg',
                      ),
                      onTap: () async {
                        await context.push('/diary/feed');
                        _loadDiary();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  StaggeredSlideFade(
                    index: 5,
                    child: _buildLogCard(
                      imageAsset: 'assets/images/tractor_hero.jpg',
                      icon: Icons.scale_rounded,
                      accentColor: const Color(0xFF0D9488),
                      title: AppStrings.tr(
                        lang: _lang,
                        uz: 'Nazorat vaznini yozish',
                        ru: 'Записать контрольный вес',
                        en: 'Log Sample Weight',
                      ),
                      subtitle: AppStrings.tr(
                        lang: _lang,
                        uz: 'Parrandaning o\'rtacha vazni (gramm)',
                        ru: 'Средний вес одной птицы при взвешивании (грамм)',
                        en: 'Sample bird average weight in grams',
                      ),
                      onTap: () async {
                        await context.push('/diary/weight');
                        _loadDiary();
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 3. Today's Summary (Bugungi qaydlar)
                  StaggeredSlideFade(
                    index: 6,
                    child: Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: 'Bugungi qaydlar',
                        ru: 'Сегодняшние показатели',
                        en: "Today's Summary",
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  StaggeredSlideFade(
                    index: 7,
                    child: _buildTodaySummaryCard(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );

    if (widget.isEmbeddedInPageView) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: bodyContent,
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(
                  lang: _lang,
                  uz: 'Partiya kundaligi',
                  ru: 'Дневник партии',
                  en: 'Flock Diary',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.tr(
                  lang: _lang,
                  uz: "Kunlik sarf, nobodlik va vazn nazorati",
                  ru: "Ежедневный учёт корма, падежа и веса",
                  en: "Daily mortality, feed and weight records",
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!widget.isEmbeddedInPageView && Navigator.canPop(context))
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
      ],
    );
  }

  /// Photographic Hero Status Card for the Flock
  Widget _buildCinematicFlockHeroCard() {
    final gramUnit = _lang == 'en' ? 'g' : 'г';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Stack(
          children: [
            // Background Broiler Photography
            Positioned.fill(
              child: Image.asset(
                'assets/images/broiler_flock.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.primaryGreenDark,
                ),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(150),
                      Colors.black.withAlpha(80),
                      Colors.black.withAlpha(190),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Metrics overlay
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: Colors.white.withAlpha(60), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              AppStrings.tr(lang: _lang, uz: 'FAOL PODA', ru: 'АКТИВНАЯ СТАЯ', en: 'ACTIVE FLOCK'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: "Boshlang'ich: $_initialCount",
                              ru: 'Начальное: $_initialCount',
                              en: 'Initial: $_initialCount',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 3 Key Metrics Row (Tirik, Nobodlik, O'rtacha vazn)
                  Row(
                    children: [
                      Expanded(
                        child: _buildFlockHeroMetric(
                          label: AppStrings.tr(lang: _lang, uz: 'Tirik', ru: 'Живых', en: 'Alive'),
                          value: '$_currentCount',
                          color: const Color(0xFF4ADE80),
                          icon: Icons.pets_rounded,
                        ),
                      ),
                      Container(width: 1, height: 38, color: Colors.white.withAlpha(50)),
                      Expanded(
                        child: _buildFlockHeroMetric(
                          label: AppStrings.tr(lang: _lang, uz: 'Nobodlik', ru: 'Падёж', en: 'Mortality'),
                          value: '$_todayMortality',
                          color: _todayMortality > 0 ? const Color(0xFFF87171) : Colors.white,
                          icon: Icons.remove_circle_outline_rounded,
                        ),
                      ),
                      Container(width: 1, height: 38, color: Colors.white.withAlpha(50)),
                      Expanded(
                        child: _buildFlockHeroMetric(
                          label: AppStrings.tr(lang: _lang, uz: "O'rtacha vazn", ru: 'Вес (ср.)', en: 'Avg Weight'),
                          value: _lastWeight > 0 ? '${_lastWeight.toInt()} $gramUnit' : '-',
                          color: Colors.white,
                          icon: Icons.scale_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlockHeroMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.white.withAlpha(200),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard({
    required String imageAsset,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return TactileCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.cardBorder, width: 0.8),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.asset(
                imageAsset,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove_circle_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            title: Text(
              AppStrings.tr(
                lang: _lang,
                uz: 'Sutkalik nobodlik',
                ru: 'Падёж за сутки',
                en: 'Daily Mortality',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                '$_todayMortality ${AppStrings.tr(lang: _lang, uz: 'bosh', ru: 'голов', en: 'birds')}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626), fontSize: 13),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEDF2EE)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.grain_rounded, color: Color(0xFFD97706), size: 20),
            ),
            title: Text(
              AppStrings.tr(
                lang: _lang,
                uz: 'Sutkalik yem',
                ru: 'Корм за сутки',
                en: 'Daily Feed',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                '${_todayFeed.toStringAsFixed(1)} kg',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB45309), fontSize: 13),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEDF2EE)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.scale_rounded, color: Color(0xFF0D9488), size: 20),
            ),
            title: Text(
              AppStrings.tr(
                lang: _lang,
                uz: "So'nggi o'lchangan vazn",
                ru: 'Последний замер веса',
                en: 'Latest Sample Weight',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                _lastWeight > 0 ? '${_lastWeight.toStringAsFixed(0)} ${_lang == 'en' ? 'g' : 'г'}' : '-',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
