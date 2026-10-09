import 'package:equatable/equatable.dart';
abstract class AskState extends Equatable {
  const AskState();
  @override
  List<Object?> get props => [];
}
class AskInitial extends AskState {}
class AskLoading extends AskState {}
class AskLoaded extends AskState {
  final List<dynamic> messages;
  final int remainingQuestionsToday;
  const AskLoaded(this.messages, this.remainingQuestionsToday);
}
class AskRecording extends AskState {}
class AskTranscribing extends AskState {}
class AskError extends AskState {
  final String message;
  const AskError(this.message);
}
