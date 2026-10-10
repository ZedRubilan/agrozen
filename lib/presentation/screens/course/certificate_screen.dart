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
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: Text(
          AppStrings.tr(
            lang: _lang,
            uz: 'Tayyorgarlik sertifikati',
            ru: 'Сертификат готовности',
            en: 'Readiness Certificate',
          ),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Certificate Paper Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD4AF37).withAlpha(120), width: 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFDE68A), Color(0xFFD4AF37), Color(0xFF92400E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withAlpha(100),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.workspace_premium_rounded, size: 38, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'SERTIFIKAT / CERTIFICATE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Color(0xFF8B6508),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'AgroZen AI Training Program',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Divider(height: 22, thickness: 1.2, color: Color(0xFFD4AF37)),
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: 'Ushbu sertifikat tasdiqlaydiki,',
                              ru: 'Настоящим подтверждается, что',
                              en: 'This certificate confirms that',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _farmerName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppStrings.tr(
                                lang: _lang,
                                uz: '$_district viloyati',
                                ru: '$_district область',
                                en: '$_district region',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: "broyler jo'jalarini yetishtirish texnologiyasi, biologik xavfsizlik va parvarishlash me'yorlari bo'yicha tayyorgarlik kursini muvaffaqiyatli yakunladi.",
                              ru: 'успешно освоил(а) вводный курс по технологии выращивания цыплят-бройлеров, биобезопасности и стандартам содержания.',
                              en: 'has successfully completed the introductory training on broiler flock management, biosecurity protocols, and welfare standards.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF5ED),
                                  border: Border.all(color: const Color(0xFF2D7A4C)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF2D7A4C)),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppStrings.tr(
                                        lang: _lang,
                                        uz: 'TASDIQLANGAN',
                                        ru: 'ПОДТВЕРЖДЕНО',
                                        en: 'VERIFIED',
                                      ),
                                      style: const TextStyle(color: Color(0xFF2D7A4C), fontSize: 10, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TactileButton(
                    height: 56,
                    depth: 4,
                    borderRadius: 18,
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
                        const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.tr(
                            lang: _lang,
                            uz: 'Ulashish / Saqlash',
                            ru: 'Поделиться / Сохранить сертификат',
                            en: 'Share / Save Certificate',
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
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
