import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final prevFeed = prefs.getDouble('today_feed') ?? 0.0;
    await prefs.setDouble('today_feed', prevFeed + feedKg);

    setState(() => _isSaving = false);

    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final isRu = _lang == 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Расход корма' : 'Yem sarfi'),
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
                    suffixText: 'кг',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
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
                          style: TextStyle(color: Colors.brown.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade900,
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
