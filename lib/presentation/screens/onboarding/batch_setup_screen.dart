import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../domain/broiler/broiler_grower_library.dart';
import '../../../services/farm_store.dart';
import '../../ui/components.dart';
import '../../ui/format.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 3 (also used from Settings to edit the batch): name,
/// chick arrival date and flock size.
class BatchSetupScreen extends StatefulWidget {
  const BatchSetupScreen({super.key});

  @override
  State<BatchSetupScreen> createState() => _BatchSetupScreenState();
}

class _BatchSetupScreenState extends State<BatchSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countController = TextEditingController(text: '500');
  DateTime _arrivalDate = DateTime.now();
  String _lang = 'uz';
  bool _isOnboarded = false;

  /// True when an existing batch is being edited (not a new one).
  bool _editingBatch = false;

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _isOnboarded = prefs.getBool('is_onboarded') ?? false;
      _nameController.text = prefs.getString('farmer_name') ?? '';
      final arrival = DateTime.tryParse(prefs.getString('arrival_date') ?? '');
      _editingBatch = arrival != null;
      if (arrival != null) {
        _arrivalDate = arrival;
        _countController.text = '${prefs.getInt('initial_count') ?? 500}';
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _arrivalDate.isAfter(now) ? now : _arrivalDate,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
    );
    if (picked != null) setState(() => _arrivalDate = picked);
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    final count = int.parse(_countController.text.trim());

    // Editing an existing batch keeps the deaths already recorded.
    var current = count;
    if (_editingBatch) {
      final oldInitial = prefs.getInt('initial_count') ?? count;
      final oldCurrent = prefs.getInt('current_count') ?? oldInitial;
      current = math.max(0, count - math.max(0, oldInitial - oldCurrent));
    }

    await prefs.setString('farmer_name', _nameController.text.trim());
    await prefs.setInt('initial_count', count);
    await prefs.setInt('current_count', current);
    await prefs.setString('arrival_date', _arrivalDate.toIso8601String());
    FarmStore.notifyChanged();

    if (!mounted) return;
    if (!_isOnboarded) {
      context.go('/onboarding/disclaimer');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy').format(_arrivalDate);
    return Form(
      key: _formKey,
      child: OnboardingScaffold(
        step: _isOnboarded ? null : 3,
        icon: Icons.egg_alt_rounded,
        accent: AppColors.gold,
        onBack: _isOnboarded
            ? () => context.canPop() ? context.pop() : context.go('/home')
            : () => context.go('/onboarding/region'),
        title: _editingBatch
            ? _t("Partiya ma'lumotlari", 'Данные партии', 'Batch details')
            : _t(
                'Yangi broyler partiyasi',
                'Новая партия бройлеров',
                'New broiler batch',
              ),
        subtitle: _t(
          "Shu ma'lumotlar asosida har kunlik me'yorlar hisoblanadi.",
          'По этим данным рассчитываются нормы на каждый день.',
          'Daily targets are calculated from these details.',
        ),
        buttonLabel: _isOnboarded
            ? AppStrings.save(_lang)
            : AppStrings.next(_lang),
        onNext: _proceed,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _t('Ismingiz', 'Ваше имя', 'Your name'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? _t('Ismni kiriting', 'Введите имя', 'Please enter your name')
                : null,
          ),
          const Gap(AppSpace.lg),
          AppCard(
            onTap: _pickDate,
            child: Row(
              children: [
                const IconBadge(icon: Icons.calendar_month_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(
                          "Jo'jalar kelgan sana",
                          'Дата завоза цыплят',
                          'Chick arrival date',
                        ),
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 2),
                      Text(date, style: AppText.cardTitle),
                    ],
                  ),
                ),
                Text(
                  _t("O'zgartirish", 'Изменить', 'Change'),
                  style: AppText.label.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Gap(AppSpace.lg),
          TextFormField(
            controller: _countController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _t(
                "Jo'jalar soni",
                'Количество цыплят',
                'Number of chicks',
              ),
              prefixIcon: const Icon(Icons.pets_outlined),
              suffixText: _t('bosh', 'гол.', 'birds'),
            ),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) {
                return _t(
                  '0 dan katta son kiriting',
                  'Введите число больше 0',
                  'Must be greater than 0',
                );
              }
              if (n > 200000) {
                return _t(
                  'Juda katta son',
                  'Слишком большое число',
                  'Too large',
                );
              }
              return null;
            },
          ),
          const Gap(),
          Row(
            children: [
              for (final n in const [500, 1000, 2000, 5000]) ...[
                if (n != 500) const SizedBox(width: AppSpace.sm),
                Expanded(child: _countPill(n)),
              ],
            ],
          ),
          const Gap(AppSpace.lg),
          _buildPreview(),
        ],
      ),
    );
  }

  Widget _countPill(int n) {
    final selected = _countController.text.trim() == '$n';
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: selected
            ? AppShadow.glow(AppColors.primary)
            : AppShadow.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => setState(() => _countController.text = '$n'),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                Fmt.grouped(n.toDouble()),
                style: AppText.label.copyWith(
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// What the chosen arrival date means today: batch day, phase and the
  /// house temperature to hold — so the farmer sees the app "get" their flock.
  Widget _buildPreview() {
    final today = DateTime.now();
    final days = DateTime(today.year, today.month, today.day)
        .difference(
          DateTime(_arrivalDate.year, _arrivalDate.month, _arrivalDate.day),
        )
        .inDays;
    final day = (days + 1).clamp(1, 42);
    final finished = days + 1 > 42;
    final spec = BroilerGrowerLibrary.specForDay(day);
    final fmt = Fmt(_lang);
    return PhotoCard(
      image: 'assets/images/chick_starter.jpg',
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          ProgressRing(
            value: day / 42,
            size: 72,
            stroke: 7,
            color: Colors.white,
            trackColor: Colors.white.withAlpha(60),
            child: Text(
              '$day',
              style: AppText.metric.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finished
                      ? _t(
                          '42 kunlik sikl tugagan',
                          '42-дневный цикл завершён',
                          'The 42-day cycle is over',
                        )
                      : _t(
                          "Jo'jalaringiz bugun: ${fmt.day(day)}",
                          'Ваши цыплята сегодня: ${fmt.day(day).toLowerCase()}',
                          'Your chicks today: ${fmt.day(day)}',
                        ),
                  style: AppText.cardTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '${FarmSnapshot.phaseNameFor(day, _lang)} · '
                  '${_t('bino', 'птичник', 'house')} ${fmt.celsius(spec.targetTempC)}',
                  style: AppText.caption.copyWith(
                    color: Colors.white.withAlpha(225),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
