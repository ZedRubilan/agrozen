import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';
import '../../../services/daily_counters.dart';
import '../../../services/notification_service.dart';
import '../../widgets/tactile_button.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  String _lang = 'uz';

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
    });
  }

  Future<void> _acceptAndFinish() async {
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    await prefs.setBool('disclaimer_accepted', true);
    await prefs.setBool('is_onboarded', true);

    // Arm the 07:00 daily plan reminder right here, so a farmer who passed
    // onboarding is covered from the very first morning.
    try {
      final notifications = NotificationService();
      await notifications.initialize();
      final granted = await notifications.requestPermissions();
      if (granted) {
        final lang = prefs.getString('app_language') ?? 'uz';
        await notifications.scheduleDailyMorningNotification(
          title: lang == 'ru' ? 'AgroZen: план на сегодня' : 'AgroZen: bugungi reja',
          body: lang == 'ru'
              ? 'Откройте план дня: температура, корм, вода и задачи для вашей партии.'
              : "Kunlik rejani oching: harorat, yem, suv va partiyangiz vazifalari.",
        );
        await prefs.setBool('daily_reminder_set', true);
      } else {
        await prefs.setBool('daily_reminder_set', false);
      }
    } catch (_) {
      // Reminders are best-effort. Never block onboarding on them.
    }

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isRu = _lang == 'ru';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: Text(
          isRu ? 'Предупреждение' : (_lang == 'en' ? 'Disclaimer' : 'Ogohlantirish'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Progress Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isRu ? 'ШАГ 4 ИЗ 4 • ЗАВЕРШЕНИЕ' : (_lang == 'en' ? 'STEP 4 OF 4 • FINAL' : '4-BOSQICH • YAKUNIY'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withAlpha(40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    size: 44,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isRu
                    ? 'Важное предупреждение'
                    : (_lang == 'en' ? 'Important Disclaimer' : 'Muhim ogohlantirish'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRu
                              ? '1. AgroZen — это справочный ИИ-помощник для начинающих птицеводов, но он НЕ заменяет профессионального ветеринарного врача.\n\n'
                                '2. При любых признаках заболеваний, резком падеже птицы или вялости — незамедлительно свяжитесь с ветеринаром вашего района через кнопку в приложении.\n\n'
                                '3. AgroZen никогда не назначает антибиотики, вакцины и лекарственные препараты самостоятельно. Все лечебные дозировки определяет только специалист.\n\n'
                                '4. Все данные и нормы основаны на стандартах Ross-308 / Cobb-500 и опыте птицеводов Узбекистана.'
                              : (_lang == 'en'
                                  ? '1. AgroZen is an advisory AI assistant for poultry farming, but it DOES NOT replace a licensed veterinary specialist.\n\n'
                                    '2. If you notice signs of disease, sharp mortality spikes, or lethargy — contact your regional veterinarian immediately via the in-app call button.\n\n'
                                    '3. AgroZen never prescribes antibiotics, vaccines, or drug dosages autonomously. All medical treatments must be prescribed by a licensed specialist.\n\n'
                                    '4. All parameters and growth standards are based on Ross-308 / Cobb-500 standards and Uzbekistan poultry experience.'
                                  : "1. AgroZen — parrandachilar uchun ma'lumot beruvchi sun'iy intellekt yordamchisi bo'lib, professional veterinar shifokor o'rnini BOSMAYDI.\n\n"
                                    "2. Har qanday kasallik alomatlari, to'satdan yuz bergan nobodlik yoki lohaslikda — darhol ilovadagi tugma orqali tumaningiz veterinari bilan bog'laning.\n\n"
                                    "3. AgroZen mustaqil ravishda antibiotiklar, vaksinalar yoki dorilarni tayinlamaydi. Barcha davolash me'yorlari faqat mutaxassis tomonidan belgilanadi.\n\n"
                                    "4. Barcha ko'rsatkichlar Ross-308 / Cobb-500 standartlari va O'zbekiston parrandachilik amaliyotiga asoslangan."),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TactileButton(
                height: 56,
                depth: 4,
                borderRadius: 18,
                backgroundColor: theme.colorScheme.primary,
                shadowColor: const Color(0xFF1B5E20),
                onPressed: _acceptAndFinish,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isRu
                          ? 'Я согласен, начать работу'
                          : (_lang == 'en' ? 'I Understand & Agree' : 'Tushundim va roziman'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
