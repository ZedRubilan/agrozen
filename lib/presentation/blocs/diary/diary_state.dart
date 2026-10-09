import 'package:equatable/equatable.dart';
abstract class DiaryState extends Equatable {
  const DiaryState();
  @override
  List<Object?> get props => [];
}
class DiaryInitial extends DiaryState {}
class DiaryLoading extends DiaryState {}
class DiaryLoaded extends DiaryState {
  final List<dynamic> entries;
  final List<dynamic> activeAlerts;
  const DiaryLoaded(this.entries, this.activeAlerts);
}
class DiarySubmitting extends DiaryState {}
class DiarySuccess extends DiaryState {
  final dynamic alertResult;
  const DiarySuccess(this.alertResult);
}
class DiaryError extends DiaryState {
  final String message;
  const DiaryError(this.message);
}
