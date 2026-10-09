import 'package:equatable/equatable.dart';
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object> get props => [];
}
class SelectLanguage extends OnboardingEvent {
  final String language;
  const SelectLanguage(this.language);
}
class SelectDistrict extends OnboardingEvent {
  final String district;
  const SelectDistrict(this.district);
}
class SetBatchInfo extends OnboardingEvent {
  final DateTime arrivalDate;
  final int chickCount;
  const SetBatchInfo(this.arrivalDate, this.chickCount);
}
class AcceptDisclaimer extends OnboardingEvent {}
class CompleteOnboarding extends OnboardingEvent {}
