import 'package:flutter_bloc/flutter_bloc.dart';
import 'ask_event.dart';
import 'ask_state.dart';
class AskBloc extends Bloc<AskEvent, AskState> {
  AskBloc() : super(AskInitial()) {
    on<LoadChatHistory>((event, emit) => emit(const AskLoaded([], 30)));
    on<SendQuestion>((event, emit) => emit(const AskLoaded([], 29)));
    on<StartVoiceRecording>((event, emit) => emit(AskRecording()));
    on<StopVoiceRecordingAndSend>((event, emit) => emit(AskTranscribing()));
  }
}
