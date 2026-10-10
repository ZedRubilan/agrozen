import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/batch.dart';
import '../../../data/models/farmer.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../domain/alerts/alert_engine.dart';
import '../../../domain/alerts/alert_models.dart';
import '../../../domain/scheduler/day_calculator.dart';
import '../../../services/daily_counters.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final KnowledgeRepository _knowledgeRepository;
  final DiaryRepository _diaryRepository;

  HomeBloc({
    KnowledgeRepository? knowledgeRepository,
    DiaryRepository? diaryRepository,
  })  : _knowledgeRepository = knowledgeRepository ?? KnowledgeRepository(),
        _diaryRepository = diaryRepository ?? DiaryRepository(),
        super(const HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    await _loadAndEmit(emit);
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    await _loadAndEmit(emit);
  }

  Future<void> _loadAndEmit(Emitter<HomeState> emit) async {
    try {
      final prefs = await DailyCounters.rolled();
      final farmerName = prefs.getString('farmer_name') ?? 'Fermer';
      final district = prefs.getString('farmer_district') ?? 'Toshkent';
      final language = prefs.getString('app_language') ?? 'uz';
      final initialCount = prefs.getInt('initial_count') ?? 500;
      final currentCount = prefs.getInt('current_count') ?? initialCount;
      final arrivalStr = prefs.getString('arrival_date');
      final arrivalDate =
          (arrivalStr != null ? DateTime.tryParse(arrivalStr) : null) ??
              DateTime.now();

      final rawDay = DayCalculator.calculateBatchDay(arrivalDate);
      final batchDay = rawDay.clamp(1, 42);

      final farmer = Farmer(
        id: prefs.getString('farmer_id') ?? 'local_farmer',
        name: farmerName,
        phone: prefs.getString('farmer_phone') ?? '',
        district: district,
        language: language,
        createdAt: arrivalDate,
      );

      final activeBatch = Batch(
        id: prefs.getString('active_batch_id') ?? 'local_batch',
        farmerId: farmer.id,
        arrivalDate: arrivalDate,
        initialCount: initialCount,
        currentCount: currentCount,
        createdAt: arrivalDate,
      );

      final todayPlan = await _knowledgeRepository.getDailyPlan(batchDay);
      final norms = await _knowledgeRepository.getParsedNorms();
      final engine = AlertEngine(norms);

      final todayMortality = DailyCounters.getMortality(prefs);
      final lastWeight = prefs.getDouble('last_weight') ?? 0.0;
      final totalDeaths = (initialCount - currentCount).clamp(0, initialCount);

      final alerts = <AlertResult>[
        ...engine.runAllChecks(
          batchDay: batchDay,
          deaths: todayMortality,
          currentCount: currentCount,
          weightGrams: lastWeight > 0 ? lastWeight : null,
          totalDeaths: totalDeaths,
          initialCount: initialCount,
        ),
      ];

      final allEntries = await _diaryRepository.getEntriesForBatch(
        activeBatch.id,
      );
      final recentEntries = allEntries.take(7).toList();

      emit(HomeLoaded(
        farmer: farmer,
        activeBatch: activeBatch,
        batchDay: batchDay,
        todayPlan: todayPlan,
        alerts: alerts,
        recentEntries: recentEntries,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
