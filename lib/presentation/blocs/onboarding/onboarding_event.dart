import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class SelectLanguage extends OnboardingEvent {
  final String language;

  const SelectLanguage(this.language);

  @override
  List<Object?> get props => [language];
}

class SelectDistrict extends OnboardingEvent {
  final String district;

  const SelectDistrict(this.district);

  @override
  List<Object?> get props => [district];
}

class SetBatchInfo extends OnboardingEvent {
  final DateTime arrivalDate;
  final int chickCount;

  const SetBatchInfo(this.arrivalDate, this.chickCount);

  @override
  List<Object?> get props => [arrivalDate, chickCount];
}

class AcceptDisclaimer extends OnboardingEvent {
  const AcceptDisclaimer();
}

class CompleteOnboarding extends OnboardingEvent {
  const CompleteOnboarding();
}
