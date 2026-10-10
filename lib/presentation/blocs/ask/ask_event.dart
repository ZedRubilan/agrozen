import 'package:equatable/equatable.dart';

abstract class AskEvent extends Equatable {
  const AskEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatHistory extends AskEvent {
  const LoadChatHistory();
}

class SendQuestion extends AskEvent {
  final String text;

  const SendQuestion(this.text);

  @override
  List<Object?> get props => [text];
}

class StartVoiceRecording extends AskEvent {
  const StartVoiceRecording();
}

class StopVoiceRecordingAndSend extends AskEvent {
  const StopVoiceRecordingAndSend();
}
