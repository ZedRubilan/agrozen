import 'package:equatable/equatable.dart';

abstract class DailyPlanEvent extends Equatable {
  const DailyPlanEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailyPlan extends DailyPlanEvent {
  final int day;

  const LoadDailyPlan(this.day);

  @override
  List<Object?> get props => [day];
}

class LoadAllPlans extends DailyPlanEvent {
  const LoadAllPlans();
}
