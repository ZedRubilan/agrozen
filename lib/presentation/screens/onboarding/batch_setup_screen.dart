import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatchSetupScreen extends StatefulWidget {
  const BatchSetupScreen({super.key});

  @override
  State<BatchSetupScreen> createState() => _BatchSetupScreenState();
}

class _BatchSetupScreenState extends State<BatchSetupScreen> {
  DateTime _arrivalDate = DateTime.now();
  final _countController = TextEditingController(text: '500');
  final _nameController = TextEditingController(text: 'Fermer');
  final _formKey = GlobalKey<FormState>();
  String _lang = 'uz';

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _arrivalDate,
      firstDate: DateTime.now().subtract(const Duration(days: 42)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _arrivalDate = picked);
    }
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_name', _nameController.text.trim());
    await prefs.setInt('initial_count', int.parse(_countController.text.trim()));
    await prefs.setInt('current_count', int.parse(_countController.text.trim()));
    await prefs.setString('arrival_date', _arrivalDate.toIso8601String());

    if (!mounted) return;
    context.go('/onboarding/disclaimer');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';
    final isEn = _lang == 'en';
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Параметры партии' : (isEn ? 'Flock Setup' : 'Partiya ma\'lumotlari')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isRu
                      ? 'Новая партия бройлеров'
                      : (isEn ? 'New Broiler Batch' : 'Yangi broyler partiyasi'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isRu
                      ? 'Укажите дату завоза и количество цыплят для расчета ежедневного плана'
                      : (isEn
                          ? 'Enter chick arrival date and flock count to calculate the daily care plan'
                          : "Kunlik reja va me'yorlarni hisoblash uchun jo'jalar kelgan sana va sonini kiriting"),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                // Farmer Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isRu
                        ? 'Ваше имя / Название фермы'
                        : (isEn ? 'Your Name / Farm Name' : 'Ismingiz / Ferma nomi'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? (isRu
                          ? 'Введите имя'
                          : (isEn ? 'Please enter name' : 'Ismni kiriting'))
                      : null,
                ),
                const SizedBox(height: 18),
                // Arrival Date Picker Card
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRu
                                    ? 'Дата завоза цыплят'
                                    : (isEn ? 'Chick Arrival Date' : 'Jo\'jalar kelgan sana'),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(_arrivalDate),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isRu ? 'Изменить' : (isEn ? 'Change' : 'Tanlash'),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Chick Count
                TextFormField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isRu
                        ? 'Количество цыплят (голов)'
                        : (isEn ? 'Number of chicks (heads)' : 'Jo\'jalar soni (bosh)'),
                    hintText: '500',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isRu
                          ? 'Введите количество'
                          : (isEn ? 'Please enter count' : 'Sonini kiriting');
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return isRu
                          ? 'Введите число больше 0'
                          : (isEn ? 'Must be greater than 0' : '0 dan katta son kiriting');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isRu ? 'Далее' : (isEn ? 'Next' : 'Keyingisi'),
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
