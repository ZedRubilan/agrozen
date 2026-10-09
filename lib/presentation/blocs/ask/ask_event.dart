import 'package:equatable/equatable.dart';
abstract class AskEvent extends Equatable {
  const AskEvent();
  @override
  List<Object> get props => [];
}
class LoadChatHistory extends AskEvent {}
class SendQuestion extends AskEvent {
  final String text;
  const SendQuestion(this.text);
}
class StartVoiceRecording extends AskEvent {}
class StopVoiceRecordingAndSend extends AskEvent {}
