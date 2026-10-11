import 'dart:math' as math;
import '../../core/localization/app_strings.dart';

/// Day-by-day scientific specification for Ross-308 / Cobb-500 broiler growth (Days 1–42).
class BroilerDaySpec {
  final int day;
  final String phaseKey;
  final double targetWeightG;
  final double dailyGainG;
  final double dailyFeedPerBirdG;
  final double cumulativeFeedPerBirdG;
  final double targetFcr;
  final double dailyWaterPerBirdMl;
  final double targetTempC;
  final int humidityMinPct;
  final int humidityMaxPct;
  final int lightHours;
  final int darkHours;
  final int lightIntensityLux;
  final double crudeProteinPct;
  final int metabolizableEnergyKcal;
  final int maxBirdsPerSqMeter;
  final double minAirflowM3PerHrPerKg;

  const BroilerDaySpec({
    required this.day,
    required this.phaseKey,
    required this.targetWeightG,
    required this.dailyGainG,
    required this.dailyFeedPerBirdG,
    required this.cumulativeFeedPerBirdG,
    required this.targetFcr,
    required this.dailyWaterPerBirdMl,
    required this.targetTempC,
    required this.humidityMinPct,
    required this.humidityMaxPct,
    required this.lightHours,
    required this.darkHours,
    required this.lightIntensityLux,
    required this.crudeProteinPct,
    required this.metabolizableEnergyKcal,
    required this.maxBirdsPerSqMeter,
    required this.minAirflowM3PerHrPerKg,
  });

  String phaseTitle(String lang) {
    switch (phaseKey) {
      case 'pre_starter':
        return AppStrings.tr(
          lang: lang,
          uz: 'Pre-Start (1–4 kun)',
          ru: 'Пре-Старт (1–4 дни)',
          en: 'Pre-Starter (Days 1–4)',
        );
      case 'starter':
        return AppStrings.tr(
          lang: lang,
          uz: 'Start (5–10 kun)',
          ru: 'Старт (5–10 дни)',
          en: 'Starter (Days 5–10)',
        );
      case 'grower':
        return AppStrings.tr(
          lang: lang,
          uz: "O'sish / Grower (11–24 kun)",
          ru: 'Рост / Гроуэр (11–24 дни)',
          en: 'Grower (Days 11–24)',
        );
      case 'finisher_1':
        return AppStrings.tr(
          lang: lang,
          uz: 'Finish-1 (25–35 kun)',
          ru: 'Финиш-1 (25–35 дни)',
          en: 'Finisher 1 (Days 25–35)',
        );
      default:
        return AppStrings.tr(
          lang: lang,
          uz: 'Finish-2 / Yakuniy (36–42 kun)',
          ru: 'Финиш-2 / Финал (36–42 дни)',
          en: 'Finisher 2 / Withdrawal (Days 36–42)',
        );
    }
  }

  String feedFormDescription(String lang) {
    switch (phaseKey) {
      case 'pre_starter':
        return AppStrings.tr(
          lang: lang,
          uz: 'Mayda krupka (1.5 mm) • 23% oqsil',
          ru: 'Микро-крупка (1.5 мм) • 23% протеин',
          en: 'Micro-crumble (1.5 mm) • 23% CP',
        );
      case 'starter':
        return AppStrings.tr(
          lang: lang,
          uz: 'Yirik krupka (2.0 mm) • 22% oqsil',
          ru: 'Крупка (2.0 мм) • 22% протеин',
          en: 'Sieved crumble (2.0 mm) • 22% CP',
        );
      case 'grower':
        return AppStrings.tr(
          lang: lang,
          uz: 'Granula (3.0 mm) • 20.5% oqsil',
          ru: 'Гранула (3.0 мм) • 20.5% протеин',
          en: 'Pellet (3.0 mm) • 20.5% CP',
        );
      case 'finisher_1':
        return AppStrings.tr(
          lang: lang,
          uz: 'Granula (3.5 mm) • 19% oqsil',
          ru: 'Гранула (3.5 мм) • 19% протеин',
          en: 'Pellet (3.5 mm) • 19% CP',
        );
      default:
        return AppStrings.tr(
          lang: lang,
          uz: 'Granula (3.5 mm, dorisiz) • 18% oqsil',
          ru: 'Гранула (3.5 мм, без кокцидиостатиков) • 18% протеин',
          en: 'Withdrawal Pellet (3.5 mm) • 18% CP',
        );
    }
  }

