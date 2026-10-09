import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrozen/domain/alerts/alert_engine.dart';
import 'package:agrozen/domain/scheduler/day_calculator.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/services/daily_counters.dart';

class LogWeightScreen extends StatefulWidget {
  const LogWeightScreen({super.key});

  @override
  State<LogWeightScreen> createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends State<LogWeightScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _knowledgeRepo = KnowledgeRepository();

  String _lang = 'uz';
  int _batchDay = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await DailyCounters.rolled();
    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      final arrivalStr = prefs.getString('arrival_date');
      if (arrivalStr != null) {
        _batchDay = DayCalculator.calculateBatchDay(DateTime.parse(arrivalStr)).clamp(1, 42);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final weightGrams = double.parse(_controller.text.trim());
    final prefs = await DailyCounters.rolled();
    await prefs.setDouble('last_weight', weightGrams);

    // Evaluate the weight rule against the vet-verified per-day norms.
    final norms = await _knowledgeRepo.getParsedNorms();
    final engine = AlertEngine(norms);
    final alert = engine.checkWeight(weightGrams: weightGrams, batchDay: _batchDay);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (alert != null) {
      final district = prefs.getString('farmer_district') ?? 'Toshkent';
      final vets = await _knowledgeRepo.getVetByDistrict(district);
      if (!mounted) return;
      final vet = vets.isNotEmpty ? vets.first : null;
      final isRu = _lang == 'ru';

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
          title: Text(isRu ? 'Внимание: Отставание в весе!' : "Diqqat: Vazn ortda qolmoqda!"),
          content: Text(
            isRu
                ? 'Вес (${weightGrams.toInt()} г) ниже нормы (${alert.threshold.toInt()} г) более чем на 15%.\n\n'
                  'Проверьте качество корма, температуру и обратитесь к ветеринару:\n'
                  '${vet?['name'] ?? 'Ветеринар'}\nТел: ${vet?['phone'] ?? '+998 90 123 45 67'}'
                : "Parranda vazni (${weightGrams.toInt()} g) $_batchDay-kun me'yoridan (${alert.threshold.toInt()} g) 15% dan ortiq kam.\n\n"
                  "Yem sifatini, xona haroratini tekshiring va veterinarga murojaat qiling:\n"
                  "${vet?['name'] ?? 'Veterinar'}\nTel: ${vet?['phone'] ?? '+998 90 123 45 67'}",
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isRu ? 'Понятно' : 'Tushundim'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang == 'ru' ? 'Контрольный вес сохранён' : 'Nazorat vazni saqlandi'),
          backgroundColor: Colors.green,
        ),
      );
    }

    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isRu = _lang == 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Контрольный вес' : 'Nazorat vazni'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isRu ? 'Какой средний вес птицы?' : "Parrandaning o'rtacha vazni qancha?",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isRu
                      ? 'Взвесьте 5-10 случайных птиц и введите среднее значение (День $_batchDay)'
                      : "5-10 ta tasodifiy parrandani torting va o'rtacha qiymatni kiriting ($_batchDay-kun)",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isRu ? 'Средний вес (грамм)' : "O'rtacha vazn (gramm)",
                    hintText: '450',
                    prefixIcon: const Icon(Icons.scale, color: Colors.teal),
                    suffixText: isRu ? 'г' : 'g',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isRu ? 'Введите вес' : 'Vaznni kiriting';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return isRu ? 'Число должно быть больше 0' : '0 dan katta son kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timeline, color: Colors.teal, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isRu
                              ? 'Ориентиры: 7 день ~180г, 14 день ~500г, 21 день ~900г, 28 день ~1400г, 42 день ~2400г.'
                              : "Mo'ljallar: 7-kun ~180g, 14-kun ~500g, 21-kun ~900g, 28-kun ~1400g, 42-kun ~2400g.",
                          style: TextStyle(color: Colors.teal.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isRu ? 'Сохранить запись' : 'Qaydni saqlash',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
