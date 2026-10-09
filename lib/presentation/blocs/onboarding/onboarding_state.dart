import 'package:equatable/equatable.dart';
enum OnboardingStatus { initial, inProgress, success, failure }
class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final String? language;
  final String? district;
  final DateTime? arrivalDate;
  final int? chickCount;
  final bool acceptedDisclaimer;
  final String? errorMessage;
  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.language,
    this.district,
    this.arrivalDate,
    this.chickCount,
    this.acceptedDisclaimer = false,
    this.errorMessage,
  });
  OnboardingState copyWith({
    OnboardingStatus? status,
    String? language,
    String? district,
    DateTime? arrivalDate,
    int? chickCount,
    bool? acceptedDisclaimer,
    String? errorMessage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      language: language ?? this.language,
      district: district ?? this.district,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      chickCount: chickCount ?? this.chickCount,
      acceptedDisclaimer: acceptedDisclaimer ?? this.acceptedDisclaimer,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  @override
  List<Object?> get props => [status, language, district, arrivalDate, chickCount, acceptedDisclaimer, errorMessage];
}
