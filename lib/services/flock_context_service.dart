import '../config/constants.dart';
import '../data/models/weather_data.dart';
import '../domain/broiler/broiler_grower_library.dart';
import '../data/repositories/knowledge_repository.dart';
import '../domain/alerts/alert_models.dart';
import '../domain/scheduler/day_calculator.dart';
import 'daily_counters.dart';
import 'weather_service.dart';

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
  final double? outsideTemp;
  final int? outsideHumidity;
  final String? weatherCondition;
  final double? windSpeed;

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
    this.outsideTemp,
    this.outsideHumidity,
    this.weatherCondition,
    this.windSpeed,
  });

  /// Total recommended flock feed in kilograms for today based on bird count and norm.
  double get recommendedFlockFeedKg =>
      (currentCount * targetDailyFeedPerBirdG) / 1000.0;

  /// Returns a clean, structured context prompt block to prepend to any AI query.
  String toPromptContextBlock(String lang) {
    final isRu = lang == 'ru';
    final isEn = lang == 'en';

    final hasWeather = outsideTemp != null;
    final outT = outsideTemp ?? 24.0;
    final outH = outsideHumidity ?? 50;
    final cond = weatherCondition ?? 'clear';
    final wind = windSpeed ?? 10.0;
    final tempDelta = outT - targetTemperatureC;
    final isHotDelta = tempDelta >= 4.0 || (outT >= 32.0 && tempDelta >= 0.0);
    final isColdDelta = tempDelta < -8.0 || outT <= 14.0;

    if (isEn) {
      final weatherAdvisory = isHotDelta
          ? '  ⚠ HOT WEATHER ADVISORY: Outside (${outT.toStringAsFixed(1)}°C) is significantly above flock target (${targetTemperatureC.toStringAsFixed(1)}°C). Advise tunnel ventilation (2-2.5 m/s), check evaporative cooling pads if RH<70%, ensure water lines remain chilled (<20°C), and shift heavy feeding to cooler night hours.'
          : (isColdDelta
              ? '  ❄ COLD WEATHER ADVISORY: Outside (${outT.toStringAsFixed(1)}°C) is much colder than house target (${targetTemperatureC.toStringAsFixed(1)}°C). Enforce minimum ventilation timer without floor drafts, pre-heat incoming fresh air, and ensure brooder heaters keep bedding warm.'
              : '  ✓ Outside temperature (${outT.toStringAsFixed(1)}°C) is moderate relative to flock target (${targetTemperatureC.toStringAsFixed(1)}°C).');

      final weatherBlock = hasWeather
          ? '''\n• Outdoor Telemetry ($district): ${outT.toStringAsFixed(1)}°C, $outH% RH, Condition: $cond (Wind: ${wind.toStringAsFixed(1)} km/h)
• Climate Differential: Outside is ${tempDelta >= 0 ? '+${tempDelta.toStringAsFixed(1)}°C warmer' : '${tempDelta.toStringAsFixed(1)}°C cooler'} than house target (${targetTemperatureC.toStringAsFixed(1)}°C)
$weatherAdvisory'''
          : '';

      return '''[LIVE FLOCK DOSSIER - AGROZEN]:
• Farmer: $farmerName, Region: $district, Uzbekistan
• Flock: Ross-308 / Cobb-500 Broilers, Day $batchDay of 42 (Phase: $growthPhase)
• Birds: $currentCount alive (Initial: $initialCount, Today's mortality: $todayMortality)
• Current Feed: ${todayFeedKg.toStringAsFixed(1)} kg logged today (Target norm: ~${recommendedFlockFeedKg.toStringAsFixed(1)} kg [${targetDailyFeedPerBirdG.toStringAsFixed(0)}g/bird])
• Current Weight: ${lastWeightG > 0 ? '${lastWeightG.toStringAsFixed(0)}g' : 'Not weighed yet'} (Target benchmark: ~${targetWeightG.toStringAsFixed(0)}g)
• Target House Temperature: ${targetTemperatureC.toStringAsFixed(1)}°C$weatherBlock
• Local Veterinarian on duty: ${localVet != null ? '${localVet!['name']} (${localVet!['phone']})' : 'District Veterinary Department'}
---''';
    } else if (isRu) {
      final weatherAdvisory = isHotDelta
          ? '  ⚠ ПРЕДУПРЕЖДЕНИЕ О ЖАРЕ: На улице (${outT.toStringAsFixed(1)}°C) существенно жарче нормы птичника (${targetTemperatureC.toStringAsFixed(1)}°C). Рекомендуйте туннельную вентиляцию (2-2.5 м/с), охлаждающие панели при влажности <70%, прохладную воду в поилках (<20°C) и перенос обильного кормления на прохладные ночные часы.'
          : (isColdDelta
              ? '  ❄ ПРЕДУПРЕЖДЕНИЕ О ХОЛОДЕ: На улице (${outT.toStringAsFixed(1)}°C) намного холоднее нормы птичника (${targetTemperatureC.toStringAsFixed(1)}°C). Обеспечьте минимальную вентиляцию по таймеру без сквозняков по полу, подогревайте приточный воздух и следите за работой обогревателей.'
              : '  ✓ Температура на улице (${outT.toStringAsFixed(1)}°C) умеренная относительно нормы птичника (${targetTemperatureC.toStringAsFixed(1)}°C).');

      final weatherBlock = hasWeather
          ? '''\n• Погода на улице ($district): ${outT.toStringAsFixed(1)}°C, влажность $outH%, $cond (ветер ${wind.toStringAsFixed(1)} км/ч)
• Разница температур: Снаружи на ${tempDelta >= 0 ? '+${tempDelta.toStringAsFixed(1)}°C теплее' : '${tempDelta.toStringAsFixed(1)}°C холоднее'} нормы в птичнике (${targetTemperatureC.toStringAsFixed(1)}°C)
$weatherAdvisory'''
          : '';

      return '''[ДОСЬЕ ТЕКУЩЕЙ ПАРТИИ - AGROZEN]:
• Фермер: $farmerName, Район: $district, Узбекистан
• Партия: Бройлеры Ross-308 / Cobb-500, День $batchDay из 42 (Фаза: $growthPhase)
• Поголовье: $currentCount живых (Начальное: $initialCount, Падёж за сутки: $todayMortality)
• Корм: ${todayFeedKg.toStringAsFixed(1)} кг внесено сегодня (Норма Ross-308: ~${recommendedFlockFeedKg.toStringAsFixed(1)} кг [${targetDailyFeedPerBirdG.toStringAsFixed(0)}г/голову])
• Контрольный вес: ${lastWeightG > 0 ? '${lastWeightG.toStringAsFixed(0)}г' : 'Ещё не взвешивали'} (Эталонная норма: ~${targetWeightG.toStringAsFixed(0)}г)
• Норма температуры в птичнике: ${targetTemperatureC.toStringAsFixed(1)}°C$weatherBlock
• Дежурный районный ветеринар: ${localVet != null ? '${localVet!['name']} (${localVet!['phone']})' : 'Районная ветслужба'}
---''';
    } else {
      final weatherAdvisory = isHotDelta
          ? '  ⚠ JAZIRAMA ISSIQ OGOHLANTIRISHI: Tashqarida (${outT.toStringAsFixed(1)}°C) xona me\'yoridan (${targetTemperatureC.toStringAsFixed(1)}°C) ancha issiq. Tunnel ventilyatsiya (2-2.5 m/s), namlik <70% bo\'lsa sovutish panellari, quvurlardagi sovuq suv (<20°C) va kechki salqinda yemlashni maslahat bering.'
          : (isColdDelta
              ? '  ❄ SOVUQ HAVO ESLATMASI: Tashqarida (${outT.toStringAsFixed(1)}°C) xona me\'yoridan (${targetTemperatureC.toStringAsFixed(1)}°C) ancha sovuq. Pol sathida skvoznyaksiz minimal ventilyatsiya qiling, kiruvchi havoni iliting va jo\'jalar to\'planib qolmasligi uchun isitgichlarni nazorat qiling.'
              : '  ✓ Tashqi harorat (${outT.toStringAsFixed(1)}°C) xona me\'yoriga (${targetTemperatureC.toStringAsFixed(1)}°C) nisbatan mo\'tadil.');

      final weatherBlock = hasWeather
          ? '''\n• Tashqi ob-havo ($district): ${outT.toStringAsFixed(1)}°C, namlik $outH%, $cond (shamol ${wind.toStringAsFixed(1)} km/s)
• Harorat farqi: Tashqari xona me'yoridan (${targetTemperatureC.toStringAsFixed(1)}°C) ${tempDelta >= 0 ? '+${tempDelta.toStringAsFixed(1)}°C issiqroq' : '${tempDelta.toStringAsFixed(1)}°C sovuqroq'}
$weatherAdvisory'''
          : '';

      return '''[JORIY PARTIYA VA FERMER DOSYESI - AGROZEN]:
• Fermer: $farmerName, Hudud: $district, O'zbekiston
• Partiya: Ross-308 / Cobb-500 broylerlari, $batchDay-kun (42 kundan, Bosqich: $growthPhase)
• Bosh soni: $currentCount ta tirik (Boshlang'ich: $initialCount ta, Bugungi nobodlik: $todayMortality ta)
• Bugungi yem: ${todayFeedKg.toStringAsFixed(1)} kg berildi (Ross-308 me'yori: ~${recommendedFlockFeedKg.toStringAsFixed(1)} kg [${targetDailyFeedPerBirdG.toStringAsFixed(0)}g/bosh])
• O'rtacha vazn: ${lastWeightG > 0 ? '${lastWeightG.toStringAsFixed(0)}g' : "Hali tortilmadi"} (Me'yoriy andoza: ~${targetWeightG.toStringAsFixed(0)}g)
• Xonadagi me'yoriy harorat: ${targetTemperatureC.toStringAsFixed(1)}°C$weatherBlock
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
    final district =
        prefs.getString('farmer_district') ?? AppConstants.defaultDistrict;
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
    // Fallbacks come from the same norms table (BroilerGrowerLibrary mirrors
    // knowledge/norms.json), so the AI never sees different numbers.
    final spec = BroilerGrowerLibrary.specForDay(batchDay);
    final targetTemp =
        norms?.temperatureTargetForDay(batchDay) ?? spec.targetTempC;
    final targetWeightG =
        norms?.weightTargetForDay(batchDay) ?? spec.targetWeightG;
    final targetDailyFeedPerBirdG =
        norms?.feedTargetForDay(batchDay) ?? spec.dailyFeedPerBirdG;

    final growthPhase = spec.phaseTitle(language);

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

    // Live Outdoor Weather
    WeatherData? weather;
    try {
      weather = await WeatherService().getDistrictWeather(district).timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () => WeatherData.fallback(district),
          );
    } catch (_) {
      weather = WeatherData.fallback(district);
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
      outsideTemp: weather.temperature,
      outsideHumidity: weather.humidity,
      weatherCondition: weather.condition,
      windSpeed: weather.windSpeed,
    );
  }
}
