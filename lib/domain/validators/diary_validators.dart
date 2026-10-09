/// Input validation for diary entries.
///
/// Ensures mortality count is positive and less than current count,
/// weight is positive, and feed is positive.
class DiaryValidators {
  /// Validates mortality count.
  /// Mortality count must be positive (> 0) and strictly less than current count (< currentCount).
  static String? validateMortality(
    int? deaths,
    int currentCount, {
    String locale = 'ru',
  }) {
    if (deaths == null) {
      return locale == 'uz'
          ? 'Nobod sonini kiriting'
          : 'Введите количество падежа';
    }
    if (currentCount <= 0) {
      return locale == 'uz'
          ? "Joriy bosh soni noldan katta bo'lishi kerak"
          : 'Текущее поголовье должно быть больше нуля';
    }
    if (deaths <= 0) {
      return locale == 'uz'
          ? "Nobod soni noldan katta bo'lishi kerak"
          : 'Количество падежа должно быть больше нуля';
    }
    if (deaths >= currentCount) {
      return locale == 'uz'
          ? "Nobod soni joriy bosh sonidan kam bo'lishi kerak"
          : 'Падёж должен быть меньше текущего поголовья';
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
  /// Weight must be positive (> 0).
  static String? validateWeight(
    double? weightGrams, {
    String locale = 'ru',
  }) {
    if (weightGrams == null) {
      return locale == 'uz'
          ? 'Parranda vaznini kiriting'
          : 'Введите вес птицы';
    }
    if (weightGrams <= 0) {
      return locale == 'uz'
          ? "Vazn noldan katta bo'lishi kerak"
          : 'Вес должен быть больше нуля';
    }
    return null;
  }

  /// Returns true if bird weight is positive.
  static bool isValidWeight(double? weightGrams) {
    if (weightGrams == null) return false;
    return weightGrams > 0;
  }

  /// Validates feed amount in grams / kilograms.
  /// Feed amount must be positive (> 0).
  static String? validateFeed(
    double? feedAmount, {
    String locale = 'ru',
  }) {
    if (feedAmount == null) {
      return locale == 'uz'
          ? 'Yem miqdorini kiriting'
          : 'Введите количество корма';
    }
    if (feedAmount <= 0) {
      return locale == 'uz'
          ? "Yem miqdori noldan katta bo'lishi kerak"
          : 'Количество корма должно быть больше нуля';
    }
    return null;
  }

  /// Returns true if feed amount is positive.
  static bool isValidFeed(double? feedAmount) {
    if (feedAmount == null) return false;
    return feedAmount > 0;
  }

  /// Validates mortality string input from UI form fields.
  static String? validateMortalityString(
    String? value,
    int currentCount, {
    String locale = 'ru',
  }) {
    if (value == null || value.trim().isEmpty) {
      return locale == 'uz'
          ? 'Nobod sonini kiriting'
          : 'Введите количество падежа';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return locale == 'uz'
          ? "Faqat butun son kiriting"
          : 'Введите целое число';
    }
    return validateMortality(parsed, currentCount, locale: locale);
  }

  /// Validates weight string input from UI form fields.
  static String? validateWeightString(
    String? value, {
    String locale = 'ru',
  }) {
    if (value == null || value.trim().isEmpty) {
      return locale == 'uz'
          ? 'Parranda vaznini kiriting'
          : 'Введите вес птицы';
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return locale == 'uz'
          ? "Raqam kiriting"
          : 'Введите число';
    }
    return validateWeight(parsed, locale: locale);
  }

  /// Validates feed string input from UI form fields.
  static String? validateFeedString(
    String? value, {
    String locale = 'ru',
  }) {
    if (value == null || value.trim().isEmpty) {
      return locale == 'uz'
          ? 'Yem miqdorini kiriting'
          : 'Введите количество корма';
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return locale == 'uz'
          ? "Raqam kiriting"
          : 'Введите число';
    }
    return validateFeed(parsed, locale: locale);
  }
}
