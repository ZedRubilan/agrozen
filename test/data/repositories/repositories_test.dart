import 'package:agrozen/config/supabase_config.dart';
import 'package:agrozen/data/models/batch.dart';
import 'package:agrozen/data/models/diary_entry.dart';
import 'package:agrozen/data/models/farmer.dart';
import 'package:agrozen/data/repositories/auth_repository.dart';
import 'package:agrozen/data/repositories/batch_repository.dart';
import 'package:agrozen/data/repositories/course_repository.dart';
import 'package:agrozen/data/repositories/diary_repository.dart';
import 'package:agrozen/data/repositories/farmer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Repositories Integration Tests (Supabase unconfigured)', () {
    test('AuthRepository can be instantiated and accessed offline without throwing', () async {
      expect(SupabaseConfig.isConfigured, isFalse);

      final authRepo = AuthRepository();
      expect(authRepo.currentUser, isNull);
      expect(authRepo.currentSession, isNull);
      expect(authRepo.isAuthenticated, isFalse);
      expect(authRepo.currentUserId, isNull);

      final events = await authRepo.authStateChanges.toList();
      expect(events, isEmpty);
    });

    test('FarmerRepository creates, fetches, and updates a Farmer offline', () async {
      final repo = FarmerRepository();
      final now = DateTime.parse('2026-10-10T08:00:00.000Z');
      final farmer = Farmer(
        id: 'farmer-offline-1',
        phone: '+998901112233',
        name: 'Sardor Rahimov',
        language: 'uz',
        district: 'Samarqand',
        disclaimerAccepted: true,
        dailyQuestionCount: 2,
        lastQuestionDate: now,
        createdAt: now,
      );

      final created = await repo.createFarmer(farmer);
      expect(created, equals(farmer));

      final fetched = await repo.getFarmer('farmer-offline-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Sardor Rahimov');
      expect(fetched.district, 'Samarqand');
      expect(fetched.phone, '+998901112233');

      final byPhone = await repo.getFarmerByPhone('+998901112233');
      expect(byPhone, isNotNull);
      expect(byPhone!.id, 'farmer-offline-1');

      final updated = await repo.updateFarmer(
        farmer.copyWith(name: 'Sardor Aka', district: 'Buxoro', language: 'en'),
      );
      expect(updated.name, 'Sardor Aka');
      expect(updated.district, 'Buxoro');
      expect(updated.language, 'en');

      final fetchedAfterUpdate = await repo.getFarmer('farmer-offline-1');
      expect(fetchedAfterUpdate!.name, 'Sardor Aka');
      expect(fetchedAfterUpdate.district, 'Buxoro');
      expect(fetchedAfterUpdate.language, 'en');
    });

    test('BatchRepository creates, fetches, updates count, and completes an active Batch offline', () async {
      final repo = BatchRepository();
      final arrival = DateTime.parse('2026-10-01T06:00:00.000Z');
      final batch = Batch(
        id: 'batch-offline-1',
        farmerId: 'farmer-offline-1',
        arrivalDate: arrival,
        initialCount: 1000,
        currentCount: 995,
        status: 'active',
        createdAt: arrival,
      );

      final created = await repo.createBatch(batch);
      expect(created, equals(batch));

      final active = await repo.getActiveBatch('farmer-offline-1');
      expect(active, isNotNull);
      expect(active!.id, 'batch-offline-1');
      expect(active.initialCount, 1000);
      expect(active.currentCount, 995);

      final countUpdated = await repo.updateBatchCount('batch-offline-1', 990);
      expect(countUpdated.currentCount, 990);

      final allBatches = await repo.getBatchesForFarmer('farmer-offline-1');
      expect(allBatches, hasLength(1));
      expect(allBatches.first.currentCount, 990);

      final completed = await repo.completeBatch('batch-offline-1');
      expect(completed.status, 'completed');
    });

    test('DiaryRepository creates, fetches, filters by date, and deletes DiaryEntry items offline', () async {
      final repo = DiaryRepository();
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final entryTodayMortality = DiaryEntry(
        id: 'entry-1',
        batchId: 'batch-offline-1',
        entryDate: today,
        entryType: 'mortality',
        value: 3.0,
        notes: '3 chicks lost',
        createdAt: today,
      );

      final entryTodayFeed = DiaryEntry(
        id: 'entry-2',
        batchId: 'batch-offline-1',
        entryDate: today,
        entryType: 'feed',
        value: 45.5,
        notes: 'Starter crumble',
        createdAt: today,
      );

      final entryYesterdayMortality = DiaryEntry(
        id: 'entry-3',
        batchId: 'batch-offline-1',
        entryDate: yesterday,
        entryType: 'mortality',
        value: 5.0,
        notes: 'Yesterday mortality',
        createdAt: yesterday,
      );

      await repo.addEntry(entryYesterdayMortality);
      await repo.addEntry(entryTodayFeed);
      await repo.addEntry(entryTodayMortality);

      final allForBatch = await repo.getEntriesForBatch('batch-offline-1');
      expect(allForBatch, hasLength(3));

      final todayEntries = await repo.getEntriesForDate('batch-offline-1', today);
      expect(todayEntries, hasLength(2));
      expect(todayEntries.map((e) => e.id), containsAll(['entry-1', 'entry-2']));

      final yesterdayEntries = await repo.getEntriesForDate('batch-offline-1', yesterday);
      expect(yesterdayEntries, hasLength(1));
      expect(yesterdayEntries.first.id, 'entry-3');

      final todayMortality = await repo.getTodayMortality('batch-offline-1');
      expect(todayMortality, 3.0);

      await repo.deleteEntry('entry-1');
      final remaining = await repo.getEntriesForBatch('batch-offline-1');
      expect(remaining, hasLength(2));
    });

    test('CourseRepository loads lessons in uz, ru, en and saves/fetches progress idempotently', () async {
      final repo = CourseRepository();

      final lessonsUz = await repo.getLessons('uz');
      final lessonsRu = await repo.getLessons('ru');
      final lessonsEn = await repo.getLessons('en');

      expect(lessonsUz, hasLength(CourseRepository.totalLessonsCount));
      expect(lessonsRu, hasLength(CourseRepository.totalLessonsCount));
      expect(lessonsEn, hasLength(CourseRepository.totalLessonsCount));

      expect(lessonsEn.first.title, isNotEmpty);
      expect(lessonsEn.first.quiz?.question, isNotEmpty);
      expect(lessonsEn.first.title, isNot(equals(lessonsRu.first.title)));

      // Save progress for lesson 1 twice (idempotent re-save)
      await repo.saveProgress(
        farmerId: 'farmer-offline-1',
        lessonNumber: 1,
        quizPassed: false,
      );
      await repo.saveProgress(
        farmerId: 'farmer-offline-1',
        lessonNumber: 1,
        quizPassed: true,
      );

      final progressList = await repo.getFarmerProgress('farmer-offline-1');
      final lesson1Entries = progressList.where((p) => p.lessonNumber == 1).toList();
      expect(lesson1Entries, hasLength(1));
      expect(lesson1Entries.first.quizPassed, isTrue);

      final singleProgress = await repo.getLessonProgress('farmer-offline-1', 1);
      expect(singleProgress, isNotNull);
      expect(singleProgress!.quizPassed, isTrue);

      expect(await repo.isCourseCompleted('farmer-offline-1'), isFalse);

      for (int i = 2; i <= CourseRepository.totalLessonsCount; i++) {
        await repo.saveProgress(
          farmerId: 'farmer-offline-1',
          lessonNumber: i,
          quizPassed: true,
        );
      }

      expect(await repo.isCourseCompleted('farmer-offline-1'), isTrue);
    });
  });
}
