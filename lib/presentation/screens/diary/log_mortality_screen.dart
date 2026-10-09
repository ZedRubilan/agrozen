import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrozen/domain/alerts/alert_engine.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/tactile_button.dart';
import 'package:agrozen/services/daily_counters.dart';

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
    final prefs = await DailyCounters.rolled();
    if (!mounted) return;
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
    final prefs = await DailyCounters.rolled();

    // Mortality % must be measured against the flock size BEFORE today's
    // deaths are removed, otherwise the rate is inflated.
    final countBeforeToday = prefs.getInt('current_count') ?? _currentCount;
    final newTodayDeaths = DailyCounters.getMortality(prefs) + deaths;
    final updatedCurrent = (countBeforeToday - deaths).clamp(0, 999999);

    await DailyCounters.addMortality(prefs, deaths);
    await prefs.setInt('current_count', updatedCurrent);

    // Evaluate alert rule against the vet-verified norms.
    final norms = await _knowledgeRepo.getParsedNorms();
    final engine = AlertEngine(norms);
    final alert = engine.checkMortality(
      deaths: newTodayDeaths,
      currentCount: countBeforeToday,
    );

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
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          title: Text(isRu ? 'Внимание: Высокий падёж!' : "Diqqat: Yuqori nobodlik!"),
          content: Text(
            isRu
                ? 'Падёж превышает суточную норму (${alert.actualValue.toStringAsFixed(1)}% > ${alert.threshold.toStringAsFixed(1)}%).\n\n'
                  'Срочно свяжитесь с ветеринаром:\n'
                  '${vet?['name'] ?? 'Ветеринар'}\nТел: ${vet?['phone'] ?? '+998 90 123 45 67'}'
                : "Nobodlik sutkalik me'yordan oshib ketdi (${alert.actualValue.toStringAsFixed(1)}% > ${alert.threshold.toStringAsFixed(1)}%).\n\n"
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

  void _addQuick(int delta) {
    final current = int.tryParse(_controller.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, _currentCount);
    _controller.text = next.toString();
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRu = _lang == 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Запись падежа' : 'Nobodlik qaydi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                const SizedBox(height: 12),
                // Quick Increment Chips for dirty hands
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickChip('+1', () => _addQuick(1)),
                    _buildQuickChip('+2', () => _addQuick(2)),
                    _buildQuickChip('+5', () => _addQuick(5)),
                    _buildQuickChip('+10', () => _addQuick(10)),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
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
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                TactileButton(
                  height: 52,
                  depth: 3,
                  borderRadius: 16,
                  backgroundColor: Colors.red.shade700,
                  shadowColor: Colors.red.shade900,
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isRu ? 'Сохранить запись' : 'Qaydni saqlash',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
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
