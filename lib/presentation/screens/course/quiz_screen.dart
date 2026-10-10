import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/tactile_button.dart';

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

  Map<String, dynamic> _getQuizData(int id, String lang) {
    switch (id) {
      case 1:
        if (lang == 'en') {
          return {
            'question': 'To what temperature should the barn be preheated 24 hours before chick arrival?',
            'options': ['20-22°C', '26-28°C', '33-34°C', '40°C'],
            'correct': 2,
            'explanation': 'Day-old chicks cannot regulate their own body temperature; preheating the barn floor and air to 33-34°C prevents chilling and early mortality.',
          };
        } else if (lang == 'ru') {
          return {
            'question': 'До какой температуры необходимо прогреть птичник за 24 часа до завоза цыплят?',
            'options': ['20-22°C', '26-28°C', '33-34°C', '40°C'],
            'correct': 2,
            'explanation': 'Суточные цыплята еще не могут сами удерживать тепло тела; прогрев пола и воздуха до 33-34°C защищает их от переохлаждения.',
          };
        } else {
          return {
            'question': "Jo'jalar kelishidan 24 soat oldin xonani qanday haroratgacha qizdirish lozim?",
            'options': ['20-22°C', '26-28°C', '33-34°C', '40°C'],
            'correct': 2,
            'explanation': "Bir kunlik jo'jalar tana haroratini mustaqil boshqara olmaydi; xona va to'shamani 33-34°C gacha qizdirish ularni shamollashdan asraydi.",
          };
        }
      case 2:
        if (lang == 'en') {
          return {
            'question': 'What percentage of chicks must have found water and feed within the first 8 hours?',
            'options': ['At least 80%', 'Around 40%', 'Does not matter', 'Only 20%'],
            'correct': 0,
            'explanation': 'According to Ross-308 standards, at least 80% of chicks should have full, soft crops 8 hours after placement to ensure uniform growth.',
          };
        } else if (lang == 'ru') {
          return {
            'question': 'Какой процент цыплят должен найти воду и корм в первые 8 часов?',
            'options': ['Не менее 80%', 'Около 40%', 'Не имеет значения', 'Только 20%'],
            'correct': 0,
            'explanation': 'По стандарту Ross-308 через 8 часов после посадки минимум у 80% цыплят зоб должен быть мягким и наполненным кормом и водой.',
          };
        } else {
          return {
            'question': "Dastlabki 8 soat ichida jo'jalarning necha foizi suv va yemni topishi shart?",
            'options': ["Kamida 80%", 'Taxminan 40%', "Farqi yo'q", 'Faqat 20%'],
            'correct': 0,
            'explanation': "Ross-308 standartiga ko'ra, 8 soatdan so'ng kamida 80% jo'janing jig'ildoni yumshoq va to'la bo'lishi bir tekis o'sishni ta'minlaydi.",
          };
        }
      case 3:
        if (lang == 'en') {
          return {
            'question': 'What is the primary risk of improper ventilation in the barn?',
            'options': ['Increased appetite', 'Ammonia buildup and ascites (water belly)', 'Cold feet', 'No negative impact'],
            'correct': 1,
            'explanation': 'Poor air exchange traps ammonia and carbon dioxide, damaging the respiratory tract and causing ascites (water belly) in fast-growing broilers.',
          };
        } else if (lang == 'ru') {
          return {
            'question': 'К чему в первую очередь приводит отсутствие правильной вентиляции?',
            'options': ['К улучшению аппетита', 'К накоплению аммиака и асциту (водянке)', 'К переохлаждению ног', 'Ни к чему'],
            'correct': 1,
            'explanation': 'Плохой воздухообмен приводит к скоплению аммиака и углекислого газа, что вызывает ожоги дыхательных путей и асцит (водянку).',
          };
        } else {
          return {
            'question': "To'g'ri shamollatish yo'qligi birinchi navbatda nimaga olib keladi?",
            'options': ["Ishtaha ochilishiga", "Ammiak to'planishi va suv yig'ilishiga (assit)", "Oyoqlari sovushiga", "Hech narsaga"],
            'correct': 1,
            'explanation': "Havo almashinuvi yomon bo'lsa, ammiak va karbonat angidrid to'planib, nafas yo'llarini zararlaydi hamda assit (qorinda suv yig'ilishi) kelib chiqadi.",
          };
        }
      case 4:
        if (lang == 'en') {
          return {
            'question': 'How many main feeding phases are used in standard broiler production?',
            'options': ['1 phase', '3 phases (Starter, Grower, Finisher)', '5 phases', 'Phases are optional'],
            'correct': 1,
            'explanation': 'Broilers require 3 distinct nutritional phases: Starter (high protein for organs/skeleton), Grower (muscle growth), and Finisher (energy for final weight).',
          };
        } else if (lang == 'ru') {
          return {
            'question': 'Сколько основных фаз кормления используется при выращивании бройлеров?',
            'options': ['1 фаза', '3 фазы (Старт, Рост, Финиш)', '5 фаз', 'Фазы не нужны'],
            'correct': 1,
            'explanation': 'Применяются 3 фазы: Старт (высокий протеин для скелета и иммунитета), Рост (набор мышечной массы) и Финиш (энергия для убойного веса).',
          };
        } else {
          return {
            'question': "Broylerlarni boqishda nechta asosiy oziqlantirish fazasi qo'llaniladi?",
            'options': ['1 ta faza', "3 ta faza (Start, O'sish, Finish)", '5 ta faza', "Faza kerak emas"],
            'correct': 1,
            'explanation': "Broylerlar 3 bosqichda oziqlantiriladi: Start (skelet va immunitet uchun yuqori oqsil), O'sish (mushak massasi) va Finish (yakuniy vazn uchun energiya).",
          };
        }
      default:
        if (lang == 'en') {
          return {
            'question': 'What emergency action should be taken if daily mortality exceeds 1%?',
            'options': ['Administer antibiotics without consultation', 'Immediately isolate the barn and call the veterinarian', 'Just wait it out', 'Increase barn lighting'],
            'correct': 1,
            'explanation': 'Daily mortality above 1% is a critical red alert indicating potential infectious outbreak or acute climate failure; immediate veterinary intervention is mandatory.',
          };
        } else if (lang == 'ru') {
          return {
            'question': 'Что необходимо сделать при превышении суточного падежа в 1%?',
            'options': ['Самостоятельно дать антибиотики', 'Срочно изолировать птичник и позвонить ветеринару', 'Просто подождать', 'Увеличить свет'],
            'correct': 1,
            'explanation': 'Суточный падеж выше 1% — критический сигнал возможной инфекции или сбоя микроклимата; требуется немедленная изоляция и вызов ветеринара.',
          };
        } else {
          return {
            'question': "Sutkalik nobodlik 1% dan oshganda nima qilish zarur?",
            'options': ["Mustaqil antibiotik berish", "Hududni darhol cheklab, veterinarga murojaat qilish", "Kutish", "Chiroqni kuchaytirish"],
            'correct': 1,
            'explanation': "Kunlik nobodlik 1% dan oshishi xavfli infeksiya yoki mikroiqlim buzilishidan darak beradi; darhol binoni izolyatsiya qilib, veterinarni chaqirish shart.",
          };
        }
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
    final quiz = _getQuizData(widget.lessonId, _lang);
    final options = quiz['options'] as List<String>;
    final correctIndex = quiz['correct'] as int;
    final explanation = quiz['explanation'] as String? ?? '';

    final titleText = _lang == 'en'
        ? 'Quiz: Lesson ${widget.lessonId}'
        : (_lang == 'ru' ? 'Тест: Урок ${widget.lessonId}' : 'Test: Dars ${widget.lessonId}');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lang == 'en' ? 'QUESTION' : (_lang == 'ru' ? 'ВОПРОС' : 'SAVOL'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      quiz['question'] as String,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(options.length, (index) {
                final isSelected = _selectedOption == index;
                Color tileBg = Colors.white;
                Color borderColor = const Color(0xFFE2E8F0);
                IconData iconData = isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded;
                Color iconColor = isSelected ? theme.colorScheme.primary : Colors.grey.shade400;

                if (_submitted) {
                  if (index == correctIndex) {
                    tileBg = const Color(0xFFEAF5ED);
                    borderColor = const Color(0xFF2D7A4C);
                    iconData = Icons.check_circle_rounded;
                    iconColor = const Color(0xFF2D7A4C);
                  } else if (isSelected && !_isCorrect) {
                    tileBg = const Color(0xFFFEF2F2);
                    borderColor = const Color(0xFFDC2626);
                    iconData = Icons.cancel_rounded;
                    iconColor = const Color(0xFFDC2626);
                  }
                } else if (isSelected) {
                  tileBg = theme.colorScheme.primary.withAlpha(18);
                  borderColor = theme.colorScheme.primary;
                  iconColor = theme.colorScheme.primary;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: _submitted ? null : () => setState(() => _selectedOption = index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_submitted && index == correctIndex) ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(15)
                                : Colors.black.withAlpha(4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(iconData, color: iconColor, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected || (_submitted && index == correctIndex)
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              if (!_submitted)
                TactileButton(
                  height: 56,
                  depth: 4,
                  borderRadius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  shadowColor: const Color(0xFF1B4E31),
                  onPressed: _selectedOption >= 0 ? () => _submitAnswer(correctIndex) : null,
                  child: Text(
                    _lang == 'en' ? 'Check Answer' : (_lang == 'ru' ? 'Проверить ответ' : 'Javobni tekshirish'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _isCorrect ? const Color(0xFFEAF5ED) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isCorrect ? const Color(0xFF2D7A4C) : const Color(0xFFDC2626),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: _isCorrect ? const Color(0xFF2D7A4C) : const Color(0xFFDC2626),
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isCorrect
                                      ? (_lang == 'en'
                                          ? 'Correct! Lesson completed successfully.'
                                          : (_lang == 'ru'
                                              ? 'Правильно! Урок успешно сдан.'
                                              : 'To\'g\'ri! Dars muvaffaqiyatli topshirildi.'))
                                      : (_lang == 'en'
                                          ? 'Incorrect. Please try again!'
                                          : (_lang == 'ru'
                                              ? 'Неверно. Попробуйте еще раз!'
                                              : 'Noto\'g\'ri. Yana bir bor urinib ko\'ring!')),
                                  style: TextStyle(
                                    color: _isCorrect ? const Color(0xFF1B5E20) : const Color(0xFF991B1B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (explanation.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              explanation,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TactileButton(
                      height: 56,
                      depth: 4,
                      borderRadius: 18,
                      backgroundColor: _isCorrect ? const Color(0xFF2D7A4C) : const Color(0xFFD97706),
                      shadowColor: _isCorrect ? const Color(0xFF1B4E31) : const Color(0xFF92400E),
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
                      child: Text(
                        _isCorrect
                            ? (_lang == 'en' ? 'Done' : (_lang == 'ru' ? 'Готово' : 'Yakunlash'))
                            : (_lang == 'en' ? 'Try Again' : (_lang == 'ru' ? 'Попробовать снова' : 'Qayta urinish')),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
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
