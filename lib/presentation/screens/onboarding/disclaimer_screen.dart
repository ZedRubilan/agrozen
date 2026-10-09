import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';
import '../../../services/daily_counters.dart';
import '../../../services/notification_service.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    size: 48,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isRu
                    ? 'Важное предупреждение'
                    : (_lang == 'en' ? 'Important Disclaimer' : 'Muhim ogohlantirish'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
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
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _acceptAndFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isRu
                      ? 'Я согласен, начать работу'
                      : (_lang == 'en' ? 'I Understand & Agree' : 'Tushundim va roziman'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
