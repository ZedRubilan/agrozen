import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/language_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _lang = 'uz';
  String _name = 'Fermer';
  String _district = 'Toshkent';
  int _currentCount = 500;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _name = prefs.getString('farmer_name') ?? 'Fermer';
      _district = prefs.getString('farmer_district') ?? 'Toshkent';
      _currentCount = prefs.getInt('current_count') ?? 500;
      _isLoading = false;
    });
  }

  Future<void> _changeLanguage(String newLang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLang);
    setState(() => _lang = newLang);
  }

  Future<void> _resetBatch() async {
    final isRu = _lang == 'ru';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRu ? 'Начать новую партию?' : 'Yangi partiya boshlash?'),
        content: Text(
          isRu
              ? 'Все текущие данные будут сброшены для запуска нового 42-дневного цикла.'
              : "Yangi 42 kunlik sikl boshlash uchun joriy ma'lumotlar qayta sozlanadi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isRu ? 'Отмена' : 'Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(isRu ? 'Да, начать' : 'Ha, boshlash'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('arrival_date');
      await prefs.remove('today_mortality');
      await prefs.remove('today_feed');
      await prefs.remove('last_weight');
      if (!mounted) return;
      context.go('/onboarding/batch');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRu = _lang == 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Настройки' : 'Sozlamalar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Section
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                          child: Icon(Icons.person, size: 32, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_district | $_currentCount ${isRu ? 'голов' : 'bosh'}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Language Setting
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: Text(isRu ? 'Язык интерфейса' : 'Ilova tili'),
                    trailing: LanguageSelector(
                      currentLanguage: _lang,
                      onLanguageChanged: _changeLanguage,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Reset batch
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
                    title: Text(isRu ? 'Начать новую партию' : 'Yangi partiya boshlash'),
                    subtitle: Text(
                      isRu ? 'Сбросить дату завоза и счетчики' : "Keltirilgan sana va hisoblagichlarni yangilash",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _resetBatch,
                  ),
                ),
                const SizedBox(height: 24),

                // About section
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 8),
                            Text('AgroZen MVP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRu
                              ? 'Версия 1.0.0\nРазработано специально для птицеводов Узбекистана в рамках программы поддержки агростартапов.'
                              : "Versiya 1.0.0\nO'zbekiston parrandachilari uchun maxsus ishlab chiqilgan sun'iy intellekt yordamchisi.",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
