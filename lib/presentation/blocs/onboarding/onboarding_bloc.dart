import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<SelectLanguage>((event, emit) => emit(state.copyWith(language: event.language)));
    on<SelectDistrict>((event, emit) => emit(state.copyWith(district: event.district)));
    on<SetBatchInfo>((event, emit) => emit(state.copyWith(arrivalDate: event.arrivalDate, chickCount: event.chickCount)));
    on<AcceptDisclaimer>((event, emit) => emit(state.copyWith(acceptedDisclaimer: true)));
    on<CompleteOnboarding>((event, emit) => emit(state.copyWith(status: OnboardingStatus.success)));
  }
}
