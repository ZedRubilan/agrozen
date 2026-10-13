import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';
import '../../../services/daily_counters.dart';
import '../../../services/notification_service.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../ui/components.dart';
import 'onboarding_scaffold.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  String _lang = 'uz';
  bool _finishing = false;

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

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
    if (_finishing) return;
    setState(() => _finishing = true);
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
        final notifTitle = lang == 'en'
            ? 'AgroZen: Today\'s Plan'
            : (lang == 'ru'
                  ? 'AgroZen: план на сегодня'
                  : 'AgroZen: bugungi reja');
        final notifBody = lang == 'en'
            ? 'Open your daily broiler plan: target temperature, feed norms, and flock tasks.'
            : (lang == 'ru'
                  ? 'Откройте план дня: температура, корм, вода и задачи для вашей партии.'
                  : "Kunlik rejani oching: harorat, yem, suv va partiyangiz vazifalari.");

        await notifications.scheduleDailyMorningNotification(
          title: notifTitle,
          body: notifBody,
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
    final points = <(IconData, Tone, String)>[
      (
        Icons.support_agent_rounded,
        Tone.info,
        _t(
          "AgroZen — maslahat beruvchi yordamchi. U veterinar shifokor o'rnini bosmaydi.",
          'AgroZen — помощник-консультант. Он не заменяет ветеринарного врача.',
          'AgroZen is an advisory assistant. It does not replace a veterinarian.',
        ),
      ),
      (
        Icons.local_hospital_rounded,
        Tone.danger,
        _t(
          "Kasallik belgilari, to'satdan nobudlik yoki lohaslik bo'lsa — darhol tuman veterinariga qo'ng'iroq qiling (ilovada tugma bor).",
          'При признаках болезни, резком падеже или вялости птицы — сразу звоните районному ветеринару (кнопка есть в приложении).',
          'If you see signs of disease, sudden deaths or weak birds, call your district vet right away (there is a button in the app).',
        ),
      ),
      (
        Icons.medication_rounded,
        Tone.warning,
        _t(
          "AgroZen antibiotik, vaksina yoki dori dozalarini tayinlamaydi. Davolashni faqat mutaxassis belgilaydi.",
          'AgroZen не назначает антибиотики, вакцины и дозировки лекарств. Лечение назначает только специалист.',
          'AgroZen never prescribes antibiotics, vaccines or drug doses. Only a specialist prescribes treatment.',
        ),
      ),
      (
        Icons.verified_rounded,
        Tone.primary,
        _t(
          "Barcha me'yorlar Ross-308 / Cobb-500 standartlari va O'zbekiston tajribasiga asoslangan.",
          'Все нормы основаны на стандартах Ross-308 / Cobb-500 и опыте птицеводов Узбекистана.',
          'All targets are based on Ross-308 / Cobb-500 standards and Uzbek farming practice.',
        ),
      ),
    ];

    return OnboardingScaffold(
      step: 4,
      icon: Icons.verified_user_rounded,
      accent: AppColors.info,
      onBack: () => context.go('/onboarding/batch'),
      title: _t(
        'Muhim ogohlantirish',
        'Важное предупреждение',
        'Important notice',
      ),
      subtitle: _t(
        'Boshlashdan oldin o\'qib chiqing.',
        'Прочитайте перед началом.',
        'Please read before you start.',
      ),
      buttonLabel: _t(
        'Tushundim va roziman',
        'Понимаю и согласен(на)',
        'I understand and agree',
      ),
      busy: _finishing,
      onNext: _acceptAndFinish,
      children: [
        for (var i = 0; i < points.length; i++) ...[
          if (i > 0) const Gap(),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: points[i].$2.solid,
                    shape: BoxShape.circle,
                    boxShadow: AppShadow.glow(points[i].$2.solid),
                  ),
                  child: Icon(points[i].$1, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(points[i].$3, style: AppText.body)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
