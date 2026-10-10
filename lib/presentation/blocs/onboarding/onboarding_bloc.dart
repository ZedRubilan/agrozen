import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/daily_counters.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<SelectLanguage>((event, emit) {
      emit(state.copyWith(
        status: OnboardingStatus.inProgress,
        language: event.language,
      ));
    });
    on<SelectDistrict>((event, emit) {
      emit(state.copyWith(
        status: OnboardingStatus.inProgress,
        district: event.district,
      ));
    });
    on<SetBatchInfo>((event, emit) {
      emit(state.copyWith(
        status: OnboardingStatus.inProgress,
        arrivalDate: event.arrivalDate,
        chickCount: event.chickCount,
      ));
    });
    on<AcceptDisclaimer>((event, emit) {
      emit(state.copyWith(
        status: OnboardingStatus.inProgress,
        acceptedDisclaimer: true,
      ));
    });
    on<CompleteOnboarding>(_onCompleteOnboarding);
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await DailyCounters.resetAll(prefs);

      if (state.language != null) {
        await prefs.setString('app_language', state.language!);
      }
      if (state.district != null) {
        await prefs.setString('farmer_district', state.district!);
      }
      if (state.arrivalDate != null) {
        await prefs.setString(
          'arrival_date',
          state.arrivalDate!.toIso8601String(),
        );
      }
      if (state.chickCount != null && state.chickCount! > 0) {
        await prefs.setInt('initial_count', state.chickCount!);
        await prefs.setInt('current_count', state.chickCount!);
      }
      await prefs.setBool('onboarding_complete', true);
      await DailyCounters.ensureToday(prefs);

      emit(state.copyWith(status: OnboardingStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
