import '../../core/localization/app_strings.dart';

enum ClimateRiskLevel {
  optimal,
  heatWarning,
  coldWarning,
  highHumidityRisk,
  dryAirRisk,
}

/// Farmer-friendly, scientifically validated microclimate guidance
/// according to Ross-308 & Cobb-500 broiler management standards.
class ClimateAdvice {
  final ClimateRiskLevel riskLevel;
  final double targetHouseTemp;
  final double outsideTemp;
  final double outsideHumidity;
  final double tempDifference;
  final String statusBadge;
  final String title;
  final String summary;
  final String directive;
  final String ventilationAdvice;
  final String waterFeedAdvice;

  const ClimateAdvice({
    required this.riskLevel,
    required this.targetHouseTemp,
    required this.outsideTemp,
    required this.outsideHumidity,
    required this.tempDifference,
    required this.statusBadge,
    required this.title,
    required this.summary,
    required this.directive,
    required this.ventilationAdvice,
    required this.waterFeedAdvice,
  });
}

class ClimateAdvisor {
  ClimateAdvisor._();

  /// Evaluates outside weather in conjunction with the flock's target age and house temperature.
  /// Generates real-time, actionable poultry microclimate directives in Uzbek, Russian, and English.
  static ClimateAdvice evaluate({
    required int flockAgeDays,
    required double outsideTemp,
    required double outsideHumidity,
    required double targetHouseTemp,
    required String lang,
  }) {
    final diff = outsideTemp - targetHouseTemp;
    ClimateRiskLevel riskLevel = ClimateRiskLevel.optimal;

    // Heat stress evaluation (broilers cannot sweat, depend on panting)
    if (outsideTemp >= 32.0 || diff >= 5.0) {
      riskLevel = ClimateRiskLevel.heatWarning;
    }
    // Cold stress evaluation (chicks under-cool, ascites & huddling risks)
    else if (outsideTemp <= 12.0 || diff <= -8.0) {
      riskLevel = ClimateRiskLevel.coldWarning;
    }
    // High humidity: litter dampness & ammonia risk
    else if (outsideHumidity >= 75.0) {
      riskLevel = ClimateRiskLevel.highHumidityRisk;
    }
    // Very dry air: respiratory dust & dehydration
    else if (outsideHumidity <= 30.0) {
      riskLevel = ClimateRiskLevel.dryAirRisk;
    } else {
      riskLevel = ClimateRiskLevel.optimal;
    }

    return ClimateAdvice(
      riskLevel: riskLevel,
      targetHouseTemp: targetHouseTemp,
      outsideTemp: outsideTemp,
      outsideHumidity: outsideHumidity,
      tempDifference: diff,
      statusBadge: _getStatusBadge(riskLevel, lang),
      title: _getTitle(riskLevel, lang),
      summary: _getSummary(riskLevel, diff, outsideHumidity, lang),
      directive: _getDirective(riskLevel, flockAgeDays, lang),
      ventilationAdvice: _getVentilationAdvice(riskLevel, flockAgeDays, lang),
      waterFeedAdvice: _getWaterFeedAdvice(riskLevel, flockAgeDays, lang),
    );
  }

