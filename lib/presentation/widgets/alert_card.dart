import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../domain/alerts/alert_models.dart';
import '../../services/external_actions.dart';

class AlertCard extends StatelessWidget {
  final String message;
  final AlertSeverity severity;
  final String? vetPhone;
  final String? vetName;
  final String locale;
  final VoidCallback? onCallVet;

  const AlertCard({
    super.key,
    required this.message,
    this.severity = AlertSeverity.warning,
    this.vetPhone,
    this.vetName,
    this.locale = 'uz',
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
        ? (alert.messageEn ?? alert.messageRu ?? 'Warning: Parameters deviated from target norms!')
        : (lower == 'ru'
            ? (alert.messageRu ?? 'Внимание: показатели отклонились от нормы!')
            : (alert.messageUz ?? "Diqqat: ko'rsatkichlar me'yordan chetga chiqdi!"));
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
    final isEn = locale == 'en';
    final isRu = locale == 'ru';
    final bgColor = isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isCritical ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D);
    final iconColor = isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final buttonColor = isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706);

    final headerTitle = isEn
        ? (isCritical ? 'CRITICAL RISK / EMERGENCY' : 'WARNING / HEALTH ALERT')
        : (isCritical ? 'XAVF! / ОПАСНОСТЬ!' : 'OGOHLANTIRISH / ПРЕДУПРЕЖДЕНИЕ');

    final callLabel = isEn
        ? (vetPhone != null ? "Call: $vetPhone" : "Call District Veterinarian")
        : (isRu
            ? (vetPhone != null ? "Звонок: $vetPhone" : "Позвонить ветеринару")
            : (vetPhone != null ? "Qo'ng'iroq: $vetPhone" : "Veterinarga qo'ng'iroq"));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCritical ? Icons.error_rounded : Icons.warning_amber_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    headerTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: iconColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (vetPhone != null || onCallVet != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCallVet ??
                      () async {
                        final phone = vetPhone;
                        if (phone != null && phone.isNotEmpty) {
                          await const ExternalActions()
                              .callPhone(context, phone);
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(isEn
                                ? "Contact Veterinarian"
                                : (isRu ? "Связаться с ветеринаром" : "Veterinar bilan bog'lanish")),
                            content: Text(
                              "${vetName ?? (isEn ? 'District Veterinarian' : (isRu ? 'Районный ветеринар' : 'Hududiy veterinar'))}\n"
                              "${isEn ? 'Phone' : (isRu ? 'Телефон' : 'Telefon')}: ${vetPhone ?? '+998 90 123 45 67'}",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(isEn ? "Close" : (isRu ? "Закрыть" : "Yopish")),
                              ),
                            ],
                          ),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 18),
                  label: Text(
                    callLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
