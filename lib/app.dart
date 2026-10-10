import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/daily_plan_screen.dart';
import 'presentation/screens/onboarding/language_screen.dart';
import 'presentation/screens/onboarding/region_screen.dart';
import 'presentation/screens/onboarding/batch_setup_screen.dart';
import 'presentation/screens/onboarding/disclaimer_screen.dart';
import 'presentation/screens/diary/diary_screen.dart';
import 'presentation/screens/diary/log_mortality_screen.dart';
import 'presentation/screens/diary/log_feed_screen.dart';
import 'presentation/screens/diary/log_weight_screen.dart';
import 'presentation/screens/ask/ask_screen.dart';
import 'presentation/screens/course/course_list_screen.dart';
import 'presentation/screens/course/lesson_screen.dart';
import 'presentation/screens/course/quiz_screen.dart';
import 'presentation/screens/course/certificate_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/widgets/desktop_web_shell.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding/language', builder: (context, state) => const LanguageScreen()),
    GoRoute(path: '/onboarding/region', builder: (context, state) => const RegionScreen()),
    GoRoute(path: '/onboarding/batch', builder: (context, state) => const BatchSetupScreen()),
    GoRoute(path: '/onboarding/disclaimer', builder: (context, state) => const DisclaimerScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/daily-plan', builder: (context, state) => const DailyPlanScreen()),
    GoRoute(path: '/diary', builder: (context, state) => const DiaryScreen()),
    GoRoute(path: '/diary/mortality', builder: (context, state) => const LogMortalityScreen()),
    GoRoute(path: '/diary/feed', builder: (context, state) => const LogFeedScreen()),
    GoRoute(path: '/diary/weight', builder: (context, state) => const LogWeightScreen()),
    GoRoute(
      path: '/ask',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'];
        return AskScreen(startInFieldMode: mode == 'field');
      },
    ),
    GoRoute(path: '/course', builder: (context, state) => const CourseListScreen()),
    GoRoute(
      path: '/course/:lessonId',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['lessonId'] ?? '1') ?? 1;
        return LessonScreen(lessonId: id);
      },
    ),
    GoRoute(
      path: '/course/:lessonId/quiz',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['lessonId'] ?? '1') ?? 1;
        return QuizScreen(lessonId: id);
      },
    ),
    GoRoute(path: '/certificate', builder: (context, state) => const CertificateScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);

class AgroZenApp extends StatefulWidget {
  final String initialLanguage;

  const AgroZenApp({super.key, this.initialLanguage = 'uz'});

  @override
  State<AgroZenApp> createState() => _AgroZenAppState();
}

class _AgroZenAppState extends State<AgroZenApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = _localeFor(widget.initialLanguage);
  }

  static Locale _localeFor(String language) {
    final lang = language.toLowerCase();
    if (lang == 'en') return const Locale('en');
    if (lang == 'ru') return const Locale('ru');
    return const Locale('uz');
  }

  /// Called by the settings screen after the farmer switches language.
  Future<void> setLanguage(String language) async {
    setState(() => _locale = _localeFor(language));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AgroZen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz'),
        Locale('ru'),
        Locale('en'),
      ],
      builder: (context, child) {
        return DesktopWebShell(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Lets any screen switch the app language after the farmer picks a new one in
/// Settings, without threading a callback through every route.
mixin AppLanguageController<T extends StatefulWidget> on State<T> {
  void changeAppLanguage(String language) {
    final appState = context.findAncestorStateOfType<State<AgroZenApp>>();
    if (appState is _AgroZenAppState) {
      appState.setLanguage(language);
    }
  }
}
