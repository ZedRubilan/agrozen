import 'package:equatable/equatable.dart';
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final dynamic farmer, activeBatch, batchDay, todayPlan, alerts, recentEntries;
  const HomeLoaded({this.farmer, this.activeBatch, this.batchDay, this.todayPlan, this.alerts, this.recentEntries});
}
class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}
