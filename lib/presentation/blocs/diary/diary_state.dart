import 'package:equatable/equatable.dart';

abstract class DiaryState extends Equatable {
  const DiaryState();

  @override
  List<Object?> get props => [];
}

class DiaryInitial extends DiaryState {
  const DiaryInitial();
}

class DiaryLoading extends DiaryState {
  const DiaryLoading();
}

class DiaryLoaded extends DiaryState {
  final List<dynamic> entries;
  final List<dynamic> activeAlerts;

  const DiaryLoaded(this.entries, this.activeAlerts);

  @override
  List<Object?> get props => [entries, activeAlerts];
}

class DiarySubmitting extends DiaryState {
  const DiarySubmitting();
}

class DiarySuccess extends DiaryState {
  final dynamic alertResult;

  const DiarySuccess(this.alertResult);

  @override
  List<Object?> get props => [alertResult];
}

class DiaryError extends DiaryState {
  final String message;

  const DiaryError(this.message);

  @override
  List<Object?> get props => [message];
}