  String dailyFocusTip(String lang) {
    if (day <= 3) {
      return AppStrings.tr(
        lang: lang,
        uz: "Zob to'lishini tekshiring (24 soatda >95% jo'jada zob yumshoq va to'la bo'lishi shart). Pol harorati 30–32°C.",
        ru: 'Проверьте наполняемость зоба (через 24 ч у >95% цыплят зоб мягкий и полный). Пол 30–32°C.',
        en: 'Check crop fill (>95% soft, full crops at 24h). Keep litter floor temperature at 30–32°C.',
      );
    } else if (day <= 7) {
      return AppStrings.tr(
        lang: lang,
        uz: "Nippel balandligini jo'ja ko'zi sathidan biroz balandroq ko'taring va 7-kuni 1-haftalik nazorat tortishni (185 g+) o'tkazing.",
        ru: 'Поднимите ниппели чуть выше уровня глаз цыплят и проведите контрольное взвешивание на 7-й день (норма 185 г+).',
        en: 'Raise nipple lines slightly above eye level and perform Day-7 benchmark weighing (target 185g+).',
      );
    } else if (day <= 14) {
      return AppStrings.tr(
        lang: lang,
        uz: "Krupkadan 3 mm granulaga 3 kun davomida aralashtirib o'ting. Skelet mustahkamligi uchun kuniga 6 soat qorong'ulik bering.",
        ru: 'Плавно переходите с крупки на гранулу 3 мм за 3 дня. Обеспечьте 6 часов темноты в сутки для крепости костей.',
        en: 'Transition from crumble to 3mm pellets over 3 days. Provide 6h darkness daily for leg skeletal strength.',
      );
    } else if (day <= 21) {
      return AppStrings.tr(
        lang: lang,
        uz: "To'shama namligini 25–30% atrofida saqlang; ammiak hidi sezilsa minimal ventilyatsiyani 20% ga oshiring.",
        ru: 'Держите влажность подстилки 25–30%; при запахе аммиака увеличьте минимальную вентиляцию на 20%.',
        en: 'Keep litter moisture at 25–30%; increase minimum ventilation by 20% if any ammonia odor is detected.',
      );
    } else if (day <= 35) {
      return AppStrings.tr(
        lang: lang,
        uz: "Katta vazndagi broylerlar ko'p issiqlik chiqaradi: havo tezligini 2.0–2.5 m/s ga yetkazing va suvni <20°C salqin tuting.",
        ru: 'Крупная птица выделяет много тепла: держите скорость воздуха 2.0–2.5 м/с и прохладную воду (<20°C).',
        en: 'Heavy broilers generate high metabolic heat: maintain 2.0–2.5 m/s airflow and cool water (<20°C).',
      );
    } else {
      return AppStrings.tr(
        lang: lang,
        uz: "So'yishdan 5–7 kun oldin dorivor qo'shimchalarni to'xtating, ushlashdan 8–10 soat oldin yemni yig'ishtiring (suv qoladi).",
        ru: 'За 5–7 дней до убоя исключите ветпрепараты, за 8–10 часов до отлова уберите корм (вода остаётся в свободном доступе).',
        en: 'Observe 5–7 day withdrawal before harvest; remove feed 8–10 hours prior to catching while keeping water available.',
      );
    }
  }
}

/// Calculated daily resource requirements and equipment norms for a specific flock size.
class FlockDailyRequirements {
  final BroilerDaySpec spec;
  final int birdCount;
  final double totalDailyFeedKg;
  final double totalCumulativeFeedKg;
  final double totalDailyWaterLiters;
  final double heatStressWaterMultiplier;
  final int recommendedNipples;
  final int recommendedFeederPans;
  final double requiredBarnAreaCurrentSqM;
  final double requiredBarnAreaHarvestSqM;
  final double currentBiomassKg;

