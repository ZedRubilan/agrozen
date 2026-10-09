import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_strings.dart';
import '../../widgets/tactile_button.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  String _farmerName = 'Fermer';
  String _district = 'Toshkent';
  String _lang = 'uz';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _farmerName = prefs.getString('farmer_name') ?? 'Fermer';
      _district = prefs.getString('farmer_district') ?? 'Toshkent';
      _lang = prefs.getString('app_language') ?? 'uz';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.tr(
            lang: _lang,
            uz: 'Tayyorgarlik sertifikati',
            ru: 'Сертификат готовности',
            en: 'Readiness Certificate',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Certificate Paper Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 64, color: Color(0xFFD4AF37)),
                        const SizedBox(height: 12),
                        const Text(
                          'SERTIFIKAT / CERTIFICATE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Color(0xFF8B6508),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'AgroZen AI Training Program',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const Divider(height: 32, thickness: 1.5, color: Color(0xFFD4AF37)),
                        Text(
                          AppStrings.tr(
                            lang: _lang,
                            uz: 'Ushbu sertifikat tasdiqlaydiki,',
                            ru: 'Настоящим подтверждается, что',
                            en: 'This certificate confirms that',
                          ),
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _farmerName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_district viloyati',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.tr(
                            lang: _lang,
                            uz: "broyler jo'jalarini yetishtirish texnologiyasi, biologik xavfsizlik va parvarishlash me'yorlari bo'yicha tayyorgarlik kursini muvaffaqiyatli yakunladi.",
                            ru: 'успешно освоил(а) вводный курс по технологии выращивания цыплят-бройлеров, биобезопасности и стандартам содержания.',
                            en: 'has successfully completed the introductory training on broiler flock management, biosecurity protocols, and welfare standards.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr(
                                    lang: _lang,
                                    uz: 'Sana:',
                                    ru: 'Дата:',
                                    en: 'Date:',
                                  ),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'TASDIQLANGAN',
                                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TactileButton(
                    height: 52,
                    depth: 3,
                    borderRadius: 16,
                    backgroundColor: const Color(0xFF2D7A4C),
                    shadowColor: const Color(0xFF1B4E31),
                    onPressed: () async {
                      final text = AppStrings.tr(
                        lang: _lang,
                        uz: "AgroZen — Tayyorgarlik sertifikati\n"
                            "Fermer: $_farmerName ($_district)\n"
                            "Broyler yetishtirish bo'yicha tayyorgarlik kursi yakunlandi. Sana: $dateStr",
                        ru: 'AgroZen — Сертификат готовности\n'
                            'Фермер: $_farmerName ($_district)\n'
                            'Подтверждает прохождение вводного курса по бройлерам. Дата: $dateStr',
                        en: 'AgroZen — Readiness Certificate\n'
                            'Farmer: $_farmerName ($_district)\n'
                            'Completed broiler farming readiness training. Date: $dateStr',
                      );
                      try {
                        await Share.share(text);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.tr(
                                lang: _lang,
                                uz: "Ulashish oynasini ochib bo'lmadi.",
                                ru: 'Не удалось открыть окно отправки.',
                                en: 'Could not open share dialog.',
                              ),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.tr(
                            lang: _lang,
                            uz: 'Ulashish / Saqlash',
                            ru: 'Поделиться / Сохранить сертификат',
                            en: 'Share / Save Certificate',
                          ),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
