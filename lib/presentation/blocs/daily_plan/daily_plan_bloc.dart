import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../domain/scheduler/day_calculator.dart';
import 'daily_plan_event.dart';
import 'daily_plan_state.dart';

class DailyPlanBloc extends Bloc<DailyPlanEvent, DailyPlanState> {
  final KnowledgeRepository _knowledgeRepository;

  DailyPlanBloc({KnowledgeRepository? knowledgeRepository})
      : _knowledgeRepository = knowledgeRepository ?? KnowledgeRepository(),
        super(const DailyPlanInitial()) {
    on<LoadDailyPlan>(_onLoadDailyPlan);
    on<LoadAllPlans>(_onLoadAllPlans);
  }

  Future<void> _onLoadDailyPlan(
    LoadDailyPlan event,
    Emitter<DailyPlanState> emit,
  ) async {
    emit(const DailyPlanLoading());
    try {
      final day = event.day.clamp(1, 42);
      final allPlans = await _knowledgeRepository.getAllDailyPlans();
      final currentPlan = await _knowledgeRepository.getDailyPlan(day);
      emit(DailyPlanLoaded(currentPlan, allPlans, day));
    } catch (e) {
      emit(DailyPlanError(e.toString()));
    }
  }

  Future<void> _onLoadAllPlans(
    LoadAllPlans event,
    Emitter<DailyPlanState> emit,
  ) async {
    emit(const DailyPlanLoading());
    try {
      int day = 1;
      try {
        final prefs = await SharedPreferences.getInstance();
        final arrivalStr = prefs.getString('arrival_date');
        if (arrivalStr != null) {
          final arrivalDate = DateTime.tryParse(arrivalStr);
          if (arrivalDate != null) {
            day = DayCalculator.calculateBatchDay(arrivalDate).clamp(1, 42);
          }
        }
      } catch (_) {}

      final allPlans = await _knowledgeRepository.getAllDailyPlans();
      final currentPlan = await _knowledgeRepository.getDailyPlan(day);
      emit(DailyPlanLoaded(currentPlan, allPlans, day));
    } catch (e) {
      emit(DailyPlanError(e.toString()));
    }
  }
}
