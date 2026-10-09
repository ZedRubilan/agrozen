import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizScreen extends StatefulWidget {
  final int lessonId;

  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String _lang = 'uz';
  int _selectedOption = -1;
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lang = prefs.getString('app_language') ?? 'uz');
  }

  Map<String, dynamic> _getQuizData(int id, bool isRu) {
    switch (id) {
      case 1:
        return {
          'question': isRu
              ? 'До какой температуры необходимо прогреть птичник за 24 часа до завоза цыплят?'
              : "Jo'jalar kelishidan 24 soat oldin xonani qanday haroratgacha qizdirish lozim?",
          'options': isRu
              ? ['20-22°C', '26-28°C', '33-34°C', '40°C']
              : ['20-22°C', '26-28°C', '33-34°C', '40°C'],
          'correct': 2,
        };
      case 2:
        return {
          'question': isRu
              ? 'Какой процент цыплят должен найти воду и корм в первые 8 часов?'
              : "Dastlabki 8 soat ichida jo'jalarning necha foizi suv va yemni topishi shart?",
          'options': isRu
              ? ['Не менее 80%', 'Около 40%', 'Не имеет значения', 'Только 20%']
              : ["Kamida 80%", 'Taxminan 40%', "Farqi yo'q", 'Faqat 20%'],
          'correct': 0,
        };
      case 3:
        return {
          'question': isRu
              ? 'К чему в первую очередь приводит отсутствие правильной вентиляции?'
              : "To'g'ri shamollatish yo'qligi birinchi navbatda nimaga olib keladi?",
          'options': isRu
              ? ['К улучшению аппетита', 'К накоплению аммиака и асциту (водянке)', 'К переохлаждению ног', 'Ни к чему']
              : ["Ishtaha ochilishiga", "Ammiak to'planishi va suv yig'ilishiga (assit)", "Oyoqlari sovushiga", "Hech narsaga"],
          'correct': 1,
        };
      case 4:
        return {
          'question': isRu
              ? 'Сколько основных фаз кормления используется при выращивании бройлеров?'
              : "Broylerlarni boqishda nechta asosiy oziqlantirish fazasi qo'llaniladi?",
          'options': isRu
              ? ['1 фаза', '3 фазы (Старт, Рост, Финиш)', '5 фаз', 'Фазы не нужны']
              : ['1 ta faza', "3 ta faza (Start, O'sish, Finish)", '5 ta faza', "Faza kerak emas"],
          'correct': 1,
        };
      default:
        return {
          'question': isRu
              ? 'Что необходимо сделать при превышении суточного падежа в 1%?'
              : "Sutkalik nobodlik 1% dan oshganda nima qilish zarur?",
          'options': isRu
              ? ['Самостоятельно дать антибиотики', 'Срочно изолировать птичник и позвонить ветеринару', 'Просто подождать', 'Увеличить свет']
              : ["Mustaqil antibiotik berish", "Hududni darhol cheklab, veterinarga murojaat qilish", "Kutish", "Chiroqni kuchaytirish"],
          'correct': 1,
        };
    }
  }

  Future<void> _submitAnswer(int correct) async {
    setState(() {
      _submitted = true;
      _isCorrect = _selectedOption == correct;
    });

    if (_isCorrect) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('completed_lessons') ?? [];
      final idStr = widget.lessonId.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        await prefs.setStringList('completed_lessons', list);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';
    final quiz = _getQuizData(widget.lessonId, isRu);
    final options = quiz['options'] as List<String>;
    final correctIndex = quiz['correct'] as int;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isRu ? 'Тест: Урок' : 'Test: Dars'} ${widget.lessonId}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                quiz['question'] as String,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
              ),
              const SizedBox(height: 24),
              ...List.generate(options.length, (index) {
                final isSelected = _selectedOption == index;
                Color? tileColor;
                if (_submitted) {
                  if (index == correctIndex) {
                    tileColor = Colors.green.shade100;
                  } else if (isSelected && !_isCorrect) {
                    tileColor = Colors.red.shade100;
                  }
                } else if (isSelected) {
                  tileColor = theme.colorScheme.primary.withAlpha(25);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: _submitted ? null : () => setState(() => _selectedOption = index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tileColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_off,
                            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              if (!_submitted)
                ElevatedButton(
                  onPressed: _selectedOption >= 0 ? () => _submitAnswer(correctIndex) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isRu ? 'Проверить ответ' : 'Javobni tekshirish',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: _isCorrect ? Colors.green : Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isCorrect
                                  ? (isRu ? 'Правильно! Урок успешно сдан.' : 'To\'g\'ri! Dars muvaffaqiyatli topshirildi.')
                                  : (isRu ? 'Неверно. Попробуйте еще раз!' : 'Noto\'g\'ri. Yana bir bor urinib ko\'ring!'),
                              style: TextStyle(
                                color: _isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_isCorrect) {
                          context.pop();
                        } else {
                          setState(() {
                            _submitted = false;
                            _selectedOption = -1;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _isCorrect ? (isRu ? 'Готово' : 'Yakunlash') : (isRu ? 'Попробовать снова' : 'Qayta urinish'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