  const FlockDailyRequirements({
    required this.spec,
    required this.birdCount,
    required this.totalDailyFeedKg,
    required this.totalCumulativeFeedKg,
    required this.totalDailyWaterLiters,
    required this.heatStressWaterMultiplier,
    required this.recommendedNipples,
    required this.recommendedFeederPans,
    required this.requiredBarnAreaCurrentSqM,
    required this.requiredBarnAreaHarvestSqM,
    required this.currentBiomassKg,
  });
}

/// Evaluation result for Feed Conversion Ratio (FCR) and European Production Efficiency Factor (EPEF).
class BroilerEfficiencyReport {
  final int batchDay;
  final int initialCount;
  final int currentCount;
  final double livabilityPct;
  final double actualWeightG;
  final double targetWeightG;
  final double weightDeltaPct;
  final double actualFcr;
  final double targetFcr;
  final int epefScore;
  final String grade; // 'A+', 'B', 'C'

  const BroilerEfficiencyReport({
    required this.batchDay,
    required this.initialCount,
    required this.currentCount,
    required this.livabilityPct,
    required this.actualWeightG,
    required this.targetWeightG,
    required this.weightDeltaPct,
    required this.actualFcr,
    required this.targetFcr,
    required this.epefScore,
    required this.grade,
  });

  String gradeSummary(String lang) {
    if (grade == 'A+') {
      return AppStrings.tr(
        lang: lang,
        uz: "A'lo natija (EPEF $epefScore)! Yem konversiyasi (FCR ${actualFcr.toStringAsFixed(2)}) va o'sish sur'ati Ross-308 etaloniga to'liq mos.",
        ru: 'Отличный результат (EPEF $epefScore)! Конверсия корма (FCR ${actualFcr.toStringAsFixed(2)}) и привес соответствуют эталону Ross-308.',
        en: 'Elite performance (EPEF $epefScore)! Feed conversion (FCR ${actualFcr.toStringAsFixed(2)}) and weight gain match Ross-308 benchmarks.',
      );
    } else if (grade == 'B') {
      return AppStrings.tr(
        lang: lang,
        uz: "Yaxshi ko'rsatkich (EPEF $epefScore). Yem sochilishini kamaytirish uchun yemdon balandligini jo'ja yelkasiga tenglang va suv oqimini tekshiring.",
        ru: 'Хороший показатель (EPEF $epefScore). Отрегулируйте высоту кормушек по спине птицы против россыпи корма и проверьте дебит воды.',
        en: 'Good performance (EPEF $epefScore). Adjust feeder pan height to bird back level to prevent feed spillage and verify water flow.',
      );
    } else {
      return AppStrings.tr(
        lang: lang,
        uz: "Diqqat talab (EPEF $epefScore, FCR ${actualFcr.toStringAsFixed(2)}). Harorat o'zgarishi, yem sifati yoki zichlikni tekshiring.",
        ru: 'Требует внимания (EPEF $epefScore, FCR ${actualFcr.toStringAsFixed(2)}). Проверьте перепады температуры, качество гранулы и плотность посадки.',
        en: 'Needs adjustment (EPEF $epefScore, FCR ${actualFcr.toStringAsFixed(2)}). Check house temperature swings, pellet quality, and stocking density.',
      );
    }
  }
}

/// Core Broiler Grower Library providing Ross-308 / Cobb-500 precision tables,
/// calculators, and diagnostic guides for Days 1–42.
class BroilerGrowerLibrary {
  BroilerGrowerLibrary._();