  static String _getStatusBadge(ClimateRiskLevel risk, String lang) {
    switch (risk) {
      case ClimateRiskLevel.heatWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Issiq urish xavfi',
          ru: 'Риск теплового стресса',
          en: 'Heat Stress Warning',
        );
      case ClimateRiskLevel.coldWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Sovuq havo xavfi',
          ru: 'Риск переохлаждения',
          en: 'Cold Stress Risk',
        );
      case ClimateRiskLevel.highHumidityRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Yuqori namlik (Ammiak xavfi)',
          ru: 'Высокая влажность (Риск аммиака)',
          en: 'High Humidity (Ammonia Risk)',
        );
      case ClimateRiskLevel.dryAirRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Quruq havo (Chang xavfi)',
          ru: 'Сухой воздух (Пыль в птичнике)',
          en: 'Dry Air (Dust Risk)',
        );
      case ClimateRiskLevel.optimal:
        return AppStrings.tr(
          lang: lang,
          uz: 'Qulay mikroklimat',
          ru: 'Оптимальный микроклимат',
          en: 'Optimal Microclimate',
        );
    }
  }

  static String _getTitle(ClimateRiskLevel risk, String lang) {
    switch (risk) {
      case ClimateRiskLevel.heatWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Tashqarida yuqori harorat!',
          ru: 'Снаружи высокая температура!',
          en: 'High Ambient Temperature!',
        );
      case ClimateRiskLevel.coldWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Tashqarida sovuq havo!',
          ru: 'Снаружи холодная погода!',
          en: 'Cold Ambient Temperature!',
        );
      case ClimateRiskLevel.highHumidityRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Tashqi havoda yuqori namlik',
          ru: 'Высокая влажность воздуха снаружи',
          en: 'High External Humidity',
        );
      case ClimateRiskLevel.dryAirRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Juda past namlik',
          ru: 'Слишком низкая влажность',
          en: 'Very Low Humidity',
        );
      case ClimateRiskLevel.optimal:
        return AppStrings.tr(
          lang: lang,
          uz: 'Ob-havo me\'yorida',
          ru: 'Погода в пределах нормы',
          en: 'Weather is Within Normal Range',
        );
    }
  }

  static String _getSummary(
      ClimateRiskLevel risk, double diff, double humidity, String lang) {
    switch (risk) {
      case ClimateRiskLevel.heatWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Tashqi harorat me\'yordan ${diff.toStringAsFixed(1)}°C yuqori. Broylerlar terlamaydi, og\'iz orqali nafas olib soviydi.',
          ru: 'Внешняя температура выше нормы на ${diff.toStringAsFixed(1)}°C. Бройлеры не потеют и охлаждаются только одышкой.',
          en: 'Outside temp is ${diff.toStringAsFixed(1)}°C above target. Broilers cannot sweat and rely solely on panting.',
        );
      case ClimateRiskLevel.coldWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Tashqi harorat xonadagidan ancha sovuq. Sovuq shamol kirmasligini va isitgichlar yetarli quvvatda ishlashini ta\'minlang.',
          ru: 'На улице существенно холоднее нормы. Защитите птичник от сквозняков и проверьте мощность обогревателей.',
          en: 'Outside temp is significantly below house target. Guard against floor drafts and verify heating capacity.',
        );
      case ClimateRiskLevel.highHumidityRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Namlik ${humidity.toStringAsFixed(0)}%. To\'shama namlanishi ammiak gazi ko\'payishiga va panjalar jarohatiga olib kelishi mumkin.',
          ru: 'Влажность ${humidity.toStringAsFixed(0)}%. Сырая подстилка увеличивает выделение аммиака и риск пододерматита.',
          en: 'Humidity is ${humidity.toStringAsFixed(0)}%. Damp bedding accelerates ammonia emissions and footpad dermatitis.',
        );
      case ClimateRiskLevel.dryAirRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Namlik atigi ${humidity.toStringAsFixed(0)}%. Quruq havo chang ko\'payishi va nafas yo\'llari qurishiga olib keladi.',
          ru: 'Влажность всего ${humidity.toStringAsFixed(0)}%. Сухой воздух провоцирует пыль и пересыхание слизистых дыхательных путей.',
          en: 'Humidity is only ${humidity.toStringAsFixed(0)}%. Dry air increases dust and irritates the flock\'s respiratory tract.',
        );
      case ClimateRiskLevel.optimal:
        return AppStrings.tr(
          lang: lang,
          uz: 'Tashqi ob-havo qulay. Standart shamollatish rejimini va toza suv ta\'minotini saqlab turing.',
          ru: 'Внешняя среда комфортная. Поддерживайте стандартный график вентиляции и чистую питьевую воду.',
          en: 'External conditions are mild. Maintain standard ventilation schedules and clean drinking water.',
        );
    }
  }

  static String _getDirective(
      ClimateRiskLevel risk, int flockAgeDays, String lang) {
    switch (risk) {
      case ClimateRiskLevel.heatWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Kunning eng issiq vaqtida (12:00-16:00) ozuqa berishni kamaytiring (hazm qilish tana haroratini ko\'taradi). Ventilyatorlarni maksimal rejimga qo\'ying.',
          ru: 'В пик жары (12:00-16:00) ограничьте подачу корма (переваривание повышает температуру тела). Включите максимальный обдув.',
          en: 'Reduce feed during peak heat hours (12:00-16:00) as digestion increases internal heat. Set fans to maximum air velocity.',
        );
      case ClimateRiskLevel.coldWarning:
        return flockAgeDays <= 7
            ? AppStrings.tr(
                lang: lang,
                uz: 'Kichik jo\'jalar sovuqqa juda ta\'sirchan! Isitgichlarni tekshiring, pol harorati kamida 30-32°C bo\'lishi shart. Jo\'jalar to\'planib qolmasligini kuzating.',
                ru: 'Маленькие цыплята очень чувствительны к холоду! Температура пола должна быть 30-32°C. Следите, чтобы они не сбивались в кучи.',
                en: 'Young chicks are extremely vulnerable! Floor temp must be at least 30-32°C. Prevent chicks from huddling tightly.',
              )
            : AppStrings.tr(
                lang: lang,
                uz: 'Bino devorlari va eshik ostidagi tirqishlarni yoping. Isitish tizimini yoqing, lekin minimal kislorod oqimini to\'xtatmang.',
                ru: 'Устраните щели в дверях и стенах. Включите отопление, сохраняя минимальный приток свежего кислорода.',
                en: 'Seal bottom and wall air leaks. Engage heating while maintaining minimum fresh air exchange.',
              );
      case ClimateRiskLevel.highHumidityRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Shamollatish tezligini oshirib, namlikni tashqariga chiqaring. Ichimlik suvi idishlari atrofidagi nam to\'shamani darhol yangilang.',
          ru: 'Увеличьте скорость вентиляции для удаления влаги. Немедленно замените мокрую подстилку возле поилок.',
          en: 'Increase ventilation rate to exhaust moisture. Promptly remove wet bedding around drinkers and add dry shavings.',
        );
      case ClimateRiskLevel.dryAirRisk:
        return AppStrings.tr(
          lang: lang,
          uz: 'Bino yo\'laklariga suv purkash yoki namlagichlar orqali namlikni 55-65% ga yetkazing.',
          ru: 'Увлажните проходы мелким распылением воды или увлажнителями до уровня 55-65%.',
          en: 'Mist farm walkways or engage foggers to raise ambient relative humidity to 55-65%.',
        );
      case ClimateRiskLevel.optimal:
        return AppStrings.tr(
          lang: lang,
          uz: 'Kunlik reja bo\'yicha parvarishni davom eting. Harorat datchiklarini muntazam tekshiring.',
          ru: 'Продолжайте плановый уход по дневному графику. Регулярно калибруйте датчики температуры.',
          en: 'Continue routine daily flock management. Periodically check temperature and humidity sensors.',
        );
    }
  }

  static String _getVentilationAdvice(
      ClimateRiskLevel risk, int flockAgeDays, String lang) {
    switch (risk) {
      case ClimateRiskLevel.heatWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Tunnel ventilyatsiya: qushlar ustida 1.5-2.5 m/s shamol tezligini yarating (shamol sovutish effekti).',
          ru: 'Туннельная вентиляция: скорость движения воздуха над птицей 1.5-2.5 м/с (эффект ветрового охлаждения).',
          en: 'Tunnel ventilation: create 1.5-2.5 m/s air velocity over birds (wind chill cooling effect).',
        );
      case ClimateRiskLevel.coldWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Minimal ventilyatsiya: havo oqimi to\'g\'ridan-to\'g\'ri jo\'jalar ustiga emas, balki shift orqali kelsin.',
          ru: 'Минимальная вентиляция: холодный воздух должен направляться под потолок, а не прямо на цыплят.',
          en: 'Minimum ventilation: direct intake air along the ceiling to mix before reaching chick level.',
        );
      default:
        return AppStrings.tr(
          lang: lang,
          uz: 'Standart oraliqli ventilyatsiya: kislorodni doimiy toza saqlash uchun taymer bo\'yicha ishlatilsin.',
          ru: 'Стандартная циклическая вентиляция: регулярный обмен воздуха по таймеру для свежего кислорода.',
          en: 'Standard cycle ventilation: timer-controlled airflow to maintain oxygen levels and remove CO2.',
        );
    }
  }

  static String _getWaterFeedAdvice(
      ClimateRiskLevel risk, int flockAgeDays, String lang) {
    switch (risk) {
      case ClimateRiskLevel.heatWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Ichimlik suvi harorati 15-18°C bo\'lsin. Suvga elektrolit (C vitamini) qo\'shing. Suv bosimini oshiring.',
          ru: 'Температура воды 15-18°C. Добавьте в воду электролиты и витамин С. Увеличьте напор в поилках.',
          en: 'Keep drinking water cool (15-18°C). Add electrolytes/vitamin C to water lines. Flush lines regularly.',
        );
      case ClimateRiskLevel.coldWarning:
        return AppStrings.tr(
          lang: lang,
          uz: 'Ichimlik suvi juda sovuq bo\'lmasin (kamida 18-20°C). Sovuq suv ichish jo\'jalarni ichki tomondan sovutadi.',
          ru: 'Вода не должна быть ледяной (не ниже 18-20°C). Ледяная вода вызывает внутреннее переохлаждение.',
          en: 'Ensure drinking water is not freezing (maintain at least 18-20°C) to prevent core hypothermia.',
        );
      default:
        return AppStrings.tr(
          lang: lang,
          uz: 'Toza ichimlik suvi va ratsion bo\'yicha to\'laqonli ozuqa mavjudligini tekshiring.',
          ru: 'Обеспечьте постоянный доступ к чистой воде и сбалансированному рациону корма.',
          en: 'Ensure ad libitum access to clean potable water and age-appropriate feed formula.',
        );
    }
  }
}
