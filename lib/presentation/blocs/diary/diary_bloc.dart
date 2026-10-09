import 'package:flutter_bloc/flutter_bloc.dart';
import 'diary_event.dart';
import 'diary_state.dart';
class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  DiaryBloc() : super(DiaryInitial()) {
    on<LoadDiaryEntries>((event, emit) => emit(const DiaryLoaded([], [])));
    on<AddMortalityEntry>((event, emit) => emit(const DiarySuccess(null)));
    on<AddFeedEntry>((event, emit) => emit(const DiarySuccess(null)));
    on<AddWeightEntry>((event, emit) => emit(const DiarySuccess(null)));
  }
}
