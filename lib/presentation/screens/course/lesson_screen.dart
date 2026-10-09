import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String _lang = 'uz';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _isLoading = false;
    });
  }

  Map<String, String> _getLessonContent(int id, bool isRu) {
    switch (id) {
      case 1:
        return {
          'title': isRu ? 'Подготовка помещения до завоза' : "Jo'jalar kelishidan oldin xonani tayyorlash",
          'content': isRu
              ? 'Перед приёмом партии бройлеров птичник должен быть тщательно очищен, вымыт и продезинфицирован.\n\n'
                '• За 24 часа прогрейте помещение до 33-34°C.\n'
                '• Насыпьте сухую стружку толщиной 5-7 см.\n'
                '• Установите ниппельные или вакуумные поилки и проверьте подачу воды.\n'
                '• Обеспечьте круглосуточное освещение (23 часа) в первые дни.'
              : "Broyler jo'jalari kelishidan oldin bino to'liq tozalangan, yuvilgan va dezinfeksiya qilingan bo'lishi shart.\n\n"
                "• 24 soat oldin xonani 33-34°C gacha qizdiring.\n"
                "• Qalinligi 5-7 sm quruq yog'och qirindisi (to'shama) to'shang.\n"
                "• Suv idishlarini (nippel yoki vakuum) toza suv bilan to'ldiring.\n"
                "• Dastlabki kunlarda 23 soatlik yorug'lik rejimini ta'minlang.",
        };
      case 2:
        return {
          'title': isRu ? 'Первые 3 дня цыплят' : "Dastlabki 3 kun: hal qiluvchi davr",
          'content': isRu
              ? 'Первые 72 часа определяют выживаемость всей партии.\n\n'
                '• Проверьте зоб цыплят через 8 часов: 80% должны быть с кормом и водой.\n'
                '• Вода должна быть тёплой (20-22°C).\n'
                '• Если цыплята сбиваются в кучу — им холодно. Если тяжело дышат и раскрывают клювы — жарко.'
              : "Dastlabki 72 soat butun partiyaning yashovchanligini belgilaydi.\n\n"
                "• 8 soatdan keyin jig'ildonni tekshiring: 80% jo'jalarda yem va suv bo'lishi shart.\n"
                "• Suv iliq (20-22°C) bo'lishi kerak.\n"
                "• Agar jo'jalar to'planib olsa — sovuq. Agar og'zini ochib hansirasa — issiq.",
        };
      case 3:
        return {
          'title': isRu ? 'Температура и микроклимат' : "Harorat va shamollatish",
          'content': isRu
              ? 'Температурный график:\n\n'
                '• Дни 1-3: 33-34°C\n'
                '• Дни 4-7: 32°C\n'
                '• Неделя 2: 29°C\n'
                '• Неделя 3: 27°C\n'
                '• Неделя 4+: 22-24°C\n\n'
                'Вентиляция обязательна: недостаток свежего воздуха приводит к асциту (водянке) и замедлению роста.'
              : "Harorat jadvali:\n\n"
                "• 1-3 kunlar: 33-34°C\n"
                "• 4-7 kunlar: 32°C\n"
                "• 2-hafta: 29°C\n"
                "• 3-hafta: 27°C\n"
                "• 4+ hafta: 22-24°C\n\n"
                "Shamollatish o'ta zarur: toza havoning yetishmasligi parrandada suv yig'ilishi (assit) va o'sish to'xtashiga olib keladi.",
        };
      case 4:
        return {
          'title': isRu ? 'Фазы кормления' : "To'g'ri oziqlantirish fazalari",
          'content': isRu
              ? 'Кормление бройлеров состоит из 3 ключевых этапов:\n\n'
                '1. Старт (1-10 дни): протеин 22-23%. Закладывает скелет и иммунитет.\n'
                '2. Рост (11-24 дни): протеин 20-21%. Интенсивный набор мышечной массы.\n'
                '3. Финиш (25-42 дни): протеин 18-19%. Завершающий откорм перед забоем.'
              : "Broylerlarni oziqlantirish 3 muhim bosqichdan iborat:\n\n"
                "1. Start (1-10 kunlar): oqsil 22-23%. Skelet va immunitetni shakllantiradi.\n"
                "2. O'sish (11-24 kunlar): oqsil 20-21%. Mushak massasining jadal o'sishi.\n"
                "3. Finish (25-42 kunlar): oqsil 18-19%. So'yish oldidan yakuniy semirtirish.",
        };
      default:
        return {
          'title': isRu ? 'Болезни и ветеринария' : "Kasalliklar va veterinar bilan ishlash",
          'content': isRu
              ? 'Главное правило птицевода: профилактика дешевле лечения!\n\n'
                '• Соблюдайте биобезопасность: дезковрик у входа, сменная обувь.\n'
                '• При падеже более 1% в сутки немедленно изолируйте птичник и звоните ветеринару.\n'
                '• Не используйте антибиотики без назначения специалиста.'
              : "Parrandachining asosiy qoidasi: kasallikning oldini olish davolashdan ancha arzon!\n\n"
                "• Biologik xavfsizlikka rioya qiling: dezbariyer, maxsus poyabzal.\n"
                "• Sutkalik nobodlik 1% dan oshsa, zudlik bilan hududni cheklang va veterinarga murojaat qiling.\n"
                "• Mutaxassis tavsiyasisiz antibiotiklarni aslo qo'llamang.",
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';
    final data = _getLessonContent(widget.lessonId, isRu);

    return Scaffold(
      appBar: AppBar(
        title: Text('${isRu ? 'Урок' : 'Dars'} ${widget.lessonId}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      data['title']!,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            data['content']!,
                            style: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/course/${widget.lessonId}/quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.quiz_outlined),
                      label: Text(
                        isRu ? 'Пройти тест урока' : 'Dars testini topshirish',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
