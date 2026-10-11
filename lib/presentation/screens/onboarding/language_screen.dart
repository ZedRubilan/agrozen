import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../widgets/agro_icons.dart';
import '../../widgets/tactile_button.dart';

/// Redesigned Welcome & Language Screen:
/// - Instantaneous entry (zero loading spinner).
/// - Payme-inspired big photographic hero showcase with interactive feature slides & progress dots.
/// - Crisp, uncropped 4:3 national flag badges (`AgroFlagBadge`) for O'zbekcha, Русский, and English.
/// - Bottom step progress dots (`1 / 4`) + primary CTA button with circular arrow badge.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with AppLanguageController {
  String _selectedLanguage = 'uz';
  int _activeSlideIndex = 0;

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selectedLanguage);
    if (!mounted) return;
    changeAppLanguage(_selectedLanguage);
    context.go('/onboarding/region');
  }

  void _nextHeroSlide() {
    setState(() {
      _activeSlideIndex = (_activeSlideIndex + 1) % 3;
    });
  }

  ({String badge, String title, String subtitle, String image}) _slideData(
    int index,
    String lang,
  ) {
    final isRu = lang == 'ru';
    final isEn = lang == 'en';
    switch (index) {
      case 1:
        return (
          badge: isRu
              ? 'ИИ-АССИСТЕНТ 24/7'
              : (isEn ? '24/7 VOICE & AI ADVISOR' : 'OVOZLI AI YORDAMCHI'),
          title: isRu
              ? 'Умный голосовой помощник и диагностика стада'
              : (isEn
                  ? 'Natural Voice AI & Instant Flock Diagnostics'
                  : "Tabiiy ovozli AI va tezkor parrandachilik tahlili"),
          subtitle: isRu
              ? 'Спрашивайте голосом в птичнике — получайте точные ответы по Ross-308'
              : (isEn
                  ? 'Hands-free voice guidance and real-time regional weather alerts'
                  : "Parrandaxonada ovoz orqali so'rang va aniq tavsiyalar oling"),
          image: 'assets/images/broiler_flock.jpg',
        );
      case 2:
        return (
          badge: isRu
              ? 'АГРОКРЕДИТ И СЕРТИФИКАТ'
              : (isEn ? 'ACADEMY & LOAN TRACKER' : 'AGROKREDIT VA SERTIFIKAT'),
          title: isRu
              ? 'Академия фермера и расчет чистой прибыли'
              : (isEn
                  ? '5-Module Academy & Bank Loan Profit Tracker'
                  : "5 modulli akademiya, sertifikat va sof foyda hisobi"),
          subtitle: isRu
              ? 'Пройдите экспресс-курс и получите верифицированный сертификат'
              : (isEn
                  ? 'Complete the course to unlock your verified farmer certificate'
                  : "Kursni yakunlab, imtiyozli kredit uchun sertifikatga ega bo'ling"),
          image: 'assets/images/chick_starter.jpg',
        );
      case 0:
      default:
        return (
          badge: isRu
              ? 'ДОБРО ПОЖАЛОВАТЬ В AGROZEN'
              : (isEn ? 'WELCOME TO AGROZEN' : 'AGROZENGA XUSH KELIBSIZ'),
          title: isRu
              ? 'Цифровая экосистема для вашей птицефермы'
              : (isEn
                  ? 'Next-Gen Smart Poultry Farming Companion'
                  : "Zamonaviy parrandachilik va 42 kunlik aqlli nazorat"),
          subtitle: isRu
              ? 'Микроклимат по геолокации, дневник партии и нормы Ross-308'
              : (isEn
                  ? 'Live GPS microclimate, flock diary & Ross-308 growth standards'
                  : "Geolokatsiya ob-havosi, partiya kundaligi va Ross-308 me'yorlari"),
          image: 'assets/images/sunset_farm.jpg',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slideData(_activeSlideIndex, _selectedLanguage);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Payme-Inspired Big Photographic Welcome Hero Card
                  GestureDetector(
                    onTap: _nextHeroSlide,
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -120) {
                        setState(
                          () => _activeSlideIndex = (_activeSlideIndex + 1) % 3,
                        );
                      } else if (v > 120) {
                        setState(
                          () => _activeSlideIndex = (_activeSlideIndex + 2) % 3,
                        );
                      }
                    },
                    child: Container(
                      height: 184,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B2214).withAlpha(45),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Photographic Slide Background
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              child: Image.asset(
                                slide.image,
                                key: ValueKey<String>(slide.image),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xFF0F2E1C),
                                ),
                              ),
                            ),

                            // Rich Cinematic Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF071A0E).withAlpha(155),
                                    const Color(0xFF071A0E).withAlpha(80),
                                    const Color(0xFF071A0E).withAlpha(235),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),

                            // Hero Content: Brand Header + Headline + Slide Dots & Little Arrow
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Rounded Photographic Logo + Step Progress Pill
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const AgroChickIcon(size: 34),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'AgroZen',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              Text(
                                                slide.badge,
                                                style: const TextStyle(
                                                  color: Color(0xFF6EE7B7),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(90),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                          border: Border.all(
                                            color: Colors.white.withAlpha(40),
                                          ),
                                        ),
                                        child: const Text(
                                          '1 / 4',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Animated Headline & Subtitle
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Column(
                                      key: ValueKey<String>(
                                        '${_activeSlideIndex}_$_selectedLanguage',
                                      ),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slide.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            height: 1.18,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          slide.subtitle,
                                          style: TextStyle(
                                            color: Colors.white.withAlpha(215),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.25,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Bottom Row inside Hero: Interactive Slide Dots + Little Arrow Button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AgroProgressDots(
                                        currentStep: _activeSlideIndex,
                                        totalSteps: 3,
                                        activeColor: const Color(0xFF4ADE80),
                                        inactiveColor:
                                            Colors.white.withAlpha(80),
                                        onDotTapped: (idx) => setState(
                                          () => _activeSlideIndex = idx,
                                        ),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(35),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withAlpha(70),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Section Header (preserves test finder while looking clean & modern)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tilni tanlang\nВыберите язык\nSelect Language',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.18,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.translate_rounded,
                              size: 14,
                              color: Color(0xFF15803D),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'UZ • RU • EN',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3. Modern Language Cards with Uncropped 4:3 Vector Flags
                  _buildModernLanguageCard(
                    code: 'uz',
                    title: "O'zbekcha",
                    subtitle: "O'zbek tili (Lotin)",
                    tag: 'UZB',
                    isSelected: _selectedLanguage == 'uz',
                  ),
                  const SizedBox(height: 8),
                  _buildModernLanguageCard(
                    code: 'ru',
                    title: 'Русский',
                    subtitle: 'На русском языке',
                    tag: 'RUS',
                    isSelected: _selectedLanguage == 'ru',
                  ),
                  const SizedBox(height: 8),
                  _buildModernLanguageCard(
                    code: 'en',
                    title: 'English',
                    subtitle: 'International English',
                    tag: 'ENG',
                    isSelected: _selectedLanguage == 'en',
                  ),
                  const SizedBox(height: 12),

                  // 4. Bottom Onboarding Progress Bar + Arrow Continue Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2EBE4)),
                        ),
                        child: const AgroProgressDots(
                          currentStep: 0,
                          totalSteps: 4,
                          activeColor: Color(0xFF15803D),
                          inactiveColor: Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TactileButton(
                          height: 50,
                          depth: 3,
                          borderRadius: 18,
                          backgroundColor: const Color(0xFF15803D),
                          shadowColor: const Color(0xFF0F5328),
                          onPressed: _proceed,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Davom etish / Далее / Continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.1,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernLanguageCard({
    required String code,
    required String title,
    required String subtitle,
    required String tag,
    required bool isSelected,
  }) {
    const primary = Color(0xFF15803D);

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2.2 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primary.withAlpha(24)
                  : Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Uncropped 4:3 National Flag Badge
            AgroFlagBadge(code: code, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? const Color(0xFF0F5328)
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withAlpha(25)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isSelected ? primary : const Color(0xFFCBD5E1),
                  width: 1.8,
                ),
              ),
              child: Icon(
                isSelected
                    ? Icons.check_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: isSelected ? 16 : 11,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

