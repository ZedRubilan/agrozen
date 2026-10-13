import 'package:flutter/material.dart';
import '../../domain/alerts/alert_models.dart';
import '../../services/external_actions.dart';
import '../ui/components.dart';

/// A flock alert (high mortality, low weight…) with a one-tap call to the
/// district veterinarian. Treatment advice is always left to the vet.
class AlertCard extends StatelessWidget {
  final String message;
  final AlertSeverity severity;
  final String? vetPhone;
  final String? vetName;
  final String? locale;
  final VoidCallback? onCallVet;

  const AlertCard({
    super.key,
    required this.message,
    this.severity = AlertSeverity.warning,
    this.vetPhone,
    this.vetName,
    this.locale,
    this.onCallVet,
  });

  factory AlertCard.fromAlertResult({
    Key? key,
    required AlertResult alert,
    required String locale,
    String? vetPhone,
    String? vetName,
    VoidCallback? onCallVet,
  }) {
    final lower = locale.toLowerCase();
    final message = lower == 'en'
        ? (alert.messageEn ?? 'Parameters deviated from target norms.')
        : (lower == 'ru'
            ? (alert.messageRu ?? 'Показатели отклонились от нормы.')
            : (alert.messageUz ?? "Ko'rsatkichlar me'yordan chetga chiqdi."));
    return AlertCard(
      key: key,
      message: message,
      severity: alert.severity,
      vetPhone: vetPhone,
      vetName: vetName,
      locale: lower,
      onCallVet: onCallVet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == AlertSeverity.critical;
    final lang = (locale ?? 'uz').toLowerCase();
    final isEn = lang == 'en';
    final isRu = lang == 'ru';

    final String title;
    if (locale == null) {
      title = isCritical ? 'XAVF! / ОПАСНОСТЬ!' : 'OGOHLANTIRISH / ПРЕДУПРЕЖДЕНИЕ';
    } else if (isEn) {
      title = isCritical ? 'CRITICAL ALERT' : 'WARNING';
    } else if (isRu) {
      title = isCritical ? 'ОПАСНОСТЬ!' : 'ПРЕДУПРЕЖДЕНИЕ';
    } else {
      title = isCritical ? 'XAVF!' : 'OGOHLANTIRISH';
    }

    final callLabel = isEn
        ? 'Call vet${vetName != null ? ' · $vetName' : ''}'
        : (isRu
            ? 'Позвонить ветеринару${vetName != null ? ' · $vetName' : ''}'
            : "Veterinarga qo'ng'iroq${vetName != null ? ' · $vetName' : ''}");

    final canCall = onCallVet != null || (vetPhone != null && vetPhone!.isNotEmpty);
    final tone = isCritical ? Tone.danger : Tone.warning;

    return NoticeBanner(
      tone: tone,
      icon: Icons.warning_amber_rounded,
      title: title,
      message: message,
      actions: [
        if (canCall)
          FilledButton.icon(
            onPressed: onCallVet ??
                () => const ExternalActions().callPhone(context, vetPhone!),
            style: FilledButton.styleFrom(
              backgroundColor: tone.foreground,
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.phone_in_talk, size: 18),
            label: Text(callLabel),
          ),
      ],
    );
  }
}
