import 'package:equatable/equatable.dart';

abstract class DailyPlanState extends Equatable {
  const DailyPlanState();

  @override
  List<Object?> get props => [];
}

class DailyPlanInitial extends DailyPlanState {
  const DailyPlanInitial();
}

class DailyPlanLoading extends DailyPlanState {
  const DailyPlanLoading();
}

class DailyPlanLoaded extends DailyPlanState {
  final dynamic currentDayPlan;
  final dynamic allPlans;
  final int dayNumber;

  const DailyPlanLoaded(this.currentDayPlan, this.allPlans, this.dayNumber);

  @override
  List<Object?> get props => [currentDayPlan, allPlans, dayNumber];
}

class DailyPlanError extends DailyPlanState {
  final String message;

  const DailyPlanError(this.message);

  @override
  List<Object?> get props => [message];
}
