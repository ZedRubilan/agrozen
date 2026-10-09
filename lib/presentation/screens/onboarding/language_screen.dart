import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../widgets/agro_icons.dart';
import '../../widgets/tactile_button.dart';

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

  String get _mascotGreeting {
    if (_selectedLanguage == 'ru') return 'Привет! На каком языке общаемся?';
    if (_selectedLanguage == 'en') return 'Hello! Which language do you prefer?';
    return 'Salom! Qaysi tilda gaplashamiz?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mascot bobbing animation with speech bubble
              Center(
                child: Column(
                  children: [
                    // Speech bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2D7A4C), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _mascotGreeting,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Bobbing chick mascot
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.85 + (value * 0.15),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                        child: const AgroChickIcon(size: 42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tilni tanlang\nВыберите язык\nSelect Language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "AgroZen ilovasidan qaysi tilda foydalanmoqchisiz?\nВыберите язык / Choose language",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Chunky Tactile Language Cards
              _buildTactileLanguageCard(
                code: 'uz',
                title: "O'zbekcha",
                subtitle: "Lotin yozuvida",
                isSelected: _selectedLanguage == 'uz',
              ),
              const SizedBox(height: 9),
              _buildTactileLanguageCard(
                code: 'ru',
                title: "Русский",
                subtitle: "На русском языке",
                isSelected: _selectedLanguage == 'ru',
              ),
              const SizedBox(height: 9),
              _buildTactileLanguageCard(
                code: 'en',
                title: "English",
                subtitle: "International English",
                isSelected: _selectedLanguage == 'en',
              ),
              const SizedBox(height: 16),

              // Tactile 3D Proceed Button
              TactileButton(
                height: 52,
                depth: 3,
                borderRadius: 16,
                backgroundColor: theme.colorScheme.primary,
                shadowColor: const Color(0xFF1B5E20),
                onPressed: _proceed,
                child: const Text(
                  'Davom etish / Далее / Continue',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTactileLanguageCard({
    required String code,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFCBD5E1),
              offset: Offset(0, isSelected ? 4 : 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            AgroFlagBadge(code: code, size: 38),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primary : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

