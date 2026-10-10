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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mascot bobbing animation with speech bubble
              Center(
                child: Column(
                  children: [
                    // Animated Speech bubble
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<String>(_selectedLanguage),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D7A4C), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _mascotGreeting,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Bobbing chick mascot with warm shadow
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.88 + (value * 0.12),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100.withAlpha(140),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade300.withAlpha(60),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const AgroChickIcon(size: 46),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tilni tanlang\nВыберите язык\nSelect Language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "AgroZen ilovasidan qaysi tilda foydalanmoqchisiz?\nВыберите язык / Choose language",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),

              // Chunky Tactile Language Cards
              _buildTactileLanguageCard(
                code: 'uz',
                title: "O'zbekcha",
                subtitle: "Lotin yozuvida",
                isSelected: _selectedLanguage == 'uz',
              ),
              const SizedBox(height: 10),
              _buildTactileLanguageCard(
                code: 'ru',
                title: "Русский",
                subtitle: "На русском языке",
                isSelected: _selectedLanguage == 'ru',
              ),
              const SizedBox(height: 10),
              _buildTactileLanguageCard(
                code: 'en',
                title: "English",
                subtitle: "International English",
                isSelected: _selectedLanguage == 'en',
              ),
              const SizedBox(height: 20),

              // Tactile 3D Proceed Button
              TactileButton(
                height: 54,
                depth: 3,
                borderRadius: 16,
                backgroundColor: theme.colorScheme.primary,
                shadowColor: const Color(0xFF1B5E20),
                onPressed: _proceed,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Davom etish / Далее / Continue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
            AgroFlagBadge(code: code, size: 40),
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
              duration: const Duration(milliseconds: 160),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primary : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

