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

    // Mortality % must be measured against the flock size at the start of the
    // day before today's deaths are removed, otherwise the rate is inflated.
    final currentBefore = prefs.getInt('current_count') ?? _currentCount;
    final previousTodayDeaths = DailyCounters.getMortality(prefs);
    final startOfDayCount = currentBefore + previousTodayDeaths;
    final newTodayDeaths = previousTodayDeaths + deaths;
    final updatedCurrent = (currentBefore - deaths).clamp(0, 999999);

    await DailyCounters.addMortality(prefs, deaths);
    await prefs.setInt('current_count', updatedCurrent);

    // Evaluate alert rule against the vet-verified norms.
    final norms = await _knowledgeRepo.getParsedNorms();
    final engine = AlertEngine(norms);
    final alert = engine.checkMortality(
      deaths: newTodayDeaths,
      currentCount: startOfDayCount,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (alert != null) {
      final district = prefs.getString('farmer_district') ?? 'Toshkent';
      final vets = await _knowledgeRepo.getVetByDistrict(district);
      if (!mounted) return;
      final vet = vets.isNotEmpty ? vets.first : null;

      final isEn = _lang == 'en';
      final isRu = _lang == 'ru';
      final alertTitle = isEn
          ? 'Warning: High Mortality!'
          : (isRu ? 'Внимание: Высокий падёж!' : "Diqqat: Yuqori nobodlik!");
      final alertContent = isEn
          ? 'Daily mortality exceeds standard threshold (${alert.actualValue.toStringAsFixed(1)}% > ${alert.threshold.toStringAsFixed(1)}%).\n\n'
            'Contact your district veterinarian immediately:\n'
            '${vet?['name'] ?? 'District Veterinarian'}\nTel: ${vet?['phone'] ?? '+998 90 123 45 67'}'
          : (isRu
              ? 'Падёж превышает суточную норму (${alert.actualValue.toStringAsFixed(1)}% > ${alert.threshold.toStringAsFixed(1)}%).\n\n'
                'Срочно свяжитесь с ветеринаром:\n'
                '${vet?['name'] ?? 'Ветеринар'}\nТел: ${vet?['phone'] ?? '+998 90 123 45 67'}'
              : "Nobodlik sutkalik me'yordan oshib ketdi (${alert.actualValue.toStringAsFixed(1)}% > ${alert.threshold.toStringAsFixed(1)}%).\n\n"
                "Zudlik bilan veterinarga murojaat qiling:\n"
                "${vet?['name'] ?? 'Veterinar'}\nTel: ${vet?['phone'] ?? '+998 90 123 45 67'}");

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          title: Text(alertTitle),
          content: Text(alertContent),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text(isEn ? 'Understood' : (isRu ? 'Понятно' : 'Tushundim')),
            ),
          ],
        ),
      );
    } else {
      final successMsg = _lang == 'en'
          ? 'Record saved successfully'
          : (_lang == 'ru' ? 'Запись успешно сохранена' : 'Qayd muvaffaqiyatli saqlandi');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F0), Color(0xFFFFE0E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withAlpha(20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.red.shade900,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = _lang == 'en';
    final isRu = _lang == 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEn ? 'Log Mortality' : (isRu ? 'Запись падежа' : 'Nobodlik qaydi')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEn
                      ? 'How many birds were lost today?'
                      : (isRu ? 'Сколько птиц погибло?' : 'Nechta parranda nobud bo\'ldi?'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? 'Current living flock: $_currentCount birds'
                      : (isRu
                          ? 'Текущее поголовье: $_currentCount голов'
                          : 'Jami mavjud parranda: $_currentCount bosh'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isEn
                        ? 'Number of dead birds'
                        : (isRu ? 'Количество погибших (голов)' : 'Nobud bo\'lganlar soni (bosh)'),
                    hintText: '0',
                    prefixIcon: const Icon(Icons.heart_broken_outlined, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isEn
                          ? 'Enter a count'
                          : (isRu ? 'Введите число' : 'Son kiriting');
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) {
                      return isEn
                          ? 'Number cannot be negative'
                          : (isRu ? 'Число не может быть отрицательным' : 'Son musbat bo\'lishi kerak');
                    }
                    if (n > _currentCount) {
                      return isEn
                          ? 'Cannot exceed current flock size'
                          : (isRu ? 'Не может превышать текущее поголовье' : 'Mavjud parrandalar sonidan ko\'p bo\'la olmaydi');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Quick Increment Chips for dirty hands
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
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
                          isEn
                              ? 'Normal daily mortality threshold: must not exceed 1% per day.'
                              : (isRu
                                  ? 'Норма естественного отхода: не более 1% за сутки.'
                                  : "Tabiiy nobodlik me'yori: sutkasiga 1% dan oshmasligi kerak."),
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
                          isEn ? 'Save Entry' : (isRu ? 'Сохранить запись' : 'Qaydni saqlash'),
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
