import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrozen/domain/alerts/alert_engine.dart';
import 'package:agrozen/domain/alerts/alert_models.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/alert_card.dart';
import 'package:agrozen/services/daily_counters.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  String _lang = 'uz';
  int _initialCount = 500;
  int _currentCount = 495;
  int _todayMortality = 0;
  double _todayFeed = 0.0;
  double _lastWeight = 0.0;
  AlertResult? _activeAlert;
  Map<String, dynamic>? _vet;
  bool _isLoading = true;

  final KnowledgeRepository _knowledgeRepo = KnowledgeRepository();

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    setState(() => _isLoading = true);
    final prefs = await DailyCounters.rolled();
    _lang = prefs.getString('app_language') ?? 'uz';
    _initialCount = prefs.getInt('initial_count') ?? 500;
    _currentCount = prefs.getInt('current_count') ?? _initialCount;
    _todayMortality = DailyCounters.getMortality(prefs);
    _todayFeed = DailyCounters.getFeed(prefs);
    _lastWeight = prefs.getDouble('last_weight') ?? 0.0;

    final district = prefs.getString('farmer_district') ?? 'Toshkent';
    final vets = await _knowledgeRepo.getVetByDistrict(district);
    if (vets.isNotEmpty) {
      _vet = vets.first;
    }

    // Evaluate the alert against the vet-verified norms.
    if (_todayMortality > 0) {
      final norms = await _knowledgeRepo.getParsedNorms();
      final engine = AlertEngine(norms);
      _activeAlert = engine.checkMortality(
        deaths: _todayMortality,
        currentCount: _currentCount,
      );
    } else {
      _activeAlert = null;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Дневник партии' : 'Partiya kundaligi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDiary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            icon: Icons.pets,
                            label: isRu ? 'Живых' : 'Tirik',
                            value: '$_currentCount',
                            color: Colors.green.shade800,
                          ),
                          _buildSummaryItem(
                            icon: Icons.remove_circle_outline,
                            label: isRu ? 'Падёж сегодня' : 'Nobodlik',
                            value: '$_todayMortality',
                            color: Colors.red.shade700,
                          ),
                          _buildSummaryItem(
                            icon: Icons.scale,
                            label: isRu ? 'Вес (ср.)' : "O'rtacha vazn",
                            value: _lastWeight > 0 ? '${_lastWeight.toInt()} г' : '-',
                            color: Colors.teal.shade800,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_activeAlert != null)
                      AlertCard.fromAlertResult(
                        alert: _activeAlert!,
                        locale: _lang,
                        vetName: _vet?['name'] as String?,
                        vetPhone: _vet?['phone'] as String?,
                      ),

                    // Log action buttons
                    Text(
                      isRu ? 'Новая запись' : 'Yangi yozuv kiritish',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    _buildEntryCard(
                      icon: Icons.heart_broken_rounded,
                      color: Colors.red.shade700,
                      title: isRu ? 'Записать падёж' : 'Nobodlik yozish',
                      subtitle: isRu
                          ? 'Укажите количество погибших птиц за сутки'
                          : 'Bugun nobud bo\'lgan parrandalar soni',
                      onTap: () async {
                        await context.push('/diary/mortality');
                        _loadDiary();
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildEntryCard(
                      icon: Icons.grain_rounded,
                      color: Colors.amber.shade900,
                      title: isRu ? 'Записать расход корма' : 'Yem sarfini yozish',
                      subtitle: isRu
                          ? 'Укажите израсходованный комбикорм (кг)'
                          : 'Bugun berilgan yem miqdori (kg)',
                      onTap: () async {
                        await context.push('/diary/feed');
                        _loadDiary();
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildEntryCard(
                      icon: Icons.scale_rounded,
                      color: Colors.teal.shade700,
                      title: isRu ? 'Записать контрольный вес' : 'Nazorat vaznini yozish',
                      subtitle: isRu
                          ? 'Средний вес одной птицы при взвешивании (грамм)'
                          : 'Parrandaning o\'rtacha vazni (gramm)',
                      onTap: () async {
                        await context.push('/diary/weight');
                        _loadDiary();
                      },
                    ),

                    const SizedBox(height: 24),
                    Text(
                      isRu ? 'Сегодняшние показатели' : 'Bugungi qaydlar',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.remove_circle, color: Colors.red),
                            title: Text(isRu ? 'Падёж за сутки' : 'Sutkalik nobodlik'),
                            trailing: Text(
                              '$_todayMortality ${isRu ? 'голов' : 'bosh'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.grain, color: Colors.amber),
                            title: Text(isRu ? 'Корм за сутки' : 'Sutkalik yem'),
                            trailing: Text(
                              '${_todayFeed.toStringAsFixed(1)} кг',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.scale, color: Colors.teal),
                            title: Text(isRu ? 'Последний замер веса' : "So'nggi o'lchangan vazn"),
                            trailing: Text(
                              _lastWeight > 0 ? '${_lastWeight.toStringAsFixed(0)} г' : '-',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildEntryCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
