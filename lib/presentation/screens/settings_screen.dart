import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../services/external_actions.dart';
import '../../services/farm_store.dart';
import '../../services/flock_context_service.dart';
import '../ui/broiler_photos.dart';
import '../ui/components.dart';
import '../widgets/agro_icons.dart';
import '../ui/format.dart';
import '../widgets/location_picker_sheet.dart';

/// Settings: who the farmer is, language, farm location and the batch.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AppLanguageController<SettingsScreen> {
  FarmSnapshot? _farm;

  String get _lang => _farm?.lang ?? 'uz';
  Fmt get _fmt => Fmt(_lang);
  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load();
    if (!mounted) return;
    setState(() => _farm = farm);
  }

  Future<void> _changed() async {
    FarmStore.notifyChanged();
    await _load();
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    changeAppLanguage(lang);
    await _changed();
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _farm?.farmerName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Ismingiz', 'Ваше имя', 'Your name')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel(_lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppStrings.save(_lang)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_name', name);
    await _changed();
  }

  Future<void> _editLocation() async {
    final farm = _farm;
    if (farm == null) return;
    final changed = await showLocationPicker(
      context,
      lang: _lang,
      currentDistrict: farm.district,
      currentLocality: farm.locality,
    );
    if (changed) await _changed();
  }

  Future<void> _startNewBatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _t(
            'Yangi partiya boshlaysizmi?',
            'Начать новую партию?',
            'Start a new batch?',
          ),
        ),
        content: Text(
          _t(
            "Joriy partiyaning kundaligi va hisoblari o'chiriladi. Bu amalni qaytarib bo'lmaydi.",
            'Дневник и счётчики текущей партии будут удалены. Это нельзя отменить.',
            'The current batch diary and counters will be deleted. This cannot be undone.',
          ),
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel(_lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(_t('Ha, boshlash', 'Да, начать', 'Yes, start')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FarmStore.resetBatch();
    FlockContextService().clearHistory();
    if (!mounted) return;
    context.go('/onboarding/batch');
  }

  /// Title, author and licence of each bundled broiler photo; tapping one
  /// opens its Commons page (CC BY-SA requires the credit and a link).
  void _showPhotoCredits() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.photo_library_outlined,
          color: AppColors.primary,
          size: 36,
        ),
        title: Text(
          _t('Rasmlar mualliflari', 'Авторы фотографий', 'Photo credits'),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.sm,
          0,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final credit in PhotoCredit.all)
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.asset(
                      credit.asset,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 56, height: 56),
                    ),
                  ),
                  title: Text(credit.author, style: AppText.cardTitle),
                  subtitle: Text(
                    '${credit.title}\n${credit.licence}'
                    '${credit.licenceUrl != null ? ' · ${credit.licenceUrl}' : ''}',
                    style: AppText.caption,
                  ),
                  isThreeLine: true,
                  onTap: () =>
                      const ExternalActions().openLink(context, credit.url),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Yopish', 'Закрыть', 'Close')),
          ),
        ],
      ),
    );
  }

  void _showSafety() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.health_and_safety_outlined,
          color: AppColors.primary,
          size: 36,
        ),
        title: Text(
          _t('Xavfsizlik qoidasi', 'Правило безопасности', 'Safety rule'),
        ),
        content: Text(
          _t(
            "AgroZen Ross-308 / Cobb-500 me'yorlari asosida maslahat beradi, lekin dori va dozalarni tayinlamaydi. Kasallik belgilari bo'lsa, tuman veterinariga murojaat qiling.",
            'AgroZen даёт советы по нормам Ross-308 / Cobb-500, но не назначает лекарства и дозировки. При признаках болезни обращайтесь к районному ветеринару.',
            'AgroZen gives advice based on Ross-308 / Cobb-500 norms but never prescribes medicines or doses. For signs of disease, contact your district veterinarian.',
          ),
          style: AppText.body,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.understood(_lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    var i = 0;
    Widget reveal(Widget child) => Reveal(index: i++, child: child);

    return Scaffold(
      appBar: AppBar(title: Text(_t('Sozlamalar', 'Настройки', 'Settings'))),
      body: farm == null
          ? const LoadingView()
          : PageBody(
              children: [
                reveal(_buildProfile(farm)),
                const Gap(AppSpace.xl),
                reveal(SectionHeader(title: _t('Til', 'Язык', 'Language'))),
                reveal(
                  Row(
                    children: [
                      for (final l in const [
                        ('uz', "O'zbekcha"),
                        ('ru', 'Русский'),
                        ('en', 'English'),
                      ]) ...[
                        if (l.$1 != 'uz') const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: _LanguageTile(
                            code: l.$1,
                            label: l.$2,
                            selected: farm.lang == l.$1,
                            onTap: () => _setLanguage(l.$1),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(AppSpace.xl),
                reveal(SectionHeader(title: _t('Ferma', 'Ферма', 'Farm'))),
                reveal(
                  ListGroup(
                    children: [
                      ListRow(
                        icon: Icons.location_on_rounded,
                        tone: Tone.info,
                        title: farm.locationLabel,
                        subtitle: _t(
                          "Ob-havo va veterinar shu hudud bo'yicha",
                          'Погода и ветеринар — по этому району',
                          'Weather and vet are matched to this area',
                        ),
                        onTap: _editLocation,
                      ),
                      ListRow(
                        icon: Icons.egg_alt_rounded,
                        tone: Tone.warning,
                        title: _t(
                          "${Fmt.grouped(farm.initialCount.toDouble())} ta jo'ja",
                          '${Fmt.grouped(farm.initialCount.toDouble())} цыплят',
                          '${Fmt.grouped(farm.initialCount.toDouble())} chicks',
                        ),
                        subtitle: _t(
                          'Kelgan sana: ${DateFormat('dd.MM.yyyy').format(farm.arrivalDate)} · ${_fmt.day(farm.batchDay)}',
                          'Дата завоза: ${DateFormat('dd.MM.yyyy').format(farm.arrivalDate)} · ${_fmt.day(farm.batchDay)}',
                          'Arrived: ${DateFormat('dd.MM.yyyy').format(farm.arrivalDate)} · ${_fmt.day(farm.batchDay)}',
                        ),
                        onTap: () async {
                          await context.push('/onboarding/batch');
                          await _changed();
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(),
                reveal(
                  AppCard(
                    onTap: _startNewBatch,
                    color: AppColors.dangerSoft,
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restart_alt_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(
                                  'Yangi partiya boshlash',
                                  'Начать новую партию',
                                  'Start a new batch',
                                ),
                                style: AppText.cardTitle.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _t(
                                  "Yangi jo'jalar kelganda",
                                  'Когда привезли новых цыплят',
                                  'When new chicks arrive',
                                ),
                                style: AppText.caption,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(AppSpace.xl),
                reveal(
                  SectionHeader(
                    title: _t('Ilova haqida', 'О приложении', 'About'),
                  ),
                ),
                reveal(
                  ListGroup(
                    children: [
                      ListRow(
                        icon: Icons.health_and_safety_rounded,
                        title: _t(
                          'Xavfsizlik qoidasi',
                          'Правило безопасности',
                          'Safety rule',
                        ),
                        subtitle: _t(
                          'Dori va dozalar — faqat veterinar',
                          'Лекарства и дозы — только ветеринар',
                          'Medicines and doses — vet only',
                        ),
                        onTap: _showSafety,
                      ),
                      ListRow(
                        icon: Icons.photo_library_rounded,
                        tone: Tone.info,
                        title: _t(
                          'Rasmlar mualliflari',
                          'Авторы фотографий',
                          'Photo credits',
                        ),
                        subtitle: 'Wikimedia Commons',
                        onTap: _showPhotoCredits,
                      ),
                      ListRow(
                        icon: Icons.info_rounded,
                        tone: Tone.neutral,
                        title: 'AgroZen 1.0',
                        subtitle: _t(
                          "Ross-308 / Cobb-500 me'yorlari · asosiy qismi internetsiz ishlaydi",
                          'Нормы Ross-308 / Cobb-500 · основное работает без интернета',
                          'Ross-308 / Cobb-500 norms · core features work offline',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Farm photo with the farmer's avatar, name (tap to edit), place and a
  /// one-line batch summary.
  Widget _buildProfile(FarmSnapshot farm) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const AgroChickIcon(size: 56),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.farmerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.metric,
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    StatusPill(
                      label: '${_fmt.day(farm.batchDay)} · ${farm.phaseName()}',
                      tone: Tone.primary,
                    ),
                    StatusPill(label: _fmt.birds(farm.currentCount)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _t('Ismni o\'zgartirish', 'Изменить имя', 'Edit name'),
            onPressed: _editName,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Square language choice: flag, native name, check when selected.
class _LanguageTile extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        color: selected ? AppColors.primarySoft : null,
        borderColor: selected ? AppColors.primary : null,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Column(
          children: [
            AgroFlagBadge(code: code, size: 36),
            const SizedBox(height: AppSpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: AppText.label),
            ),
          ],
        ),
      ),
    );
  }
}