  // Key Ross-308 benchmark anchor points (Day -> [WeightG, DailyFeedG, TempC])
  static const Map<int, List<double>> _anchors = {
    1: [42.0, 12.0, 33.5],
    3: [72.0, 18.0, 32.0],
    7: [185.0, 36.0, 30.0],
    10: [305.0, 50.0, 28.5],
    14: [510.0, 74.0, 26.5],
    21: [1050.0, 118.0, 23.5],
    28: [1720.0, 156.0, 21.0],
    35: [2420.0, 188.0, 19.0],
    42: [3080.0, 210.0, 18.0],
  };

  static final List<BroilerDaySpec> _allDays = _build42DayMatrix();

  /// Returns the full 42-day Ross-308 specification table.
  static List<BroilerDaySpec> get allDays => _allDays;

  /// Returns the precision specification for [day] (clamped to 1..42).
  static BroilerDaySpec specForDay(int day) {
    final safeDay = day.clamp(1, 42);
    return _allDays[safeDay - 1];
  }

  static List<BroilerDaySpec> _build42DayMatrix() {
    final specs = <BroilerDaySpec>[];
    double cumulativeFeed = 0.0;
    double prevWeight = 42.0;

    for (int d = 1; d <= 42; d++) {
      final weight = _interpolate(d, 0);
      final feed = _interpolate(d, 1);
      final temp = _interpolate(d, 2);

      cumulativeFeed += feed;
      final gain = d == 1 ? 14.0 : math.max(14.0, weight - prevWeight);
      prevWeight = weight;

      final fcr = (cumulativeFeed / weight).clamp(0.28, 1.85);
      final waterMl = feed * (d <= 7 ? 2.0 : 1.85);

      final String phaseKey;
      final double cp;
      final int kcal;
      if (d <= 4) {
        phaseKey = 'pre_starter';
        cp = 23.0;
        kcal = 3000;
      } else if (d <= 10) {
        phaseKey = 'starter';
        cp = 22.0;
        kcal = 3020;
      } else if (d <= 24) {
        phaseKey = 'grower';
        cp = 20.5;
        kcal = 3120;
      } else if (d <= 35) {
        phaseKey = 'finisher_1';
        cp = 19.0;
        kcal = 3200;
      } else {
        phaseKey = 'finisher_2';
        cp = 18.0;
        kcal = 3220;
      }

      final int humidityMin = d <= 7 ? 60 : (d <= 21 ? 55 : 50);
      final int humidityMax = d <= 7 ? 70 : (d <= 21 ? 65 : 60);

      final int lightHours = d <= 3 ? 23 : (d <= 6 ? 20 : (d <= 35 ? 18 : 20));
      final int darkHours = 24 - lightHours;
      final int lux = d <= 6 ? 35 : 10;

      final int maxBirdsSqM = d <= 7
          ? 35
          : (d <= 14 ? 26 : (d <= 21 ? 20 : (d <= 28 ? 16 : 13)));

      final double minAirflow = d <= 7
          ? 0.7
          : (d <= 14 ? 1.1 : (d <= 21 ? 1.8 : (d <= 28 ? 2.6 : 3.8)));

      specs.add(
        BroilerDaySpec(
          day: d,
          phaseKey: phaseKey,
          targetWeightG: double.parse(weight.toStringAsFixed(0)),
          dailyGainG: double.parse(gain.toStringAsFixed(0)),
          dailyFeedPerBirdG: double.parse(feed.toStringAsFixed(0)),
          cumulativeFeedPerBirdG: double.parse(cumulativeFeed.toStringAsFixed(0)),
          targetFcr: double.parse(fcr.toStringAsFixed(2)),
          dailyWaterPerBirdMl: double.parse(waterMl.toStringAsFixed(0)),
          targetTempC: double.parse(temp.toStringAsFixed(1)),
          humidityMinPct: humidityMin,
          humidityMaxPct: humidityMax,
          lightHours: lightHours,
          darkHours: darkHours,
          lightIntensityLux: lux,
          crudeProteinPct: cp,
          metabolizableEnergyKcal: kcal,
          maxBirdsPerSqMeter: maxBirdsSqM,
          minAirflowM3PerHrPerKg: minAirflow,
        ),
      );
    }
    return specs;
  }

