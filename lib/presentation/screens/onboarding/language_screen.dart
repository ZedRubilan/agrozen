import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../widgets/agro_icons.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 1: welcome and language.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with AppLanguageController {
  String _selected = 'uz';

  static const _languages = [
    ('uz', "O'zbekcha", 'Uzbek'),
    ('ru', 'Русский', 'Russian'),
    ('en', 'English', 'English'),
  ];

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selected);
    if (!mounted) return;
    changeAppLanguage(_selected);
    context.go('/onboarding/region');
  }

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        AppStrings.tr(lang: _selected, uz: uz, ru: ru, en: en);

    return OnboardingScaffold(
      step: 1,
      header: _WelcomeHero(
        tagline: t(
          "Broyler parvarishi uchun kundalik yordamchi",
          'Ежедневный помощник для выращивания бройлеров',
          'Your daily helper for raising broilers',
        ),
      ),
      title: "Tilni tanlang\nВыберите язык\nSelect Language",
      buttonLabel: AppStrings.proceed(_selected),
      onNext: _proceed,
      children: [
        for (final lang in _languages) ...[
          OptionCard(
            leading: AgroFlagBadge(code: lang.$1, size: 34),
            title: lang.$2,
            selected: _selected == lang.$1,
            onTap: () => setState(() => _selected = lang.$1),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  final String tagline;

  const _WelcomeHero({required this.tagline});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // One gentle zoom-out when the app first opens.
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                    ? 1
                    : 1.15,
                end: 1,
              ),
              duration: const Duration(milliseconds: 1800),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Image.asset(
                'assets/images/sunset_farm.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: AppColors.primaryDark),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: AppSpace.lg,
              right: AppSpace.lg,
              bottom: AppSpace.lg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AgroChickIcon(size: 48),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AgroZen',
                          style: AppText.screenTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: AppMotion.medium,
                          child: Text(
                            tagline,
                            key: ValueKey(tagline),
                            style: AppText.bodyMuted.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
