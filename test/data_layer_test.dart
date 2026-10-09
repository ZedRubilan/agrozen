import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrozen/config/constants.dart';
import 'package:agrozen/config/theme.dart';
import 'package:agrozen/data/models/farmer.dart';
import 'package:agrozen/data/models/batch.dart';
import 'package:agrozen/data/models/diary_entry.dart';
import 'package:agrozen/data/models/daily_plan.dart';
import 'package:agrozen/data/models/question_log.dart';
import 'package:agrozen/data/models/course_progress.dart';
import 'package:agrozen/data/models/course_lesson.dart';
import 'package:agrozen/data/providers/ai_provider.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';

class MockAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  MockAssetBundle(this.assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (assets.containsKey(key)) {
      return assets[key]!;
    }
    throw Exception('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    final bytes = utf8.encode(str);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  group('AppConstants & AppTheme Tests', () {
    test('AppConstants contains correct defaults', () {
      expect(AppConstants.maxDailyQuestions, 30);
      expect(AppConstants.broilerCycleDays, 42);
      expect(AppConstants.timezone, 'Asia/Tashkent');
      expect(AppConstants.morningNotificationHour, 7);
      expect(AppConstants.supportedLocales, ['uz', 'ru']);
      expect(AppConstants.districts.length, 13);
      expect(AppConstants.districts, contains('Namangan'));
      expect(AppConstants.districts, contains('Toshkent'));
    });

    test('AppTheme defines primary and secondary farming palette', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.primary, AppTheme.primaryGreen);
      expect(theme.colorScheme.secondary, AppTheme.secondaryBrown);
      expect(theme.useMaterial3, true);
    });
  });

  group('Data Models JSON Serialization', () {
    test('Farmer model encodes and decodes snake_case correctly', () {
      final now = DateTime.parse('2026-10-09T10:00:00.000Z');
      final farmer = Farmer(
        id: 'farmer-123',
        phone: '+998901234567',
        name: 'Ali Valiyev',
        language: 'uz',
        district: 'Namangan',
        disclaimerAccepted: true,
        dailyQuestionCount: 5,
        lastQuestionDate: now,
        createdAt: now,
      );

      final json = farmer.toJson();
      expect(json['id'], 'farmer-123');
      expect(json['phone'], '+998901234567');
      expect(json['name'], 'Ali Valiyev');
      expect(json['language'], 'uz');
      expect(json['district'], 'Namangan');
      expect(json['disclaimer_accepted'], true);
      expect(json['daily_question_count'], 5);
      expect(json['last_question_date'], now.toIso8601String());
      expect(json['created_at'], now.toIso8601String());

      final fromJson = Farmer.fromJson(json);
      expect(fromJson, farmer);
    });

    test('Batch model encodes and decodes correctly', () {
      final now = DateTime.parse('2026-10-09T10:00:00.000Z');
      final batch = Batch(
        id: 'batch-001',
        farmerId: 'farmer-123',
        arrivalDate: now,
        initialCount: 500,
        currentCount: 495,
        status: 'active',
        createdAt: now,
      );

      final json = batch.toJson();
      expect(json['id'], 'batch-001');
      expect(json['farmer_id'], 'farmer-123');
      expect(json['initial_count'], 500);
      expect(json['current_count'], 495);
      expect(json['status'], 'active');

      final fromJson = Batch.fromJson(json);
      expect(fromJson, batch);
    });

    test('DiaryEntry model encodes and decodes correctly', () {
      final now = DateTime.parse('2026-10-09T10:00:00.000Z');
      final entry = DiaryEntry(
        id: 'entry-001',
        batchId: 'batch-001',
        entryDate: now,
        entryType: 'mortality',
        value: 2.0,
        notes: 'Chicks were cold',
        createdAt: now,
      );

      final json = entry.toJson();
      expect(json['id'], 'entry-001');
      expect(json['batch_id'], 'batch-001');
      expect(json['entry_type'], 'mortality');
      expect(json['value'], 2.0);
      expect(json['notes'], 'Chicks were cold');

      final fromJson = DiaryEntry.fromJson(json);
      expect(fromJson, entry);
    });

    test('DailyPlan model translates tasks correctly', () {
      const plan = DailyPlan(
        day: 1,
        tasksRu: 'Подготовка брудера',
        tasksUz: 'Bruderni tayyorlash',
        videoUrl: 'https://youtube.com/v1',
      );

      expect(plan.getTasks('ru'), 'Подготовка брудера');
      expect(plan.getTasks('uz'), 'Bruderni tayyorlash');

      final json = plan.toJson();
      expect(json['day'], 1);
      expect(json['tasks_ru'], 'Подготовка брудера');
      expect(json['tasks_uz'], 'Bruderni tayyorlash');
      expect(json['video_url'], 'https://youtube.com/v1');

      final fromJson = DailyPlan.fromJson(json);
      expect(fromJson, plan);
    });

    test('QuestionLog model encodes and decodes correctly', () {
      final now = DateTime.parse('2026-10-09T10:00:00.000Z');
      final log = QuestionLog(
        id: 'log-001',
        farmerId: 'farmer-123',
        question: 'Jo\'jalar nima uchun chirillayapti?',
        answer: 'Sovuq bo\'lishi mumkin',
        topicsUsed: const ['temperature', 'brooder'],
        language: 'uz',
        source: 'voice',
        transcribedText: 'Jo\'jalar nima uchun chirillayapti?',
        createdAt: now,
      );

      final json = log.toJson();
      expect(json['farmer_id'], 'farmer-123');
      expect(json['source'], 'voice');
      expect(json['topics_used'], ['temperature', 'brooder']);

      final fromJson = QuestionLog.fromJson(json);
      expect(fromJson, log);
    });

    test('CourseProgress model encodes and decodes correctly', () {
      final now = DateTime.parse('2026-10-09T10:00:00.000Z');
      final progress = CourseProgress(
        id: 'prog-001',
        farmerId: 'farmer-123',
        lessonNumber: 1,
        quizPassed: true,
        completedAt: now,
      );

      final json = progress.toJson();
      expect(json['farmer_id'], 'farmer-123');
      expect(json['lesson_number'], 1);
      expect(json['quiz_passed'], true);
      expect(json['completed_at'], now.toIso8601String());

      final fromJson = CourseProgress.fromJson(json);
      expect(fromJson, progress);
    });

    test('CourseLesson and CourseQuiz model serialize correctly', () {
      const quiz = CourseQuiz(
        question: 'What temp?',
        options: ['20', '32'],
        correctOptionIndex: 1,
        explanation: '32C is right',
      );
      const lesson = CourseLesson(
        lessonNumber: 1,
        title: 'Brooder prep',
        content: 'Check temperature',
        quiz: quiz,
      );

      final json = lesson.toJson();
      expect(json['lesson_number'], 1);
      expect(json['title'], 'Brooder prep');
      expect(json['quiz']['question'], 'What temp?');

      final fromJson = CourseLesson.fromJson(json);
      expect(fromJson, lesson);
    });
  });

  group('AiResponse Tests', () {
    test('AiResponse parses camelCase and snake_case properly', () {
      final res1 = AiResponse.fromJson({
        'answer': 'Temperature should be 32C',
        'sources_used': ['temperature.md'],
      });
      expect(res1.answer, 'Temperature should be 32C');
      expect(res1.sourcesUsed, ['temperature.md']);

      final res2 = AiResponse.fromJson({
        'answer': 'Use starter feed',
        'sourcesUsed': ['feed.md'],
      });
      expect(res2.sourcesUsed, ['feed.md']);
    });
  });

  group('KnowledgeRepository Tests', () {
    late KnowledgeRepository repo;

    setUp(() {
      final mockAssets = {
        'knowledge/broiler_plan.json': jsonEncode([
          {
            'day': 1,
            'tasks_ru': 'День 1 задачи',
            'tasks_uz': '1-kun vazifalari',
            'video_url': 'https://youtube.com/day1',
          },
          {
            'day': 2,
            'tasks_ru': 'День 2 задачи',
            'tasks_uz': '2-kun vazifalari',
            'video_url': null,
          }
        ]),
        'knowledge/norms.json': jsonEncode({
          'breed': 'Ross-308',
          'daily_norms': {
            '1': {'weight_g': 42, 'feed_g': 12}
          }
        }),
        'knowledge/vets.json': jsonEncode([
          {
            'district': 'Namangan',
            'name': 'Dr. Mirzayev',
            'phone': '+998932114506',
          },
          {
            'district': 'Toshkent',
            'name': 'Dr. Karimov',
            'phone': '+998901234501',
          }
        ]),
        'knowledge/videos.json': jsonEncode([
          {
            'day': 1,
            'url': 'https://youtube.com/day1',
          }
        ]),
        'knowledge/broilers/uz/temperature.md':
            '# Harorat\nBruder 32-33C bo\'lishi kerak',
      };

      repo = KnowledgeRepository(bundle: MockAssetBundle(mockAssets));
    });

    test('getDailyPlan loads specific day', () async {
      final plan1 = await repo.getDailyPlan(1);
      expect(plan1, isNotNull);
      expect(plan1!.day, 1);
      expect(plan1.tasksUz, '1-kun vazifalari');
      expect(plan1.videoUrl, 'https://youtube.com/day1');

      final plan99 = await repo.getDailyPlan(99);
      expect(plan99, isNull);
    });

    test('getNorms loads norms dictionary', () async {
      final norms = await repo.getNorms();
      expect(norms['breed'], 'Ross-308');
      expect(norms['daily_norms']['1']['weight_g'], 42);
    });

    test('getVetByDistrict filters veterinarians by district', () async {
      final namanganVets = await repo.getVetByDistrict('Namangan');
      expect(namanganVets.length, 1);
      expect(namanganVets.first['name'], 'Dr. Mirzayev');

      final toshkentVets = await repo.getVetByDistrict('Toshkent');
      expect(toshkentVets.length, 1);
      expect(toshkentVets.first['name'], 'Dr. Karimov');
    });

    test('getVideoForDay returns video URL from plan or videos', () async {
      final video = await repo.getVideoForDay(1);
      expect(video, 'https://youtube.com/day1');
    });

    test('getTopicContent returns markdown content', () async {
      final content = await repo.getTopicContent('uz', 'temperature');
      expect(content, contains('Bruder 32-33C'));
    });
  });
}