  static double _interpolate(int day, int valueIdx) {
    final keys = _anchors.keys.toList()..sort();
    if (_anchors.containsKey(day)) {
      return _anchors[day]![valueIdx];
    }
    int lowerDay = keys.first;
    int upperDay = keys.last;
    for (int i = 0; i < keys.length - 1; i++) {
      if (day > keys[i] && day < keys[i + 1]) {
        lowerDay = keys[i];
        upperDay = keys[i + 1];
        break;
      }
    }
    final t = (day - lowerDay) / (upperDay - lowerDay);
    final v0 = _anchors[lowerDay]![valueIdx];
    final v1 = _anchors[upperDay]![valueIdx];
    return v0 + (v1 - v0) * t;
  }

  /// Calculates exact daily feed, water, drinker, feeder, and barn space requirements for [birdCount].
  static FlockDailyRequirements calculateFlockRequirements({
    required int day,
    required int birdCount,
    double? outsideTempC,
  }) {
    final safeBirds = math.max(1, birdCount);
    final spec = specForDay(day);

    final dailyFeedKg = (safeBirds * spec.dailyFeedPerBirdG) / 1000.0;
    final cumulativeFeedKg = (safeBirds * spec.cumulativeFeedPerBirdG) / 1000.0;

    // Heat stress multiplier: +6.5% water intake per °C above 26°C outdoor/barn temperature
    double waterMultiplier = 1.0;
    if (outsideTempC != null && outsideTempC > 26.0) {
      waterMultiplier = (1.0 + (outsideTempC - 26.0) * 0.065).clamp(1.0, 1.85);
    }
    final dailyWaterL =
        ((safeBirds * spec.dailyWaterPerBirdMl) / 1000.0) * waterMultiplier;

    final nipples = (safeBirds / 11.0).ceil();
    final pans = (safeBirds / 50.0).ceil();
    final areaNow = safeBirds / spec.maxBirdsPerSqMeter;
    // Harvest density safe target: ~13 birds/m² (~34 kg/m² at 2.6-2.9 kg live weight)
    final areaHarvest = safeBirds / 13.0;
    final biomassKg = (safeBirds * spec.targetWeightG) / 1000.0;

    return FlockDailyRequirements(
      spec: spec,
      birdCount: safeBirds,
      totalDailyFeedKg: dailyFeedKg,
      totalCumulativeFeedKg: cumulativeFeedKg,
      totalDailyWaterLiters: dailyWaterL,
      heatStressWaterMultiplier: waterMultiplier,
      recommendedNipples: nipples,
      recommendedFeederPans: pans,
      requiredBarnAreaCurrentSqM: areaNow,
      requiredBarnAreaHarvestSqM: areaHarvest,
      currentBiomassKg: biomassKg,
    );
  }

  /// Evaluates flock FCR and European Production Efficiency Factor (EPEF).
  static BroilerEfficiencyReport evaluateEfficiency({
    required int batchDay,
    required int initialCount,
    required int currentCount,
    double? actualAverageWeightG,
    double? totalFeedConsumedKg,
  }) {
    final spec = specForDay(batchDay);
    final safeInitial = math.max(1, initialCount);
    final safeCurrent = currentCount.clamp(1, safeInitial);
    final livability = (safeCurrent / safeInitial) * 100.0;

    final weightG = (actualAverageWeightG != null && actualAverageWeightG > 0)
        ? actualAverageWeightG
        : spec.targetWeightG;
    final weightKg = weightG / 1000.0;

    final expectedTotalFeedKg =
        (safeCurrent * spec.cumulativeFeedPerBirdG) / 1000.0;
    final feedUsedKg = (totalFeedConsumedKg != null && totalFeedConsumedKg > 0)
        ? totalFeedConsumedKg
        : expectedTotalFeedKg;

    final totalLiveBiomassKg = safeCurrent * weightKg;
    final actualFcr = totalLiveBiomassKg > 0
        ? (feedUsedKg / totalLiveBiomassKg).clamp(0.4, 3.5)
        : spec.targetFcr;

    final epefRaw =
        ((livability * weightKg) / (math.max(1, batchDay) * actualFcr)) * 100.0;
    final epef = epefRaw.round().clamp(50, 550);

    final weightDeltaPct =
        ((weightG - spec.targetWeightG) / spec.targetWeightG) * 100.0;

    final String grade;
    if (epef >= 320 || (actualFcr <= spec.targetFcr * 1.05 && weightDeltaPct >= -5)) {
      grade = 'A+';
    } else if (epef >= 240 && weightDeltaPct >= -14) {
      grade = 'B';
    } else {
      grade = 'C';
    }

    return BroilerEfficiencyReport(
      batchDay: spec.day,
      initialCount: safeInitial,
      currentCount: safeCurrent,
      livabilityPct: livability,
      actualWeightG: weightG,
      targetWeightG: spec.targetWeightG,
      weightDeltaPct: weightDeltaPct,
      actualFcr: actualFcr,
      targetFcr: spec.targetFcr,
      epefScore: epef,
      grade: grade,
    );
  }
}

