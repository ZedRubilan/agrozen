import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../domain/alerts/alert_engine.dart';
import '../../../domain/alerts/alert_models.dart';
import '../../../domain/scheduler/day_calculator.dart';
import '../../../domain/validators/diary_validators.dart';
import '../../../services/daily_counters.dart';
import 'diary_event.dart';
import 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final DiaryRepository _diaryRepository;
  final KnowledgeRepository _knowledgeRepository;

  DiaryBloc({
    DiaryRepository? diaryRepository,
    KnowledgeRepository? knowledgeRepository,
  })  : _diaryRepository = diaryRepository ?? DiaryRepository(),
        _knowledgeRepository = knowledgeRepository ?? KnowledgeRepository(),
        super(const DiaryInitial()) {
    on<LoadDiaryEntries>(_onLoadDiaryEntries);
    on<AddMortalityEntry>(_onAddMortalityEntry);
    on<AddFeedEntry>(_onAddFeedEntry);
    on<AddWeightEntry>(_onAddWeightEntry);
  }

  Future<void> _onLoadDiaryEntries(
    LoadDiaryEntries event,
    Emitter<DiaryState> emit,
  ) async {
    emit(const DiaryLoading());
    try {
      final prefs = await DailyCounters.rolled();
      final batchId = prefs.getString('active_batch_id') ?? 'local_batch';
      final initialCount = prefs.getInt('initial_count') ?? 500;
      final currentCount = prefs.getInt('current_count') ?? initialCount;
      final arrivalStr = prefs.getString('arrival_date');
      final arrivalDate =
          (arrivalStr != null ? DateTime.tryParse(arrivalStr) : null) ??
              DateTime.now();
      final batchDay = DayCalculator.calculateBatchDay(arrivalDate).clamp(1, 42);

      final norms = await _knowledgeRepository.getParsedNorms();
      final engine = AlertEngine(norms);
      final todayDeaths = DailyCounters.getMortality(prefs);
      final lastWeight = prefs.getDouble('last_weight') ?? 0.0;
      final totalDeaths = (initialCount - currentCount).clamp(0, initialCount);

      final alerts = <AlertResult>[
        ...engine.runAllChecks(
          batchDay: batchDay,
          deaths: todayDeaths,
          currentCount: currentCount,
          weightGrams: lastWeight > 0 ? lastWeight : null,
          totalDeaths: totalDeaths,
          initialCount: initialCount,
        ),
      ];

      final entries = await _diaryRepository.getEntriesForBatch(batchId);
      emit(DiaryLoaded(entries, alerts));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }

  Future<void> _onAddMortalityEntry(
    AddMortalityEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(const DiarySubmitting());
    try {
      final prefs = await DailyCounters.rolled();
      final lang = prefs.getString('app_language') ?? 'uz';
      final initialCount = prefs.getInt('initial_count') ?? 500;
      final currentCount = prefs.getInt('current_count') ?? initialCount;

      final validationError = DiaryValidators.validateMortality(
        event.deaths,
        currentCount,
        locale: lang,
      );
      if (validationError != null) {
        emit(DiaryError(validationError));
        return;
      }

      final newCount = (currentCount - event.deaths).clamp(0, initialCount);
      await prefs.setInt('current_count', newCount);
      await DailyCounters.addMortality(prefs, event.deaths);

      final batchId = prefs.getString('active_batch_id') ?? 'local_batch';
      final now = DateTime.now();
      await _diaryRepository.addEntry(
        DiaryEntry(
          id: 'mortality_${now.millisecondsSinceEpoch}',
          batchId: batchId,
          entryDate: now,
          entryType: 'mortality',
          value: event.deaths.toDouble(),
          notes: event.notes.isNotEmpty ? event.notes : null,
          createdAt: now,
        ),
      );

      final norms = await _knowledgeRepository.getParsedNorms();
      final engine = AlertEngine(norms);
      final totalDeathsToday = DailyCounters.getMortality(prefs);
      final alert = engine.checkMortality(
        deaths: totalDeathsToday,
        currentCount: currentCount,
      );
      emit(DiarySuccess(alert));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }

  Future<void> _onAddFeedEntry(
    AddFeedEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(const DiarySubmitting());
    try {
      final prefs = await DailyCounters.rolled();
      final lang = prefs.getString('app_language') ?? 'uz';
      final validationError = DiaryValidators.validateFeed(
        event.kg,
        locale: lang,
      );
      if (validationError != null) {
        emit(DiaryError(validationError));
        return;
      }

      await DailyCounters.addFeed(prefs, event.kg);

      final batchId = prefs.getString('active_batch_id') ?? 'local_batch';
      final now = DateTime.now();
      await _diaryRepository.addEntry(
        DiaryEntry(
          id: 'feed_${now.millisecondsSinceEpoch}',
          batchId: batchId,
          entryDate: now,
          entryType: 'feed',
          value: event.kg,
          notes: event.notes.isNotEmpty ? event.notes : null,
          createdAt: now,
        ),
      );

      emit(const DiarySuccess(null));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }

  Future<void> _onAddWeightEntry(
    AddWeightEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(const DiarySubmitting());
    try {
      final prefs = await DailyCounters.rolled();
      final lang = prefs.getString('app_language') ?? 'uz';
      final validationError = DiaryValidators.validateWeight(
        event.grams,
        locale: lang,
      );
      if (validationError != null) {
        emit(DiaryError(validationError));
        return;
      }

      await prefs.setDouble('last_weight', event.grams);

      final batchId = prefs.getString('active_batch_id') ?? 'local_batch';
      final now = DateTime.now();
      await _diaryRepository.addEntry(
        DiaryEntry(
          id: 'weight_${now.millisecondsSinceEpoch}',
          batchId: batchId,
          entryDate: now,
          entryType: 'weight',
          value: event.grams,
          notes: event.notes.isNotEmpty ? event.notes : null,
          createdAt: now,
        ),
      );

      final arrivalStr = prefs.getString('arrival_date');
      final arrivalDate =
          (arrivalStr != null ? DateTime.tryParse(arrivalStr) : null) ??
              DateTime.now();
      final batchDay = DayCalculator.calculateBatchDay(arrivalDate).clamp(1, 42);
      final norms = await _knowledgeRepository.getParsedNorms();
      final engine = AlertEngine(norms);

      final alert = engine.checkWeight(
        weightGrams: event.grams,
        batchDay: batchDay,
      );
      emit(DiarySuccess(alert));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }
}
