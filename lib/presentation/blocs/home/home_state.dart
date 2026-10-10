import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final dynamic farmer;
  final dynamic activeBatch;
  final dynamic batchDay;
  final dynamic todayPlan;
  final dynamic alerts;
  final dynamic recentEntries;

  const HomeLoaded({
    this.farmer,
    this.activeBatch,
    this.batchDay,
    this.todayPlan,
    this.alerts,
    this.recentEntries,
  });

  @override
  List<Object?> get props => [
        farmer,
        activeBatch,
        batchDay,
        todayPlan,
        alerts,
        recentEntries,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
