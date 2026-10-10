import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/data/models/daily_plan.dart';
import 'package:agrozen/data/models/diary_entry.dart';
import 'package:agrozen/data/repositories/course_repository.dart';
import 'package:agrozen/data/repositories/diary_repository.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:agrozen/presentation/blocs/ask/ask_bloc.dart';
import 'package:agrozen/presentation/blocs/ask/ask_event.dart';
import 'package:agrozen/presentation/blocs/ask/ask_state.dart';
import 'package:agrozen/presentation/blocs/course/course_bloc.dart';
import 'package:agrozen/presentation/blocs/course/course_event.dart';
import 'package:agrozen/presentation/blocs/course/course_state.dart';
import 'package:agrozen/presentation/blocs/daily_plan/daily_plan_bloc.dart';
import 'package:agrozen/presentation/blocs/daily_plan/daily_plan_event.dart';
import 'package:agrozen/presentation/blocs/daily_plan/daily_plan_state.dart';
import 'package:agrozen/presentation/blocs/diary/diary_bloc.dart';
import 'package:agrozen/presentation/blocs/diary/diary_event.dart';
import 'package:agrozen/presentation/blocs/diary/diary_state.dart';
import 'package:agrozen/presentation/blocs/home/home_bloc.dart';
import 'package:agrozen/presentation/blocs/home/home_event.dart';
import 'package:agrozen/presentation/blocs/home/home_state.dart';
import 'package:agrozen/presentation/blocs/onboarding/onboarding_bloc.dart';
import 'package:agrozen/presentation/blocs/onboarding/onboarding_event.dart';
import 'package:agrozen/presentation/blocs/onboarding/onboarding_state.dart';
import 'package:agrozen/services/daily_counters.dart';
import 'package:agrozen/services/voice_service.dart';

