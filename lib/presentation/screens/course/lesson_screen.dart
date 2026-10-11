import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/external_actions.dart';
import '../../widgets/tactile_button.dart';
import 'course_guide_data.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String _lang = 'uz';
  bool _isLoading = true;
  String? _jsonDetailContent;
  String? _videoUrl;
  bool _showDetailedNotes = false;

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = CourseGuideData.normalizeLang(
      prefs.getString('app_language') ?? 'uz',
    );
    if (!mounted) return;
    setState(() {
      _lang = lang;
      _isLoading = false;
    });
    _loadRichJsonLesson(lang);
  }

  Future<void> _loadRichJsonLesson(String lang) async {
    final folder = lang == 'en' ? 'en' : (lang == 'ru' ? 'ru' : 'uz');
    try {
      final raw = await rootBundle.loadString(
        'knowledge/course/$folder/lesson_${widget.lessonId}.json',
      );
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _jsonDetailContent = map['content'] as String?;
        _videoUrl = map['video_url'] as String?;
      });
    } catch (_) {
      // Fallback gracefully if asset cannot be loaded in isolated test environments.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final module = CourseGuideData.getModule(widget.lessonId, _lang);
    final videoUrl = _videoUrl ?? module.videoUrl;

    final lessonBadge = AppStrings.tr(
      lang: _lang,
      uz: '${widget.lessonId}-dars (5 tadan)',
      ru: 'Урок ${widget.lessonId} из 5',
      en: 'Lesson ${widget.lessonId} of 5',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: Text(
          lessonBadge,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.primary.withAlpha(50),
                            ),
                          ),
                          child: Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: '3 ASOSIY QOIDA',
                              ru: '3 ГЛАВНЫХ ПРАВИЛА',
                              en: '3 GOLDEN RULES',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              const ExternalActions().openVideo(context, videoUrl),
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          label: Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: "Videodarsni ko'rish",
                              ru: 'Смотреть видеоурок',
                              en: 'Watch Video Guide',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF52665A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 3 Scannable Rule Cards
                            ...module.keyPoints.map((point) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE2EBE4),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF5ED),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          point.icon,
                                          size: 20,
                                          color: const Color(0xFF15803D),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF15803D),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7),
                                                  ),
                                                  child: Text(
                                                    point.badge,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    point.title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              point.description,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: Color(0xFF334155),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            // Farmer Takeaway Box
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_rounded,
                                    color: Color(0xFFD97706),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      module.farmerTakeaway,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Optional Expandable Full Manual Text
                            InkWell(
                              onTap: () => setState(
                                () => _showDetailedNotes = !_showDetailedNotes,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE2EBE4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppStrings.tr(
                                            lang: _lang,
                                            uz: "Batafsil Ross-308 qo'llanmasi",
                                            ru: 'Подробная памятка Ross-308',
                                            en: 'Detailed Ross-308 Manual Note',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                        Icon(
                                          _showDetailedNotes
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                  .keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: const Color(0xFF15803D),
                                        ),
                                      ],
                                    ),
                                    if (_showDetailedNotes) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        _jsonDetailContent?.isNotEmpty == true
                                            ? _jsonDetailContent!
                                            : module.detailedNote,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          height: 1.55,
                                          color: Color(0xFF334155),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TactileButton(
                      height: 56,
                      depth: 4,
                      borderRadius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      shadowColor: const Color(0xFF1B4E31),
                      onPressed: () =>
                          context.push('/course/${widget.lessonId}/quiz'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.quiz_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: 'Dars testini topshirish',
                              ru: 'Пройти тест урока',
                              en: 'Take Lesson Quiz',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
