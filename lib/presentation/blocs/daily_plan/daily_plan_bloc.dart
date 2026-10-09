import 'package:flutter_bloc/flutter_bloc.dart';
import 'daily_plan_event.dart';
import 'daily_plan_state.dart';
class DailyPlanBloc extends Bloc<DailyPlanEvent, DailyPlanState> {
  DailyPlanBloc() : super(DailyPlanInitial()) {
    on<LoadDailyPlan>((event, emit) => emit(DailyPlanLoaded(null, null, event.day)));
    on<LoadAllPlans>((event, emit) => emit(const DailyPlanLoaded(null, null, 1)));
  }
}
