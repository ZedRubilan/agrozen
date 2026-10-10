import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../app.dart';
import '../../services/daily_counters.dart';
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
  String _district = 'Toshkent';
  int _currentCount = 500;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _name = prefs.getString('farmer_name') ?? 'Fermer';
      _district = prefs.getString('farmer_district') ?? 'Toshkent';
      _currentCount = prefs.getInt('current_count') ?? 500;
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
      await DailyCounters.resetAll(prefs);
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
                    Column(
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
                        ),
                      ],
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
              const SizedBox(height: 16),

                // Language Setting Section
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
                  index: 2,
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

                // About section
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
                          Icon(Icons.eco_rounded, size: 22, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
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
