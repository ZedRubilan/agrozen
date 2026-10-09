import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> with AppLanguageController {
  String _selectedLanguage = 'uz';

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selectedLanguage);
    if (!mounted) return;
    changeAppLanguage(_selectedLanguage);
    context.go('/onboarding/region');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.language, size: 30, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tilni tanlang\nВыберите язык\nSelect Language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "AgroZen ilovasidan qaysi tilda foydalanmoqchisiz?\nВыберите язык / Choose language",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.25),
              ),
              const SizedBox(height: 16),
              _buildLanguageCard(
                code: 'uz',
                title: "O'zbekcha",
                subtitle: "Lotin yozuvida",
                flag: "🇺🇿",
                isSelected: _selectedLanguage == 'uz',
              ),
              const SizedBox(height: 12),
              _buildLanguageCard(
                code: 'ru',
                title: "Русский",
                subtitle: "На русском языке",
                flag: "🇷🇺",
                isSelected: _selectedLanguage == 'ru',
              ),
              const SizedBox(height: 10),
              _buildLanguageCard(
                code: 'en',
                title: "English",
                subtitle: "International English",
                flag: "🇬🇧",
                isSelected: _selectedLanguage == 'en',
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Davom etish / Далее / Continue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String code,
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _selectedLanguage = code),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.primary : Colors.black87,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
