import 'package:flutter/material.dart';
import '../../domain/alerts/alert_models.dart';
import '../../services/external_actions.dart';

class AlertCard extends StatelessWidget {
  final String message;
  final AlertSeverity severity;
  final String? vetPhone;
  final String? vetName;
  final VoidCallback? onCallVet;

  const AlertCard({
    super.key,
    required this.message,
    this.severity = AlertSeverity.warning,
    this.vetPhone,
    this.vetName,
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
    final message = locale == 'ru'
        ? (alert.messageRu ?? 'Внимание: показатели отклонились от нормы!')
        : (alert.messageUz ?? "Diqqat: ko'rsatkichlar me'yordan chetga chiqdi!");
    return AlertCard(
      key: key,
      message: message,
      severity: alert.severity,
      vetPhone: vetPhone,
      vetName: vetName,
      onCallVet: onCallVet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == AlertSeverity.critical;
    final bgColor = isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1);
    final borderColor = isCritical ? Colors.red.shade700 : Colors.amber.shade800;
    final iconColor = isCritical ? Colors.red.shade700 : Colors.amber.shade800;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCritical ? Icons.error_rounded : Icons.warning_amber_rounded,
                  color: iconColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCritical ? 'XAVF! / ОПАСНОСТЬ!' : 'OGOHLANTIRISH / ПРЕДУПРЕЖДЕНИЕ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: iconColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade900,
                height: 1.4,
              ),
            ),
            if (vetPhone != null || onCallVet != null) ...[
              const SizedBox(height: 12),
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
                            title: const Text("Veterinar bilan bog'lanish"),
                            content: Text(
                              "${vetName ?? 'Hududiy veterinar'}\nTelefon: ${vetPhone ?? '+998 90 123 45 67'}",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Yopish"),
                              ),
                            ],
                          ),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCritical ? Colors.red.shade700 : Colors.amber.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 18),
                  label: Text(
                    vetPhone != null ? "Qo'ng'iroq: $vetPhone" : "Veterinarga qo'ng'iroq",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
