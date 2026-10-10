import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/tactile_button.dart';

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
  bool _isOnboarded = false;

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _isOnboarded = prefs.getBool('is_onboarded') ?? false;
      final existingName = prefs.getString('farmer_name');
      if (existingName != null && existingName.isNotEmpty && _nameController.text == 'Fermer') {
        _nameController.text = existingName;
      }
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

    final alreadyOnboarded = prefs.getBool('is_onboarded') ?? false;
    if (!mounted) return;
    if (alreadyOnboarded) {
      context.go('/home');
    } else {
      context.go('/onboarding/disclaimer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';
    final isEn = _lang == 'en';
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        leading: _isOnboarded
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/home'),
              )
            : null,
        title: Text(
          isRu ? 'Параметры партии' : (isEn ? 'Flock Setup' : 'Partiya ma\'lumotlari'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isRu ? 'ШАГ 3 ИЗ 4' : (isEn ? 'STEP 3 OF 4' : '3-BOSQICH (4 TADAN)'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isRu
                      ? 'Новая партия бройлеров'
                      : (isEn ? 'New Broiler Batch' : 'Yangi broyler partiyasi'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isRu
                      ? 'Укажите дату завоза и количество цыплят для расчета ежедневного плана'
                      : (isEn
                          ? 'Enter chick arrival date and flock count to calculate the daily care plan'
                          : "Kunlik reja va me'yorlarni hisoblash uchun jo'jalar kelgan sana va sonini kiriting"),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

                // Farmer Name
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: isRu
                          ? 'Ваше имя / Название фермы'
                          : (isEn ? 'Your Name / Farm Name' : 'Ismingiz / Ferma nomi'),
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      prefixIcon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (isRu
                            ? 'Введите имя'
                            : (isEn ? 'Please enter name' : 'Ismni kiriting'))
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Arrival Date Picker Card
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRu
                                    ? 'Дата завоза цыплят'
                                    : (isEn ? 'Chick Arrival Date' : 'Jo\'jalar kelgan sana'),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dateFormat.format(_arrivalDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isRu ? 'Изменить' : (isEn ? 'Change' : 'Tanlash'),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Chick Count Form Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: isRu
                          ? 'Количество цыплят (голов)'
                          : (isEn ? 'Number of chicks (heads)' : 'Jo\'jalar soni (bosh)'),
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      hintText: '500',
                      prefixIcon: Icon(Icons.tag_rounded, color: theme.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                ),
                const SizedBox(height: 12),

                // Quick preset chips
                Wrap(
                  spacing: 8,
                  children: [500, 1000, 2500, 5000].map((count) {
                    return ActionChip(
                      label: Text(
                        isRu ? '$count гол.' : (isEn ? '$count birds' : '$count bosh'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onPressed: () {
                        setState(() {
                          _countController.text = '$count';
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                TactileButton(
                  height: 56,
                  depth: 4,
                  borderRadius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  shadowColor: const Color(0xFF1B5E20),
                  onPressed: _proceed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isRu ? 'Далее' : (isEn ? 'Next' : 'Keyingisi'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
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