/// Default Smart Farmer Prompt Enhancer:
/// Transforms short, rough, or voice-transcribed farmer queries into structured,
/// context-rich Ross-308 broiler agronomy prompts.
class FarmerPromptEnhancer {
  FarmerPromptEnhancer._();

  /// Enhances a farmer's raw input into a structured, context-rich Ross-308 question
  /// suitable for displaying in the input box or sending to the AI advisor.
  static String enhanceFarmerPrompt({
    required String rawInput,
    required String lang,
    int batchDay = 1,
    int birdCount = 500,
    double? outsideTempC,
  }) {
    final trimmed = rawInput.trim();
    final req = BroilerGrowerLibrary.calculateFlockRequirements(
      day: batchDay,
      birdCount: birdCount,
      outsideTempC: outsideTempC,
    );
    final spec = req.spec;
    final lower = trimmed.toLowerCase();

    if (trimmed.isEmpty) {
      return AppStrings.tr(
        lang: lang,
        uz: "${spec.day}-kundagi $birdCount ta Ross-308 broylerlarim uchun (${spec.phaseTitle('uz')}) bugungi harorat (${spec.targetTempC}°C), yem (${req.totalDailyFeedKg.toStringAsFixed(1)} kg), suv (${req.totalDailyWaterLiters.toStringAsFixed(1)} L) va yorug'lik (${spec.lightHours} soat) me'yorlarini tushuntirib bering.",
        ru: "Для моих $birdCount бройлеров Ross-308 на ${spec.day}-й день (${spec.phaseTitle('ru')}) подробно распишите сегодняшние нормы температуры (${spec.targetTempC}°C), корма (${req.totalDailyFeedKg.toStringAsFixed(1)} кг), воды (${req.totalDailyWaterLiters.toStringAsFixed(1)} л) и освещения (${spec.lightHours} ч).",
        en: "For my $birdCount Ross-308 broilers on Day ${spec.day} (${spec.phaseTitle('en')}), explain today's exact targets for barn temperature (${spec.targetTempC}°C), feed (${req.totalDailyFeedKg.toStringAsFixed(1)} kg), water (${req.totalDailyWaterLiters.toStringAsFixed(1)} L), and lighting (${spec.lightHours}h).",
      );
    }

    // Topic-aware prompt expansion for short or conversational inputs
    final isFeedOrFcr = _matchesAny(lower, [
      'yem', 'ovqat', 'korm', 'корм', 'feed', 'fcr', 'konvers', 'конверс',
      'granul', 'krupka', 'oqsil', 'протеин', 'protein', 'starter', 'grower', 'finish',
    ]);
    final isWater = _matchesAny(lower, [
      'suv', 'nippel', 'vod', 'вод', 'поил', 'ниппел', 'water', 'drinker', 'nipple',
    ]);
    final isTempOrVent = _matchesAny(lower, [
      'harorat', 'issiq', 'sovuq', 'shamol', 'havo', 'ammiak', 'темп', 'жар',
      'холод', 'вентил', 'аммиак', 'temp', 'heat', 'cold', 'ventil', 'air', 'humidity', 'namlik',
    ]);
    final isLightOrDensity = _matchesAny(lower, [
      'yorug', 'chiroq', 'qorong', 'zichlik', 'joy', 'kvadrat', 'свет', 'темнот',
      'плотност', 'квадрат', 'light', 'dark', 'lux', 'density', 'space', 'area',
    ]);
    final isWeightOrGrowth = _matchesAny(lower, [
      'vazn', "o'sish", 'osish', 'semir', 'gramm', 'вес', 'рост', 'привес',
      'weight', 'grow', 'gain', 'heavy', 'bigger', 'broiler', 'boiler', 'chicken', "jo'ja",
    ]);

    if (isFeedOrFcr) {
      return AppStrings.tr(
        lang: lang,
        uz: "$trimmed — Partiyam ${spec.day}-kunda ($birdCount bosh, ${spec.phaseTitle('uz')}). Kunlik ${req.totalDailyFeedKg.toStringAsFixed(1)} kg (${spec.dailyFeedPerBirdG.toStringAsFixed(0)} g/bosh, ${spec.feedFormDescription('uz')}) yem berish va FCR (${spec.targetFcr}) samaradorligini yaxshilash bo'yicha aniq tavsiya bering.",
        ru: "$trimmed — Моя партия на ${spec.day}-м дне ($birdCount голов, ${spec.phaseTitle('ru')}). Дайте точные рекомендации по суточной норме ${req.totalDailyFeedKg.toStringAsFixed(1)} кг (${spec.dailyFeedPerBirdG.toStringAsFixed(0)} г/гол., ${spec.feedFormDescription('ru')}) и улучшению конверсии корма FCR (${spec.targetFcr}).",
        en: "$trimmed — My flock is on Day ${spec.day} ($birdCount birds, ${spec.phaseTitle('en')}). Provide exact guidance on today's ${req.totalDailyFeedKg.toStringAsFixed(1)} kg feed target (${spec.dailyFeedPerBirdG.toStringAsFixed(0)}g/bird, ${spec.feedFormDescription('en')}) and optimizing FCR (${spec.targetFcr}).",
      );
    }

    if (isWater) {
      return AppStrings.tr(
        lang: lang,
        uz: "$trimmed — ${spec.day}-kundagi $birdCount ta broyler uchun kunlik ${req.totalDailyWaterLiters.toStringAsFixed(1)} litr suv me'yori, suv harorati va ${req.recommendedNipples} ta nippel sug'orgich bosimini qanday sozlash kerak?",
        ru: "$trimmed — Как настроить суточную подачу ${req.totalDailyWaterLiters.toStringAsFixed(1)} л воды, температуру воды и высоту/давление ${req.recommendedNipples} ниппельных поилок для $birdCount бройлеров на ${spec.day}-й день?",
        en: "$trimmed — For $birdCount broilers on Day ${spec.day}, how should I manage today's ${req.totalDailyWaterLiters.toStringAsFixed(1)} L water target, water temperature, and pressure/height across ${req.recommendedNipples} nipple drinkers?",
      );
    }

    if (isLightOrDensity) {
      return AppStrings.tr(
        lang: lang,
        uz: "$trimmed — ${spec.day}-kundagi $birdCount bosh broyler uchun yorug'lik rejimi (${spec.lightHours} soat yorug'lik / ${spec.darkHours} soat qorong'ulik, ${spec.lightIntensityLux} lyuks) va xona zichligi (1 m² ga max ${spec.maxBirdsPerSqMeter} bosh, jami ~${req.requiredBarnAreaCurrentSqM.toStringAsFixed(1)} m²) qanday bo'lishi kerak?",
        ru: "$trimmed — Какой режим освещения (${spec.lightHours} ч света / ${spec.darkHours} ч темноты, ${spec.lightIntensityLux} люкс) и плотность посадки (макс. ${spec.maxBirdsPerSqMeter} гол./м², площадь ~${req.requiredBarnAreaCurrentSqM.toStringAsFixed(1)} м²) нужны для $birdCount бройлеров на ${spec.day}-й день?",
        en: "$trimmed — What lighting schedule (${spec.lightHours}h light / ${spec.darkHours}h dark at ${spec.lightIntensityLux} lux) and stocking density (max ${spec.maxBirdsPerSqMeter} birds/m², ~${req.requiredBarnAreaCurrentSqM.toStringAsFixed(1)} m² area) should I maintain for $birdCount broilers on Day ${spec.day}?",
      );
    }

    if (isTempOrVent) {
      return AppStrings.tr(
        lang: lang,
        uz: "$trimmed — ${spec.day}-kunda ($birdCount bosh) xona harorati ${spec.targetTempC}°C, namlik ${spec.humidityMinPct}–${spec.humidityMaxPct}% va havo almashinuvi (${spec.minAirflowM3PerHrPerKg} m³/soat/kg) me'yorlarini qanday ushlab turaman?",
        ru: "$trimmed — Как удерживать целевую температуру ${spec.targetTempC}°C, влажность ${spec.humidityMinPct}–${spec.humidityMaxPct}% и воздухообмен (${spec.minAirflowM3PerHrPerKg} м³/ч/кг) на ${spec.day}-й день ($birdCount голов)?",
        en: "$trimmed — How do I maintain the ${spec.targetTempC}°C target temperature, ${spec.humidityMinPct}–${spec.humidityMaxPct}% humidity, and ${spec.minAirflowM3PerHrPerKg} m³/h/kg ventilation rate on Day ${spec.day} ($birdCount birds)?",
      );
    }

    if (isWeightOrGrowth) {
      return AppStrings.tr(
        lang: lang,
        uz: "$trimmed — ${spec.day}-kunda Ross-308 jo'jalarim etalon ${spec.targetWeightG.toStringAsFixed(0)} g vaznga (kunlik +${spec.dailyGainG.toStringAsFixed(0)} g o'sish, FCR ${spec.targetFcr}) sog'lom va tez yetishi uchun yemlash, suv va mikroiqlimda nimalarga e'tibor beray?",
        ru: "$trimmed — На что обратить внимание в кормлении, воде и микроклимате на ${spec.day}-й день, чтобы мои бройлеры Ross-308 вышли на эталонный вес ${spec.targetWeightG.toStringAsFixed(0)} г (суточный привес +${spec.dailyGainG.toStringAsFixed(0)} г, FCR ${spec.targetFcr})?",
        en: "$trimmed — What feeding, water, and microclimate steps on Day ${spec.day} will help my Ross-308 broilers reach the ${spec.targetWeightG.toStringAsFixed(0)}g benchmark weight (+${spec.dailyGainG.toStringAsFixed(0)}g/day gain, FCR ${spec.targetFcr})?",
      );
    }

    // General enhancement wrapper if input is short (< 60 chars)
    if (trimmed.length < 65) {
      return AppStrings.tr(
        lang: lang,
        uz: "$trimmed (${spec.day}-kun, $birdCount bosh Ross-308, me'yoriy harorat ${spec.targetTempC}°C, etalon vazn ${spec.targetWeightG.toStringAsFixed(0)} g bo'yicha amaliy tavsiya bering).",
        ru: "$trimmed (Дайте практические рекомендации для партии Ross-308: ${spec.day}-й день, $birdCount голов, норма тепла ${spec.targetTempC}°C, эталонный вес ${spec.targetWeightG.toStringAsFixed(0)} г).",
        en: "$trimmed (Provide practical Ross-308 guidance for Day ${spec.day}, $birdCount birds, target temp ${spec.targetTempC}°C, benchmark weight ${spec.targetWeightG.toStringAsFixed(0)}g).",
      );
    }

    return trimmed;
  }

  static bool _matchesAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }
}
