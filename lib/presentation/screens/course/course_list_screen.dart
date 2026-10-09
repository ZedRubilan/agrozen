import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String _lang = 'uz';
  List<int> _completedLessons = [];
  bool _isLoading = true;

  final List<Map<String, String>> _lessons = [
    {
      'num': '1',
      'title_uz': "Jo'jalar kelishidan oldin xonani tayyorlash",
      'title_ru': 'Подготовка помещения до завоза цыплят',
      'desc_uz': 'Dezinfeksiya, to\'shama, isitish tizimini sozlash',
      'desc_ru': 'Дезинфекция, подстилка, настройка обогрева',
    },
    {
      'num': '2',
      'title_uz': 'Dastlabki 3 kun: hal qiluvchi davr',
      'title_ru': 'Первые 3 дня: решающий период',
      'desc_uz': 'Suv va yemga o\'rgatish, harorat monitoringi',
      'desc_ru': 'Приучение к воде и корму, контроль температуры',
    },
    {
      'num': '3',
      'title_uz': 'Harorat va shamollatish boshqaruvi',
      'title_ru': 'Управление температурой и вентиляцией',
      'desc_uz': 'Ammiakni yo\'qotish va qizib ketishdan saqlash',
      'desc_ru': 'Удаление аммиака и защита от перегрева',
    },
    {
      'num': '4',
      'title_uz': "To'g'ri oziqlantirish fazalari",
      'title_ru': 'Фазы правильного кормления',
      'desc_uz': 'Start, O\'sish va Finish yemlari me\'yorlari',
      'desc_ru': 'Нормы кормов Старт, Рост и Финиш',
    },
    {
      'num': '5',
      'title_uz': 'Kasalliklar va veterinar bilan ishlash',
      'title_ru': 'Болезни и работа с ветеринаром',
      'desc_uz': 'Asosiy alomatlar va favqulodda harakatlar',
      'desc_ru': 'Главные симптомы и экстренные действия',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('app_language') ?? 'uz';
    final completed = prefs.getStringList('completed_lessons') ?? [];
    _completedLessons = completed.map((e) => int.tryParse(e) ?? 0).toList();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';
    final allCompleted = _completedLessons.length >= _lessons.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Курс до кредита' : 'Kreditdan oldingi kurs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Course banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school, color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isRu ? 'Обучение птицевода' : 'Parrandachilik kursi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRu
                              ? 'Пройдите 5 мини-уроков с тестами и получите официальный сертификат о готовности к партии.'
                              : "5 ta qisqa dars va testni yakunlang hamda partiyaga tayyorgarlik sertifikatiga ega bo'ling.",
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isRu
                              ? 'Пройдено: ${_completedLessons.length} из ${_lessons.length}'
                              : "Tugallandi: ${_completedLessons.length} / ${_lessons.length}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (allCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/certificate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: Text(
                          isRu ? 'Посмотреть мой сертификат' : "Sertifikatimni ko'rish",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  Text(
                    isRu ? 'Уроки курса' : 'Darslar ro\'yxati',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _lessons[index];
                      final num = int.parse(item['num']!);
                      final isPassed = _completedLessons.contains(num);

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isPassed ? Colors.green.shade100 : theme.colorScheme.primary.withAlpha(20),
                            child: isPassed
                                ? const Icon(Icons.check, color: Colors.green)
                                : Text(
                                    '$num',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ),
                          title: Text(
                            isRu ? item['title_ru']! : item['title_uz']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            isRu ? item['desc_ru']! : item['desc_uz']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            await context.push('/course/$num');
                            _loadState();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
