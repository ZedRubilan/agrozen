import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final isRu = _lang == 'ru';
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Сертификат готовности' : 'Tayyorgarlik sertifikati'),
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
                      borderRadius: BorderRadius.circular(16),
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
                          'SERTIFIKAT / СЕРТИФИКАТ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Color(0xFF8B6508),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'AgroZen AI Ta\'lim Dasturi',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const Divider(height: 32, thickness: 1.5, color: Color(0xFFD4AF37)),
                        Text(
                          isRu ? 'Настоящим подтверждается, что' : 'Ushbu sertifikat tasdiqlaydiki,',
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
                          isRu
                              ? 'успешно освоил(а) вводный курс по технологии выращивания цыплят-бройлеров, биобезопасности и стандартам содержания.'
                              : "broyler jo'jalarini yetishtirish texnologiyasi, biologik xavfsizlik va parvarishlash me'yorlari bo'yicha tayyorgarlik kursini muvaffaqiyatli yakunladi.",
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
                                const Text('Sana / Дата:', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRu
                                ? 'Сертификат готов к экспорту для банка или партнёров'
                                : "Sertifikat bank yoki hamkorlar uchun eksportga tayyor",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: Text(
                      isRu ? 'Поделиться / Сохранить сертификат' : 'Ulashish / Saqlash',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