class _MockVoiceService extends Mock implements VoiceService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    KnowledgeRepository.clearCache();
  });

  group('1. HomeBloc Tests', () {
    test('LoadHomeData emits HomeLoading -> HomeLoaded with batch day, survival metrics, daily plan, and alerts', () async {
      final arrivalDate = DateTime.now().subtract(const Duration(days: 13)); // Day 14
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'farmer_name': 'Sardor Fermer',
        'farmer_district': 'Samarqand',
        'app_language': 'uz',
        'initial_count': 500,
        'current_count': 485,
        'today_mortality': 12, // > 1% of 485 -> triggers mortality alert
        'last_weight': 350.0, // Day 14 norm is 510g -> triggers underweight alert
        'arrival_date': arrivalDate.toIso8601String(),
      });

      final bloc = HomeBloc();
      final states = <HomeState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const LoadHomeData());
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(states.length, 2);
      expect(states[0], isA<HomeLoading>());
      expect(states[1], isA<HomeLoaded>());

      final loaded = states[1] as HomeLoaded;
      expect(loaded.batchDay, 14);
      expect(loaded.farmer.name, 'Sardor Fermer');
      expect(loaded.farmer.district, 'Samarqand');
      expect(loaded.activeBatch.initialCount, 500);
      expect(loaded.activeBatch.currentCount, 485);
      expect(loaded.todayPlan, isNotNull);
      expect(loaded.todayPlan.day, 14);
      expect(loaded.alerts, isNotEmpty);

      await sub.cancel();
      await bloc.close();
    });

    test('RefreshHomeData emits updated HomeLoaded without HomeLoading', () async {
      final arrivalDate = DateTime.now().subtract(const Duration(days: 6)); // Day 7
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'farmer_name': 'Jasur',
        'farmer_district': 'Toshkent',
        'app_language': 'ru',
        'initial_count': 1000,
        'current_count': 998,
        'today_mortality': 1,
        'arrival_date': arrivalDate.toIso8601String(),
      });

      final bloc = HomeBloc();
      final states = <HomeState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const RefreshHomeData());
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(states.length, 1);
      expect(states[0], isA<HomeLoaded>());
      final loaded = states[0] as HomeLoaded;
      expect(loaded.batchDay, 7);
      expect(loaded.activeBatch.currentCount, 998);
      expect(loaded.alerts, isEmpty);

      // Verify Equatable props on HomeEvent & HomeState
      expect(const LoadHomeData().props, isEmpty);
      expect(const RefreshHomeData().props, isEmpty);
      expect(const HomeError('err').props, ['err']);
      expect(loaded.props.length, 6);

      await sub.cancel();
      await bloc.close();
    });
  });

  group('2. DiaryBloc Tests', () {
    test('AddMortalityEntry, AddFeedEntry, AddWeightEntry update SharedPreferences and LoadDiaryEntries emits DiaryLoaded with entries and alerts', () async {
      final arrivalDate = DateTime.now().subtract(const Duration(days: 13)); // Day 14 (target 510g)
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'initial_count': 500,
        'current_count': 500,
        'today_mortality': 0,
        'today_feed': 0.0,
        'arrival_date': arrivalDate.toIso8601String(),
      });

      final bloc = DiaryBloc(diaryRepository: DiaryRepository());
      final states = <DiaryState>[];
      final sub = bloc.stream.listen(states.add);

      // 1. Add Mortality (10 deaths out of 500 = 2.0% > 1.0% threshold)
      bloc.add(const AddMortalityEntry(10, 'Issiqlik tufayli'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('current_count'), 490);
      expect(prefs.getInt('today_mortality'), 10);
      expect(states.last, isA<DiarySuccess>());
      expect((states.last as DiarySuccess).alertResult, isNotNull);

      // 2. Add Feed (42.5 kg)
      bloc.add(const AddFeedEntry(42.5, 'Grower yem'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(prefs.getDouble('today_feed'), 42.5);
      expect(states.last, isA<DiarySuccess>());

      // 3. Add Weight (360g on Day 14 -> underweight alert vs 510g norm)
      bloc.add(const AddWeightEntry(360.0, 'Nazorat tarozi'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(prefs.getDouble('last_weight'), 360.0);
      expect(states.last, isA<DiarySuccess>());
      expect((states.last as DiarySuccess).alertResult, isNotNull);

      // 4. LoadDiaryEntries emits DiaryLoading -> DiaryLoaded with 3 entries and active alerts
      states.clear();
      bloc.add(const LoadDiaryEntries());
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(states.first, isA<DiaryLoading>());
      expect(states.last, isA<DiaryLoaded>());
      final loaded = states.last as DiaryLoaded;
      expect(loaded.entries.length, 3);
      expect(loaded.activeAlerts.length, greaterThanOrEqualTo(2));

      await sub.cancel();
      await bloc.close();
    });

    test('DiaryLoaded Equatable props distinguish different entry and alert lists', () {
      final now = DateTime(2026, 10, 10);
      final entry1 = DiaryEntry(
        id: '1',
        batchId: 'b1',
        entryDate: now,
        entryType: 'mortality',
        value: 2,
        createdAt: now,
      );
      final entry2 = DiaryEntry(
        id: '2',
        batchId: 'b1',
        entryDate: now,
        entryType: 'feed',
        value: 25.0,
        createdAt: now,
      );
      const alert1 = AlertResult(
        type: AlertType.highMortality,
        severity: AlertSeverity.critical,
        actualValue: 2.5,
        threshold: 1.0,
        messageRu: 'Падёж',
        messageUz: 'Nobodlik',
        messageEn: 'Mortality',
      );

      final stateA = DiaryLoaded([entry1], const []);
      final stateB = DiaryLoaded([entry1], const []);
      final stateC = DiaryLoaded([entry2], const []);
      final stateD = DiaryLoaded([entry1], const [alert1]);

      expect(stateA, equals(stateB));
      expect(stateA, isNot(equals(stateC)));
      expect(stateA, isNot(equals(stateD)));
      expect(stateA.props, [
        [entry1],
        const <dynamic>[],
      ]);

      // Verify event props as well
      expect(const AddMortalityEntry(5, 'note').props, [5, 'note']);
      expect(const AddFeedEntry(12.5, 'feed').props, [12.5, 'feed']);
      expect(const AddWeightEntry(450.0, 'w').props, [450.0, 'w']);
    });
  });

  group('3. DailyPlanBloc Tests', () {
    test('LoadDailyPlan emits DailyPlanLoaded for days 1, 14, and 42 and verifies Equatable props', () async {
      final bloc = DailyPlanBloc();
      final states = <DailyPlanState>[];
      final sub = bloc.stream.listen(states.add);

      for (final targetDay in [1, 14, 42]) {
        states.clear();
        bloc.add(LoadDailyPlan(targetDay));
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(states.first, isA<DailyPlanLoading>());
        expect(states.last, isA<DailyPlanLoaded>());
        final loaded = states.last as DailyPlanLoaded;
        expect(loaded.dayNumber, targetDay);
        expect((loaded.currentDayPlan as DailyPlan).day, targetDay);
        expect((loaded.allPlans as List).length, 42);
      }

      // Verify Equatable props on DailyPlanLoaded and LoadDailyPlan
      const plan1 = DailyPlan(day: 1, tasksRu: 'День 1', tasksUz: '1-kun');
      const plan14 = DailyPlan(day: 14, tasksRu: 'День 14', tasksUz: '14-kun');
      const state1 = DailyPlanLoaded(plan1, [plan1, plan14], 1);
      const state1Copy = DailyPlanLoaded(plan1, [plan1, plan14], 1);
      const state14 = DailyPlanLoaded(plan14, [plan1, plan14], 14);

      expect(state1, equals(state1Copy));
      expect(state1, isNot(equals(state14)));
      expect(const LoadDailyPlan(14).props, [14]);
      expect(const LoadAllPlans().props, isEmpty);

      await sub.cancel();
      await bloc.close();
    });
  });

  group('4. AskBloc Tests', () {
    test('SendQuestion emits user/assistant messages, decrements quota, and blocks medicine queries with safety refusal', () async {
      SharedPreferences.setMockInitialValues({
        'counters_date': DailyCounters.todayStamp(),
        'app_language': 'uz',
        'remaining_questions': 30,
      });

      final bloc = AskBloc(voiceService: _MockVoiceService());
      final states = <AskState>[];
      final sub = bloc.stream.listen(states.add);

      // Load initial chat history
      bloc.add(const LoadChatHistory());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(states.last, isA<AskLoaded>());
      expect((states.last as AskLoaded).remainingQuestionsToday, 30);

      // 1. Standard husbandry question
      states.clear();
      bloc.add(const SendQuestion("Jo'jalarga qanday harorat kerak?"));
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(states.first, isA<AskLoading>());
      expect(states.last, isA<AskLoaded>());
      final afterFirst = states.last as AskLoaded;
      expect(afterFirst.remainingQuestionsToday, 29);
      expect(afterFirst.messages.length, 2);
      expect(afterFirst.messages[0]['role'], 'user');
      expect(afterFirst.messages[1]['role'], 'assistant');

      // 2. Medical/antibiotic query -> blocked with deterministic safety refusal
      states.clear();
      bloc.add(const SendQuestion('Qanday antibiotik va dori berish kerak?'));
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final afterSecond = states.last as AskLoaded;
      expect(afterSecond.remainingQuestionsToday, 28);
      expect(afterSecond.messages.length, 4);
      expect(
        afterSecond.messages.last['text'].toString(),
        contains('AgroZen mustaqil ravishda dori yoki antibiotik belgilamaydi'),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('remaining_questions'), 28);

      await sub.cancel();
      await bloc.close();
    });
  });

  group('5. CourseBloc Tests', () {
    test('LoadCourse and SubmitQuiz update completed lessons and unlock certificate when all 5 lessons are completed', () async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'uz',
        'farmer_id': 'farmer_test_1',
        'completed_lessons': <String>[],
      });

      final courseRepo = CourseRepository();
      final bloc = CourseBloc(courseRepository: courseRepo);
      final states = <CourseState>[];
      final sub = bloc.stream.listen(states.add);

      // Load course
      bloc.add(const LoadCourse());
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(states.first, isA<CourseLoading>());
      expect(states.last, isA<CourseLoaded>());
      final loaded = states.last as CourseLoaded;
      expect(loaded.lessons.length, 5);
      expect(loaded.progressList, isEmpty);

      // Select and complete all 5 lessons with their correct answers
      for (int lessonNum = 1; lessonNum <= 5; lessonNum++) {
        states.clear();
        bloc.add(SelectLesson(lessonNum));
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(states.last, isA<LessonViewing>());

        final quiz = await courseRepo.getQuizForLesson(lessonNum, 'uz');
        final correctIdx = quiz?.correctOptionIndex ?? 0;
        states.clear();
        bloc.add(SubmitQuiz(lessonNum, [correctIdx]));
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(states.last, isA<QuizCompleted>());
        final completed = states.last as QuizCompleted;
        expect(completed.passed, isTrue);
        expect(completed.score, 100.0);
      }

      final prefs = await SharedPreferences.getInstance();
      final completedLessons = prefs.getStringList('completed_lessons') ?? [];
      expect(completedLessons.toSet(), {'1', '2', '3', '4', '5'});
      expect(await courseRepo.isCourseCompleted('farmer_test_1'), isTrue);

      await sub.cancel();
      await bloc.close();
    });
  });

  group('6. OnboardingBloc Tests', () {
    test('SelectLanguage, SelectDistrict, SetBatchInfo, AcceptDisclaimer, and CompleteOnboarding update state and persist flags', () async {
      SharedPreferences.setMockInitialValues({});

      final bloc = OnboardingBloc();
      final arrival = DateTime(2026, 10, 1);

      bloc.add(const SelectLanguage('en'));
      bloc.add(const SelectDistrict('Buxoro'));
      bloc.add(SetBatchInfo(arrival, 650));
      bloc.add(const AcceptDisclaimer());
      bloc.add(const CompleteOnboarding());

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(bloc.state.status, OnboardingStatus.success);
      expect(bloc.state.language, 'en');
      expect(bloc.state.district, 'Buxoro');
      expect(bloc.state.arrivalDate, arrival);
      expect(bloc.state.chickCount, 650);
      expect(bloc.state.acceptedDisclaimer, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'en');
      expect(prefs.getString('farmer_district'), 'Buxoro');
      expect(prefs.getString('arrival_date'), arrival.toIso8601String());
      expect(prefs.getInt('initial_count'), 650);
      expect(prefs.getInt('current_count'), 650);
      expect(prefs.getBool('onboarding_complete'), isTrue);

      await bloc.close();
    });
  });
}
