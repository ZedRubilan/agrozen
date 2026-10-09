import 'package:equatable/equatable.dart';
abstract class DailyPlanState extends Equatable {
  const DailyPlanState();
  @override
  List<Object?> get props => [];
}
class DailyPlanInitial extends DailyPlanState {}
class DailyPlanLoading extends DailyPlanState {}
class DailyPlanLoaded extends DailyPlanState {
  final dynamic currentDayPlan, allPlans;
  final int dayNumber;
  const DailyPlanLoaded(this.currentDayPlan, this.allPlans, this.dayNumber);
}
class DailyPlanError extends DailyPlanState {
  final String message;
  const DailyPlanError(this.message);
}
