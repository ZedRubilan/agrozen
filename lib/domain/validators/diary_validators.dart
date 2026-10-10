/// Input validation for diary entries.
///
/// Ensures mortality count is positive and less than current count,
/// weight is positive, and feed is positive.
class DiaryValidators {
  static String _pick(
    String locale, {
    required String uz,
    required String ru,
    required String en,
  }) {
    final code = locale.trim().toLowerCase();
    if (code.startsWith('en')) return en;
    if (code.startsWith('uz')) return uz;
    return ru;
  }

  /// Validates mortality count.
  /// Mortality count must be positive (> 0) and strictly less than current count (< currentCount).
  static String? validateMortality(
    int? deaths,
    int currentCount, {
    String locale = 'ru',
  }) {
    if (deaths == null) {
      return _pick(
        locale,
        uz: 'Nobod sonini kiriting',
        ru: 'Введите количество падежа',
        en: 'Enter mortality count',
      );
    }
    if (currentCount <= 0) {
      return _pick(
        locale,
        uz: "Joriy bosh soni noldan katta bo'lishi kerak",
        ru: 'Текущее поголовье должно быть больше нуля',
        en: 'Current flock count must be greater than zero',
      );
    }
    if (deaths <= 0) {
      return _pick(
        locale,
        uz: "Nobod soni noldan katta bo'lishi kerak",
        ru: 'Количество падежа должно быть больше нуля',
        en: 'Mortality count must be greater than zero',
      );
    }
    if (deaths >= currentCount) {
      return _pick(
        locale,
        uz: "Nobod soni joriy bosh sonidan kam bo'lishi kerak",
        ru: 'Падёж должен быть меньше текущего поголовья',
        en: 'Mortality count must be less than current flock count',
      );
    }
    return null;
  }

  /// Validates mortality count using named parameters.
  static String? validateMortalityNamed({
    required int? deaths,
    required int currentCount,
    String locale = 'ru',
  }) {
    return validateMortality(deaths, currentCount, locale: locale);
  }

  /// Returns true if mortality count is positive and less than current count.
  static bool isValidMortality(int? deaths, int currentCount) {
    if (deaths == null || currentCount <= 0) return false;
    return deaths > 0 && deaths < currentCount;
  }

  /// Validates bird weight in grams.
  /// Weight must be finite and positive (> 0).
  static String? validateWeight(
    double? weightGrams, {
    String locale = 'ru',
  }) {
    if (weightGrams == null) {
      return _pick(
        locale,
        uz: 'Parranda vaznini kiriting',
        ru: 'Введите вес птицы',
        en: 'Enter bird weight',
      );
    }
    if (!weightGrams.isFinite || weightGrams <= 0) {
      return _pick(
        locale,
        uz: "Vazn noldan katta bo'lishi kerak",
        ru: 'Вес должен быть больше нуля',
        en: 'Weight must be greater than zero',
      );
    }
    return null;
  }

  /// Returns true if bird weight is finite and positive.
  static bool isValidWeight(double? weightGrams) {
    if (weightGrams == null) return false;
    return weightGrams.isFinite && weightGrams > 0;
  }

  /// Validates feed amount in grams / kilograms.
  /// Feed amount must be finite and positive (> 0).
  static String? validateFeed(
    double? feedAmount, {
    String locale = 'ru',
  }) {
    if (feedAmount == null) {
      return _pick(
        locale,
        uz: 'Yem miqdorini kiriting',
        ru: 'Введите количество корма',
        en: 'Enter feed amount',
      );
    }
    if (!feedAmount.isFinite || feedAmount <= 0) {
      return _pick(
        locale,
        uz: "Yem miqdori noldan katta bo'lishi kerak",
        ru: 'Количество корма должно быть больше нуля',
        en: 'Feed amount must be greater than zero',
      );
    }
    return null;
  }

  /// Returns true if feed amount is finite and positive.
  static bool isValidFeed(double? feedAmount) {
    if (feedAmount == null) return false;
    return feedAmount.isFinite && feedAmount > 0;
  }

  /// Validates mortality string input from UI form fields.
  static String? validateMortalityString(
    String? value,
    int currentCount, {
    String locale = 'ru',
  }) {
    if (value == null || value.trim().isEmpty) {
      return _pick(
        locale,
        uz: 'Nobod sonini kiriting',
        ru: 'Введите количество падежа',
        en: 'Enter mortality count',
      );
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return _pick(
        locale,
        uz: "Faqat butun son kiriting",
        ru: 'Введите целое число',
        en: 'Enter a whole number',
      );
    }
    return validateMortality(parsed, currentCount, locale: locale);
  }

  /// Validates weight string input from UI form fields.
  static String? validateWeightString(
    String? value, {
    String locale = 'ru',
  }) {
    if (value == null || value.trim().isEmpty) {
      return _pick(
        locale,
        uz: 'Parranda vaznini kiriting',
        ru: 'Введите вес птицы',
        en: 'Enter bird weight',
      );
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return _pick(
        locale,
        uz: "Raqam kiriting",
        ru: 'Введите число',
        en: 'Enter a valid number',
      );
    }
    return validateWeight(parsed, locale: locale);
  }

  /// Validates feed string input from UI form fields.
  static String? validateFeedString(
    String? value, {
    String locale = 'ru',
  }) {
    if (value == null || value.trim().isEmpty) {
      return _pick(
        locale,
        uz: 'Yem miqdorini kiriting',
        ru: 'Введите количество корма',
        en: 'Enter feed amount',
      );
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return _pick(
        locale,
        uz: "Raqam kiriting",
        ru: 'Введите число',
        en: 'Enter a valid number',
      );
    }
    return validateFeed(parsed, locale: locale);
  }
}
