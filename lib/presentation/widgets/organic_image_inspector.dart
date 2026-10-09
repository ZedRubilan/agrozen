import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';

/// An organic, friendly inspection animation that plays over an uploaded photo
/// while AI is processing the image.
///
/// Avoids sci-fi neon grids or cyberpunk aesthetics. Instead, it features a warm,
/// natural magnifying focus lens that glides across the photo, pulsing inspection
/// focus nodes, and multilingual progressive status stages.
class OrganicImageInspector extends StatefulWidget {
  final String imagePath;
  final String language;
  final bool isAnalyzing;
  final VoidCallback? onCancel;

  const OrganicImageInspector({
    super.key,
    required this.imagePath,
    this.language = 'uz',
    this.isAnalyzing = true,
    this.onCancel,
  });

  @override
  State<OrganicImageInspector> createState() => _OrganicImageInspectorState();
}

class _OrganicImageInspectorState extends State<OrganicImageInspector>
    with TickerProviderStateMixin {
  late AnimationController _lensController;
  late AnimationController _pulseController;
  late Animation<Offset> _lensPosition;
  int _currentStageIndex = 0;

  @override
  void initState() {
    super.initState();

    // Smooth gliding lens controller
    _lensController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _lensPosition = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(-0.25, -0.2), end: const Offset(0.2, -0.15))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0.2, -0.15), end: const Offset(0.1, 0.25))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0.1, 0.25), end: const Offset(-0.2, 0.15))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_lensController);

    // Subtle breathing pulse for inspection nodes
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _cycleStages();
  }

  void _cycleStages() async {
    while (mounted && widget.isAnalyzing) {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted || !widget.isAnalyzing) break;
      setState(() {
        _currentStageIndex = (_currentStageIndex + 1) % 4;
      });
    }
  }

  @override
  void dispose() {
    _lensController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getStageIcon(int stage) {
    switch (stage) {
      case 0:
        return Icons.camera_alt_outlined;
      case 1:
        return Icons.search_rounded;
      case 2:
        return Icons.analytics_outlined;
      case 3:
      default:
        return Icons.verified_outlined;
    }
  }

  String _getStageText(int stage) {
    final lang = widget.language;
    switch (stage) {
      case 0:
        return AppStrings.tr(
          lang: lang,
          uz: "Surat qabul qilindi va tayyorlanmoqda...",
          ru: "Фотография принята в обработку...",
          en: "Photo received and calibrating...",
        );
      case 1:
        return AppStrings.tr(
          lang: lang,
          uz: "Jo'jalar holati va to'shama namligi ko'rilmoqda...",
          ru: "Осмотр оперения и влажности подстилки...",
          en: "Inspecting plumage and litter moisture...",
        );
      case 2:
        return AppStrings.tr(
          lang: lang,
          uz: "Ross-308 va Cobb-500 me'yorlari bilan tekshirilmoqda...",
          ru: "Сверка со стандартами Ross-308 и Cobb-500...",
          en: "Cross-referencing Ross-308 / Cobb-500 standards...",
        );
      case 3:
      default:
        return AppStrings.tr(
          lang: lang,
          uz: "Tahlil va xavfsiz tavsiyalar tuzilmoqda...",
          ru: "Формирование безопасных рекомендаций...",
          en: "Compiling actionable veterinary guidance...",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The image with the animated inspection lens
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.file(
                  File(widget.imagePath),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  ),
                ),
              ),

              // Soft vignette overlay
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(30),
                      Colors.transparent,
                      Colors.black.withAlpha(60),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Cancel button
              if (widget.onCancel != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),

              // Gliding Organic Focus Lens
              if (widget.isAnalyzing)
                AnimatedBuilder(
                  animation: Listenable.merge([_lensController, _pulseController]),
                  builder: (context, child) {
                    final pos = _lensPosition.value;
                    final pulseScale = 1.0 + (_pulseController.value * 0.08);

                    return Align(
                      alignment: Alignment(pos.dx * 2, pos.dy * 2),
                      child: Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5A338), // warm honey gold
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE5A338).withAlpha(120),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Translucent warm lens tint
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withAlpha(35),
                                ),
                              ),
                              // Friendly center crosshair / leaf glyph
                              Icon(
                                Icons.eco_rounded,
                                size: 24,
                                color: Colors.white.withAlpha(220),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Warm inspection chip badge
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.tr(
                          lang: widget.language,
                          uz: "AgroZen Tahlilchisi",
                          ru: "Анализатор AgroZen",
                          en: "AgroZen Vision",
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progressive status text & bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    key: ValueKey<int>(_currentStageIndex),
                    children: [
                      Icon(_getStageIcon(_currentStageIndex), size: 18, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getStageText(_currentStageIndex),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ((_currentStageIndex + 1) / 4.0),
                    minHeight: 6,
                    backgroundColor: primary.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
