import '../data/repositories/knowledge_repository.dart';
import '../domain/alerts/alert_models.dart';
import '../domain/scheduler/day_calculator.dart';
import 'daily_counters.dart';

/// Represents a turn in the ongoing conversation for multi-turn context memory.
class ConversationTurn {
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;

  ConversationTurn({
    required this.role,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Comprehensive live dossier of the farmer's current flock status,
/// verified Ross-308 / Cobb-500 standard targets, and recent logs.
class LiveFlockContext {
  final String farmerName;
  final String district;
  final String language;
  final int batchDay;
  final int initialCount;
  final int currentCount;
  final int todayMortality;
  final double todayFeedKg;
  final double lastWeightG;
  final double targetTemperatureC;
  final double targetDailyFeedPerBirdG;
  final double targetWeightG;
  final String growthPhase;
  final Map<String, dynamic>? localVet;

  const LiveFlockContext({
    required this.farmerName,
    required this.district,
    required this.language,
    required this.batchDay,
    required this.initialCount,
    required this.currentCount,
    required this.todayMortality,
    required this.todayFeedKg,
    required this.lastWeightG,
    required this.targetTemperatureC,
    required this.targetDailyFeedPerBirdG,
    required this.targetWeightG,
    required this.growthPhase,
    this.localVet,
  });

  /// Total recommended flock feed in kilograms for today based on bird count and norm.
  double get recommendedFlockFeedKg =>
      (currentCount * targetDailyFeedPerBirdG) / 1000.0;

  /// Returns a clean, structured context prompt block to prepend to any AI query.
  String toPromptContextBlock(String lang) {
    final isRu = lang == 'ru';
    final isEn = lang == 'en';

    if (isEn) {
      return '''[LIVE FLOCK DOSSIER - AGROZEN]:
• Farmer: $farmerName, Region: $district, Uzbekistan
• Flock: Ross-308 / Cobb-500 Broilers, Day $batchDay of 42 (Phase: $growthPhase)
• Birds: $currentCount alive (Initial: $initialCount, Today's mortality: $todayMortality)
• Current Feed: ${todayFeedKg.toStringAsFixed(1)} kg logged today (Target norm: ~${recommendedFlockFeedKg.toStringAsFixed(1)} kg [${targetDailyFeedPerBirdG.toStringAsFixed(0)}g/bird])
• Current Weight: ${lastWeightG > 0 ? '${lastWeightG.toStringAsFixed(0)}g' : 'Not weighed yet'} (Target benchmark: ~${targetWeightG.toStringAsFixed(0)}g)
• Target House Temperature: ${targetTemperatureC.toStringAsFixed(1)}°C
• Local Veterinarian on duty: ${localVet != null ? '${localVet!['name']} (${localVet!['phone']})' : 'District Veterinary Department'}
---''';
    } else if (isRu) {
      return '''[ДОСЬЕ ТЕКУЩЕЙ ПАРТИИ - AGROZEN]:
• Фермер: $farmerName, Район: $district, Узбекистан
• Партия: Бройлеры Ross-308 / Cobb-500, День $batchDay из 42 (Фаза: $growthPhase)
• Поголовье: $currentCount живых (Начальное: $initialCount, Падёж за сутки: $todayMortality)
• Корм: ${todayFeedKg.toStringAsFixed(1)} кг внесено сегодня (Норма Ross-308: ~${recommendedFlockFeedKg.toStringAsFixed(1)} кг [${targetDailyFeedPerBirdG.toStringAsFixed(0)}г/голову])
• Контрольный вес: ${lastWeightG > 0 ? '${lastWeightG.toStringAsFixed(0)}г' : 'Ещё не взвешивали'} (Эталонная норма: ~${targetWeightG.toStringAsFixed(0)}г)
• Норма температуры в птичнике: ${targetTemperatureC.toStringAsFixed(1)}°C
• Дежурный районный ветеринар: ${localVet != null ? '${localVet!['name']} (${localVet!['phone']})' : 'Районная ветслужба'}
---''';
    } else {
      return '''[JORIY PARTIYA VA FERMER DOSYESI - AGROZEN]:
• Fermer: $farmerName, Hudud: $district, O'zbekiston
• Partiya: Ross-308 / Cobb-500 broylerlari, $batchDay-kun (42 kundan, Bosqich: $growthPhase)
• Bosh soni: $currentCount ta tirik (Boshlang'ich: $initialCount ta, Bugungi nobodlik: $todayMortality ta)
• Bugungi yem: ${todayFeedKg.toStringAsFixed(1)} kg berildi (Ross-308 me'yori: ~${recommendedFlockFeedKg.toStringAsFixed(1)} kg [${targetDailyFeedPerBirdG.toStringAsFixed(0)}g/bosh])
• O'rtacha vazn: ${lastWeightG > 0 ? '${lastWeightG.toStringAsFixed(0)}g' : "Hali tortilmadi"} (Me'yoriy andoza: ~${targetWeightG.toStringAsFixed(0)}g)
• Xonadagi me'yoriy harorat: ${targetTemperatureC.toStringAsFixed(1)}°C
• Tuman veterinari: ${localVet != null ? '${localVet!['name']} (${localVet!['phone']})' : "Tuman veterinariya bo'limi"}
---''';
    }
  }
}

/// Singleton manager for compiling real-time farm context and storing
/// conversation memory across chat turns.
class FlockContextService {
  static final FlockContextService _instance = FlockContextService._internal();
  factory FlockContextService() => _instance;
  FlockContextService._internal();

  final KnowledgeRepository _knowledgeRepo = KnowledgeRepository();
  final List<ConversationTurn> _recentTurns = [];
  static const int maxStoredTurns = 8;

  /// Adds a conversation turn to session memory.
  void recordTurn({required String role, required String text}) {
    _recentTurns.add(ConversationTurn(role: role, text: text));
    if (_recentTurns.length > maxStoredTurns) {
      _recentTurns.removeAt(0);
    }
  }

  /// Clears recent conversation memory.
  void clearHistory() {
    _recentTurns.clear();
  }

  /// Returns recent conversation history formatted for context injection.
  String getConversationHistorySnippet(String lang) {
    if (_recentTurns.isEmpty) return '';

    final buffer = StringBuffer();
    final header = lang == 'en'
        ? '[RECENT CONVERSATION HISTORY]:\n'
        : (lang == 'ru'
            ? '[ИСТОРИЯ ПОСЛЕДНИХ ВОПРОСОВ]:\n'
            : "[OXIRGI SUHBAT TARIXI]:\n");
    buffer.write(header);

    for (final turn in _recentTurns) {
      final roleLabel = turn.role == 'user'
          ? (lang == 'en' ? 'Farmer' : (lang == 'ru' ? 'Фермер' : 'Fermer'))
          : 'AgroZen';
      buffer.writeln('$roleLabel: ${turn.text}');
    }
    buffer.writeln('---');
    return buffer.toString();
  }

  /// Compiles the full live flock context from SharedPreferences and knowledge norms.
  Future<LiveFlockContext> getLiveContext() async {
    final prefs = await DailyCounters.rolled();

    final farmerName = prefs.getString('farmer_name') ?? 'Fermer';
    final district = prefs.getString('farmer_district') ?? 'Toshkent';
    final language = prefs.getString('app_language') ?? 'uz';
    final initialCount = prefs.getInt('initial_count') ?? 500;
    final currentCount = prefs.getInt('current_count') ?? initialCount;

    final arrivalStr = prefs.getString('arrival_date');
    DateTime arrivalDate = DateTime.now();
    if (arrivalStr != null) {
      arrivalDate = DateTime.tryParse(arrivalStr) ?? DateTime.now();
    }
    final batchDay = DayCalculator.calculateBatchDay(arrivalDate).clamp(1, 42);

    final todayMortality = DailyCounters.getMortality(prefs);
    final todayFeedKg = DailyCounters.getFeed(prefs);
    final lastWeightG = prefs.getDouble('last_weight') ?? 0.0;

    NormsData? norms;
    try {
      norms = await _knowledgeRepo.getParsedNorms();
    } catch (_) {
      norms = null;
    }

    // Target Temperature
    final targetTemp = norms?.temperatureTargetForDay(batchDay) ??
        _fallbackTempForDay(batchDay);

    final targetWeightG = norms?.weightTargetForDay(batchDay) ??
        _fallbackTargetWeight(batchDay);

    final targetDailyFeedPerBirdG = norms?.dailyFeedPerBird[batchDay] ??
        _fallbackDailyFeedPerBird(batchDay);

    // Growth Phase
    final growthPhase = _resolveGrowthPhase(batchDay, language);

    // Local Vet
    Map<String, dynamic>? localVet;
    try {
      final vets = await _knowledgeRepo.getVetByDistrict(district);
      if (vets.isNotEmpty) {
        localVet = vets.first;
      }
    } catch (_) {
      localVet = null;
    }

    return LiveFlockContext(
      farmerName: farmerName,
      district: district,
      language: language,
      batchDay: batchDay,
      initialCount: initialCount,
      currentCount: currentCount,
      todayMortality: todayMortality,
      todayFeedKg: todayFeedKg,
      lastWeightG: lastWeightG,
      targetTemperatureC: targetTemp,
      targetDailyFeedPerBirdG: targetDailyFeedPerBirdG,
      targetWeightG: targetWeightG,
      growthPhase: growthPhase,
      localVet: localVet,
    );
  }

  static String _resolveGrowthPhase(int day, String lang) {
    if (day <= 7) {
      return lang == 'en' ? 'Starter' : (lang == 'ru' ? 'Старт (1-7 дни)' : "Start (1-7 kunlar)");
    } else if (day <= 21) {
      return lang == 'en' ? 'Grower' : (lang == 'ru' ? 'Рост (8-21 дни)' : "O'sish (8-21 kunlar)");
    } else {
      return lang == 'en' ? 'Finisher' : (lang == 'ru' ? 'Финиш (22-42 дни)' : "Finish (22-42 kunlar)");
    }
  }

  static double _fallbackTempForDay(int day) {
    if (day <= 2) return 34.0;
    if (day <= 4) return 33.0;
    if (day <= 7) return 30.0;
    if (day <= 14) return 27.0;
    if (day <= 21) return 24.0;
    if (day <= 28) return 21.0;
    if (day <= 35) return 19.0;
    return 18.0;
  }

  static double _fallbackDailyFeedPerBird(int day) {
    if (day <= 7) return 24.0;
    if (day <= 14) return 54.0;
    if (day <= 21) return 95.0;
    if (day <= 28) return 140.0;
    if (day <= 35) return 175.0;
    return 195.0;
  }

  static double _fallbackTargetWeight(int day) {
    if (day <= 7) return 185.0;
    if (day <= 14) return 465.0;
    if (day <= 21) return 975.0;
    if (day <= 28) return 1600.0;
    if (day <= 35) return 2280.0;
    return 2900.0;
  }
}
