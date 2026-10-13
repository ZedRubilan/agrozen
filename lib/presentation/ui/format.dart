import '../../core/localization/app_strings.dart';

/// Number and unit formatting shared by every screen, so "27 kg", "Day 14"
/// and "498 birds" read the same everywhere.
class Fmt {
  final String lang;

  const Fmt(this.lang);

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: lang, uz: uz, ru: ru, en: en);

  /// 27 → "27", 27.25 → "27.3".
  static String num(double value, {int decimals = 1}) {
    final rounded = double.parse(value.toStringAsFixed(decimals));
    if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
    return rounded.toStringAsFixed(decimals);
  }

  /// 12500 → "12 500".
  static String grouped(double value) {
    final digits = value.round().abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }

  String kg(double v) => '${num(v)} ${_t('kg', 'кг', 'kg')}';
  String grams(double v) => '${num(v, decimals: 0)} ${_t('g', 'г', 'g')}';
  String liters(double v) => '${num(v)} ${_t('L', 'л', 'L')}';
  String ml(double v) => '${num(v, decimals: 0)} ${_t('ml', 'мл', 'ml')}';
  String celsius(double v) => '${num(v)}°C';
  String birds(int n) => '${grouped(n.toDouble())} ${_t('bosh', 'гол.', 'birds')}';
  String days(int n) => '$n ${_t('kun', _ruDays(n), n == 1 ? 'day' : 'days')}';

  static String _ruDays(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'дня';
    return 'дней';
  }
  String day(int n) => _t('$n-kun', 'День $n', 'Day $n');
  String dayOf(int n, int total) =>
      _t('$n-kun ($total kundan)', 'День $n из $total', 'Day $n of $total');
  String money(double sum) => '${grouped(sum)} ${_t("so'm", 'сум', 'UZS')}';
  String perBird(String value) => '$value ${_t('/ bosh', '/ гол.', '/ bird')}';
}
