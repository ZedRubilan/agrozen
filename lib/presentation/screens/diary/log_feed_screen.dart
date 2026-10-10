import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrozen/presentation/widgets/tactile_button.dart';
import 'package:agrozen/services/daily_counters.dart';

class LogFeedScreen extends StatefulWidget {
  const LogFeedScreen({super.key});

  @override
  State<LogFeedScreen> createState() => _LogFeedScreenState();
}

class _LogFeedScreenState extends State<LogFeedScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _lang = 'uz';
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

    final feedKg = double.parse(_controller.text.trim());
    final prefs = await DailyCounters.rolled();
    await DailyCounters.addFeed(prefs, feedKg);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lang == 'ru' ? 'Расход корма сохранён' : 'Yem sarfi saqlandi'),
        backgroundColor: Colors.green,
      ),
    );
    if (context.canPop()) {
      context.pop();
    }
  }

  void _addQuick(double delta) {
    final current = double.tryParse(_controller.text.trim()) ?? 0.0;
    final next = current + delta;
    _controller.text = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade400, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withAlpha(20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.brown.shade900,
            ),
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
        title: Text(isRu ? 'Расход корма' : 'Yem sarfi'),
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
                  isRu ? 'Сколько корма выдано?' : 'Qancha yem berildi?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isRu
                      ? 'Укажите общий вес выданного комбикорма (в килограммах)'
                      : "Berilgan jami aralash yem og'irligini kiriting (kilogrammda)",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isRu ? 'Расход корма (кг)' : 'Yem miqdori (kg)',
                    hintText: '25.0',
                    prefixIcon: const Icon(Icons.grain, color: Colors.amber),
                    suffixText: isRu ? 'кг' : 'kg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isRu ? 'Введите вес корма' : 'Yem miqdorini kiriting';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return isRu ? 'Число должно быть больше 0' : '0 dan katta son kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickChip('+5 kg', () => _addQuick(5)),
                    _buildQuickChip('+10 kg', () => _addQuick(10)),
                    _buildQuickChip('+25 kg', () => _addQuick(25)),
                    _buildQuickChip('+50 kg', () => _addQuick(50)),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isRu
                              ? 'Кормите птицу строго по фазам (Старт -> Рост -> Финиш) и не допускайте порчи корма.'
                              : "Parrandalarni qat'iy bosqichlar bo'yicha boqing (Start -> O'sish -> Finish) va yem buzilishiga yo'l qo'ymang.",
                          style: TextStyle(color: Colors.brown.shade800, fontSize: 13, fontWeight: FontWeight.w600),
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
                  backgroundColor: Colors.amber.shade900,
                  shadowColor: const Color(0xFF6D3800),
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
