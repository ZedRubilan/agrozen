import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/domain/alerts/alert_engine.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';

class LogMortalityScreen extends StatefulWidget {
  const LogMortalityScreen({super.key});

  @override
  State<LogMortalityScreen> createState() => _LogMortalityScreenState();
}

class _LogMortalityScreenState extends State<LogMortalityScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _knowledgeRepo = KnowledgeRepository();

  String _lang = 'uz';
  int _currentCount = 500;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _currentCount = prefs.getInt('current_count') ?? 500;
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

    final deaths = int.parse(_controller.text.trim());
    final prefs = await SharedPreferences.getInstance();

    final prevDeaths = prefs.getInt('today_mortality') ?? 0;
    final newTodayDeaths = prevDeaths + deaths;
    final updatedCurrent = (_currentCount - deaths).clamp(0, 999999);

    await prefs.setInt('today_mortality', newTodayDeaths);
    await prefs.setInt('current_count', updatedCurrent);

    // Evaluate alert rule
    final normsMap = await _knowledgeRepo.getNorms();
    final norms = NormsData(
      mortalityThresholdPercent: (normsMap['alert_thresholds']?['daily_mortality_percent'] as num?)?.toDouble() ?? 1.0,
      weeklyWeightTargets: {7: 180, 14: 500, 21: 900, 28: 1400, 35: 1900, 42: 2400},
      weightDeviationPercent: 15.0,
      dailyFeedPerBird: {7: 25, 14: 55, 21: 85, 28: 120, 35: 155, 42: 180},
      temperatureTargets: {1: 34, 3: 33, 7: 32, 14: 29, 21: 27, 28: 24, 35: 22, 42: 20},
    );
    final engine = AlertEngine(norms);
    final alert = engine.checkMortality(deaths: newTodayDeaths, currentCount: updatedCurrent);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (!mounted) return;

    if (alert != null) {
      final district = prefs.getString('farmer_district') ?? 'Toshkent';
      final vets = await _knowledgeRepo.getVetByDistrict(district);
      if (!mounted) return;
      final vet = vets.isNotEmpty ? vets.first : null;

      final isRu = _lang == 'ru';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          title: Text(isRu ? 'Внимание: Высокий падёж!' : "Diqqat: Yuqori nobodlik!"),
          content: Text(
            isRu
                ? 'Падёж превышает суточную норму (${alert.actualValue.toStringAsFixed(1)}% > 1%).\n\n'
                  'Срочно свяжитесь с ветеринаром:\n'
                  '${vet?['name'] ?? 'Ветеринар'}\nТел: ${vet?['phone'] ?? '+998 90 123 45 67'}'
                : "Nobodlik sutkalik me'yordan oshib ketdi (${alert.actualValue.toStringAsFixed(1)}% > 1%).\n\n"
                  "Zudlik bilan veterinarga murojaat qiling:\n"
                  "${vet?['name'] ?? 'Veterinar'}\nTel: ${vet?['phone'] ?? '+998 90 123 45 67'}",
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text(isRu ? 'Понятно' : 'Tushundim'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang == 'ru' ? 'Запись успешно сохранена' : 'Qayd muvaffaqiyatli saqlandi'),
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
        title: Text(isRu ? 'Запись падежа' : 'Nobodlik qaydi'),
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
                  isRu ? 'Сколько птиц погибло?' : 'Nechta parranda nobud bo\'ldi?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isRu
                      ? 'Текущее поголовье: $_currentCount голов'
                      : 'Jami mavjud parranda: $_currentCount bosh',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isRu ? 'Количество погибших (голов)' : 'Nobud bo\'lganlar soni (bosh)',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.heart_broken_outlined, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isRu ? 'Введите число' : 'Son kiriting';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) {
                      return isRu ? 'Число не может быть отрицательным' : 'Son musbat bo\'lishi kerak';
                    }
                    if (n > _currentCount) {
                      return isRu ? 'Не может превышать текущее поголовье' : 'Mavjud parrandalar sonidan ko\'p bo\'la olmaydi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isRu
                              ? 'Норма естественного отхода: не более 1% за сутки.'
                              : "Tabiiy nobodlik me'yori: sutkasiga 1% dan oshmasligi kerak.",
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
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
