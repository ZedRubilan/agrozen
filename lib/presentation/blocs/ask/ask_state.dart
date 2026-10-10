import 'package:equatable/equatable.dart';

abstract class AskState extends Equatable {
  const AskState();

  @override
  List<Object?> get props => [];
}

class AskInitial extends AskState {
  const AskInitial();
}

class AskLoading extends AskState {
  const AskLoading();
}

class AskLoaded extends AskState {
  final List<dynamic> messages;
  final int remainingQuestionsToday;

  const AskLoaded(this.messages, this.remainingQuestionsToday);

  @override
  List<Object?> get props => [messages, remainingQuestionsToday];
}

class AskRecording extends AskState {
  const AskRecording();
}

class AskTranscribing extends AskState {
  const AskTranscribing();
}

class AskError extends AskState {
  final String message;

  const AskError(this.message);

  @override
  List<Object?> get props => [message];
}
