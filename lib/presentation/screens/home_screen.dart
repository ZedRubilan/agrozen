import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import 'ask/ask_screen.dart';
import 'course/course_list_screen.dart';
import 'diary/diary_screen.dart';
import 'today_screen.dart';

/// Lets any tab switch to another tab (or open the assistant with a question)
/// without threading callbacks through every widget.
class HomeTabs extends InheritedWidget {
  final ValueChanged<int> select;
  final ValueChanged<String> askAssistant;

  const HomeTabs({
    super.key,
    required this.select,
    required this.askAssistant,
    required super.child,
  });

  static HomeTabs? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeTabs>();

  @override
  bool updateShouldNotify(HomeTabs oldWidget) => false;
}

/// The app's main shell: four labelled tabs — Today, Diary, Assistant, Learn.
class HomeScreen extends StatefulWidget {
  static const int todayTab = 0;
  static const int diaryTab = 1;
  static const int assistantTab = 2;
  static const int learnTab = 3;

  final int initialTab;

  const HomeScreen({super.key, this.initialTab = todayTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _index;
  // Tabs are built the first time they are opened, then kept alive.
  final Set<int> _opened = {};
  String? _assistantPrompt;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 3);
    _opened.add(_index);
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _opened.add(index);
    });
  }

  void _askAssistant(String prompt) {
    setState(() {
      _assistantPrompt = prompt;
      _index = HomeScreen.assistantTab;
      _opened.add(_index);
    });
  }

  Widget _tab(int index) {
    if (!_opened.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case HomeScreen.diaryTab:
        return const SafeArea(
          bottom: false,
          child: DiaryScreen(isEmbeddedInPageView: true),
        );
      case HomeScreen.assistantTab:
        return SafeArea(
          bottom: false,
          child: AskScreen(
            isEmbeddedInPageView: true,
            initialPrompt: _assistantPrompt,
          ),
        );
      case HomeScreen.learnTab:
        return const SafeArea(
          bottom: false,
          child: CourseListScreen(isEmbeddedInPageView: true),
        );
      default:
        return const SafeArea(bottom: false, child: TodayScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    String t(String uz, String ru, String en) =>
        AppStrings.tr(lang: lang, uz: uz, ru: ru, en: en);

    return HomeTabs(
      select: _select,
      askAssistant: _askAssistant,
      child: PopScope(
        canPop: _index == HomeScreen.todayTab,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _select(HomeScreen.todayTab);
        },
        child: Scaffold(
          body: IndexedStack(index: _index, children: List.generate(4, _tab)),
          bottomNavigationBar: _FloatingNavBar(
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              animationDuration: AppMotion.medium,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: t('Bugun', 'Сегодня', 'Today'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.edit_note_outlined),
                  selectedIcon: const Icon(Icons.edit_note_rounded),
                  label: t('Kundalik', 'Дневник', 'Diary'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: const Icon(Icons.chat_bubble_rounded),
                  label: t('Yordamchi', 'Помощник', 'Assistant'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.school_outlined),
                  selectedIcon: const Icon(Icons.school_rounded),
                  label: t("O'rganish", 'Обучение', 'Learn'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded bar that floats above the bottom edge on a soft shadow.
class _FloatingNavBar extends StatelessWidget {
  final Widget child;

  const _FloatingNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
        bottom + AppSpace.md,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.hero),
              boxShadow: AppShadow.raised,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.hero),
              // The bar pads itself for the system inset; we already did.
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
