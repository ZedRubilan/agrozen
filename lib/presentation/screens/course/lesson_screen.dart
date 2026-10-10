import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/external_actions.dart';
import '../../widgets/tactile_button.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'uz';
    if (!mounted) return;
    setState(() {
      _lang = lang;
      _isLoading = false;
    });
    _loadRichJsonLesson(lang);
  }

  Future<void> _loadRichJsonLesson(String lang) async {
    final folder = lang == 'ru' ? 'ru' : 'uz';
    try {
      final raw = await rootBundle.loadString(
        'knowledge/course/$folder/lesson_${widget.lessonId}.json',
      );
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        if (lang != 'en') {
          _jsonDetailContent = map['content'] as String?;
        }
        _videoUrl = map['video_url'] as String?;
      });
    } catch (_) {
      // Fallback gracefully if asset cannot be loaded in isolated test environments.
    }
  }

  String _defaultVideoUrlForLesson(int id) {
    switch (id) {
      case 1:
        return 'https://www.youtube.com/results?search_query=ross+308+broiler+barn+preparation+disinfection+preheating';
      case 2:
        return 'https://www.youtube.com/results?search_query=ross+308+broiler+chicks+first+3+days+crop+fill';
      case 3:
        return 'https://www.youtube.com/results?search_query=ross+308+broiler+temperature+ventilation+management';
      case 4:
        return 'https://www.youtube.com/results?search_query=ross+308+broiler+starter+grower+finisher+feeding';
      default:
        return 'https://www.youtube.com/results?search_query=ross+308+broiler+biosecurity+disease+prevention';
    }
  }

  Map<String, String> _getLessonContent(int id, String lang) {
    switch (id) {
      case 1:
        if (lang == 'en') {
          return {
            'title': 'Pre-Placement Barn Preparation',
            'content': 'Before broiler chicks arrive, the barn must be completely cleaned, washed, and disinfected.\n\n'
                '• Preheat the barn to 33-34°C at least 24 hours in advance.\n'
                '• Spread dry wood shavings 5-7 cm deep.\n'
                '• Fill nipple or bell drinkers with fresh, clean water.\n'
                '• Provide 23 hours of light during the initial brooding days.',
          };
        } else if (lang == 'ru') {
          return {
            'title': 'Подготовка помещения до завоза',
            'content': 'Перед приёмом партии бройлеров птичник должен быть тщательно очищен, вымыт и продезинфицирован.\n\n'
                '• За 24 часа прогрейте помещение до 33-34°C.\n'
                '• Насыпьте сухую стружку толщиной 5-7 см.\n'
                '• Установите ниппельные или вакуумные поилки и проверьте подачу воды.\n'
                '• Обеспечьте круглосуточное освещение (23 часа) в первые дни.',
          };
        } else {
          return {
            'title': "Jo'jalar kelishidan oldin xonani tayyorlash",
            'content': "Broyler jo'jalari kelishidan oldin bino to'liq tozalangan, yuvilgan va dezinfeksiya qilingan bo'lishi shart.\n\n"
                "• 24 soat oldin xonani 33-34°C gacha qizdiring.\n"
                "• Qalinligi 5-7 sm quruq yog'och qirindisi (to'shama) to'shang.\n"
                "• Suv idishlarini (nippel yoki vakuum) toza suv bilan to'ldiring.\n"
                "• Dastlabki kunlarda 23 soatlik yorug'lik rejimini ta'minlang.",
          };
        }
      case 2:
        if (lang == 'en') {
          return {
            'title': 'First 3 Days: Critical Phase',
            'content': 'The first 72 hours determine the survival and growth of the entire flock.\n\n'
                '• Check crop fill after 8 hours: at least 80% of chicks must have feed and water.\n'
                '• Water temperature should be warm (20-22°C).\n'
                '• If chicks huddle together — they are cold. If panting with open beaks — too hot.',
          };
        } else if (lang == 'ru') {
          return {
            'title': 'Первые 3 дня цыплят',
            'content': 'Первые 72 часа определяют выживаемость всей партии.\n\n'
                '• Проверьте зоб цыплят через 8 часов: 80% должны быть с кормом и водой.\n'
                '• Вода должна быть тёплой (20-22°C).\n'
                '• Если цыплята сбиваются в кучу — им холодно. Если тяжело дышат и раскрывают клювы — жарко.',
          };
        } else {
          return {
            'title': "Dastlabki 3 kun: hal qiluvchi davr",
            'content': "Dastlabki 72 soat butun partiyaning yashovchanligini belgilaydi.\n\n"
                "• 8 soatdan keyin jig'ildonni tekshiring: 80% jo'jalarda yem va suv bo'lishi shart.\n"
                "• Suv iliq (20-22°C) bo'lishi kerak.\n"
                "• Agar jo'jalar to'planib olsa — sovuq. Agar og'zini ochib hansirasa — issiq.",
          };
        }
      case 3:
        if (lang == 'en') {
          return {
            'title': 'Temperature & Ventilation Control',
            'content': 'Target brooding temperatures:\n\n'
                '• Days 1-3: 33-34°C\n'
                '• Days 4-7: 32°C\n'
                '• Week 2: 29°C\n'
                '• Week 3: 27°C\n'
                '• Week 4+: 22-24°C\n\n'
                'Ventilation is vital: insufficient fresh air causes ammonia buildup and ascites (water belly).',
          };
        } else if (lang == 'ru') {
          return {
            'title': 'Температура и микроклимат',
            'content': 'Температурный график:\n\n'
                '• Дни 1-3: 33-34°C\n'
                '• Дни 4-7: 32°C\n'
                '• Неделя 2: 29°C\n'
                '• Неделя 3: 27°C\n'
                '• Неделя 4+: 22-24°C\n\n'
                'Вентиляция обязательна: недостаток свежего воздуха приводит к асциту (водянке) и замедлению роста.',
          };
        } else {
          return {
            'title': "Harorat va shamollatish",
            'content': "Harorat jadvali:\n\n"
                "• 1-3 kunlar: 33-34°C\n"
                "• 4-7 kunlar: 32°C\n"
                "• 2-hafta: 29°C\n"
                "• 3-hafta: 27°C\n"
                "• 4+ hafta: 22-24°C\n\n"
                "Shamollatish o'ta zarur: toza havoning yetishmasligi parrandada suv yig'ilishi (assit) va o'sish to'xtashiga olib keladi.",
          };
        }
      case 4:
        if (lang == 'en') {
          return {
            'title': 'Feed Phases & Nutrition',
            'content': 'Broiler nutrition consists of 3 essential phases:\n\n'
                '1. Starter (Days 1-10): 22-23% protein. Builds skeletal structure and immunity.\n'
                '2. Grower (Days 11-24): 20-21% protein. Rapid muscle mass development.\n'
                '3. Finisher (Days 25-42): 18-19% protein. Final fattening before harvest.',
          };
        } else if (lang == 'ru') {
          return {
            'title': 'Фазы кормления',
            'content': 'Кормление бройлеров состоит из 3 ключевых этапов:\n\n'
                '1. Старт (1-10 дни): протеин 22-23%. Закладывает скелет и иммунитет.\n'
                '2. Рост (11-24 дни): протеин 20-21%. Интенсивный набор мышечной массы.\n'
                '3. Финиш (25-42 дни): протеин 18-19%. Завершающий откорм перед забоем.',
          };
        } else {
          return {
            'title': "To'g'ri oziqlantirish fazalari",
            'content': "Broylerlarni oziqlantirish 3 muhim bosqichdan iborat:\n\n"
                "1. Start (1-10 kunlar): oqsil 22-23%. Skelet va immunitetni shakllantiradi.\n"
                "2. O'sish (11-24 kunlar): oqsil 20-21%. Mushak massasining jadal o'sishi.\n"
                "3. Finish (25-42 kunlar): oqsil 18-19%. So'yish oldidan yakuniy semirtirish.",
          };
        }
      default:
        if (lang == 'en') {
          return {
            'title': 'Diseases & Biosecurity Protocols',
            'content': 'The golden rule of poultry farming: prevention is vastly cheaper than treatment!\n\n'
                '• Strict biosecurity: disinfection mats at entrances, designated footwear.\n'
                '• If daily mortality exceeds 1%, immediately isolate the barn and call a veterinarian.\n'
                '• Never administer antibiotics without professional prescription.',
          };
        } else if (lang == 'ru') {
          return {
            'title': 'Болезни и ветеринария',
            'content': 'Главное правило птицевода: профилактика дешевле лечения!\n\n'
                '• Соблюдайте биобезопасность: дезковрик у входа, сменная обувь.\n'
                '• При падеже более 1% в сутки немедленно изолируйте птичник и звоните ветеринару.\n'
                '• Не используйте антибиотики без назначения специалиста.',
          };
        } else {
          return {
            'title': "Kasalliklar va veterinar bilan ishlash",
            'content': "Parrandachining asosiy qoidasi: kasallikning oldini olish davolashdan ancha arzon!\n\n"
                "• Biologik xavfsizlikka rioya qiling: dezbariyer, maxsus poyabzal.\n"
                "• Sutkalik nobodlik 1% dan oshsa, zudlik bilan hududni cheklang va veterinarga murojaat qiling.\n"
                "• Mutaxassis tavsiyasisiz antibiotiklarni aslo qo'llamang.",
          };
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _getLessonContent(widget.lessonId, _lang);
    final videoUrl = _videoUrl ?? _defaultVideoUrlForLesson(widget.lessonId);

    final lessonBadge = _lang == 'en'
        ? 'Lesson ${widget.lessonId}'
        : (_lang == 'ru' ? 'Урок ${widget.lessonId}' : '${widget.lessonId}-dars');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
                          ),
                          child: Text(
                            _lang == 'en'
                                ? 'PRACTICAL GUIDE'
                                : (_lang == 'ru' ? 'ПРАКТИЧЕСКОЕ РУКОВОДСТВО' : 'AMALIY TAVSIYA'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => const ExternalActions().openVideo(context, videoUrl),
                          icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: Color(0xFFDC2626)),
                          label: Text(
                            _lang == 'en'
                                ? 'Watch Video Guide'
                                : (_lang == 'ru' ? 'Смотреть видеоурок' : "Videodarsni ko'rish"),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['title']!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['content']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.65,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_jsonDetailContent != null && _jsonDetailContent!.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                const SizedBox(height: 14),
                                Text(
                                  _lang == 'ru' ? 'Подробный стандарт Ross-308:' : 'Batafsil Ross-308 standarti:',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _jsonDetailContent!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TactileButton(
                      height: 56,
                      depth: 4,
                      borderRadius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      shadowColor: const Color(0xFF1B4E31),
                      onPressed: () => context.push('/course/${widget.lessonId}/quiz'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            _lang == 'en'
                                ? 'Take Lesson Quiz'
                                : (_lang == 'ru' ? 'Пройти тест урока' : 'Dars testini topshirish'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 18),
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
