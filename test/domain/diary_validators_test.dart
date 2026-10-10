import 'package:agrozen/domain/validators/diary_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiaryValidators', () {
    group('validateMortality / isValidMortality', () {
      test('valid when mortality is positive and less than current count', () {
        expect(DiaryValidators.validateMortality(5, 100), isNull);
        expect(DiaryValidators.validateMortalityNamed(deaths: 5, currentCount: 100), isNull);
        expect(DiaryValidators.isValidMortality(5, 100), isTrue);
      });

      test('invalid when mortality is null', () {
        final errorRu = DiaryValidators.validateMortality(null, 100, locale: 'ru');
        final errorUz = DiaryValidators.validateMortality(null, 100, locale: 'uz');
        final errorEn = DiaryValidators.validateMortality(null, 100, locale: 'en');
        expect(errorRu, contains('Введите количество падежа'));
        expect(errorUz, contains('Nobod sonini kiriting'));
        expect(errorEn, contains('Enter mortality count'));
        expect(DiaryValidators.isValidMortality(null, 100), isFalse);
      });

      test('invalid when mortality is 0', () {
        final errorRu = DiaryValidators.validateMortality(0, 100, locale: 'ru');
        final errorUz = DiaryValidators.validateMortality(0, 100, locale: 'uz');
        final errorEn = DiaryValidators.validateMortality(0, 100, locale: 'en');
        expect(errorRu, contains('больше нуля'));
        expect(errorUz, contains("noldan katta"));
        expect(errorEn, contains('Mortality count must be greater than zero'));
        expect(DiaryValidators.isValidMortality(0, 100), isFalse);
      });

      test('invalid when mortality is negative', () {
        final error = DiaryValidators.validateMortality(-3, 100);
        expect(error, isNotNull);
        expect(DiaryValidators.isValidMortality(-3, 100), isFalse);
      });

      test('invalid when mortality equals current count', () {
        final errorRu = DiaryValidators.validateMortality(100, 100, locale: 'ru');
        final errorUz = DiaryValidators.validateMortality(100, 100, locale: 'uz');
        final errorEn = DiaryValidators.validateMortality(100, 100, locale: 'en');
        expect(errorRu, contains('меньше текущего поголовья'));
        expect(errorUz, contains('kam bo\'lishi kerak'));
        expect(errorEn, contains('Mortality count must be less than current flock count'));
        expect(DiaryValidators.isValidMortality(100, 100), isFalse);
      });

      test('invalid when mortality exceeds current count', () {
        final error = DiaryValidators.validateMortality(105, 100);
        expect(error, isNotNull);
        expect(DiaryValidators.isValidMortality(105, 100), isFalse);
      });

      test('invalid when current count is non-positive', () {
        final errorRu = DiaryValidators.validateMortality(5, 0, locale: 'ru');
        final errorEn = DiaryValidators.validateMortality(5, 0, locale: 'en');
        expect(errorRu, contains('Текущее поголовье должно быть больше нуля'));
        expect(errorEn, contains('Current flock count must be greater than zero'));
        expect(DiaryValidators.isValidMortality(5, 0), isFalse);
        expect(DiaryValidators.isValidMortality(5, -10), isFalse);
      });
    });

    group('validateWeight / isValidWeight', () {
      test('valid when weight is positive', () {
        expect(DiaryValidators.validateWeight(150.0), isNull);
        expect(DiaryValidators.isValidWeight(150.0), isTrue);
      });

      test('invalid when weight is null', () {
        final errorRu = DiaryValidators.validateWeight(null, locale: 'ru');
        final errorUz = DiaryValidators.validateWeight(null, locale: 'uz');
        final errorEn = DiaryValidators.validateWeight(null, locale: 'en');
        expect(errorRu, contains('Введите вес птицы'));
        expect(errorUz, contains('Parranda vaznini kiriting'));
        expect(errorEn, contains('Enter bird weight'));
        expect(DiaryValidators.isValidWeight(null), isFalse);
      });

      test('invalid when weight is 0', () {
        final errorRu = DiaryValidators.validateWeight(0.0, locale: 'ru');
        final errorUz = DiaryValidators.validateWeight(0.0, locale: 'uz');
        final errorEn = DiaryValidators.validateWeight(0.0, locale: 'en');
        expect(errorRu, contains('больше нуля'));
        expect(errorUz, contains('noldan katta'));
        expect(errorEn, contains('Weight must be greater than zero'));
        expect(DiaryValidators.isValidWeight(0.0), isFalse);
      });

      test('invalid when weight is negative', () {
        expect(DiaryValidators.validateWeight(-10.0), isNotNull);
        expect(DiaryValidators.isValidWeight(-10.0), isFalse);
      });

      test('rejects NaN and infinity for weight', () {
        expect(DiaryValidators.validateWeight(double.nan, locale: 'en'), contains('Weight must be greater than zero'));
        expect(DiaryValidators.validateWeight(double.infinity, locale: 'en'), contains('Weight must be greater than zero'));
        expect(DiaryValidators.validateWeight(double.negativeInfinity, locale: 'en'), isNotNull);
        expect(DiaryValidators.isValidWeight(double.nan), isFalse);
        expect(DiaryValidators.isValidWeight(double.infinity), isFalse);
        expect(DiaryValidators.isValidWeight(double.negativeInfinity), isFalse);
      });
    });

    group('validateFeed / isValidFeed', () {
      test('valid when feed is positive', () {
        expect(DiaryValidators.validateFeed(45.5), isNull);
        expect(DiaryValidators.isValidFeed(45.5), isTrue);
      });

      test('invalid when feed is null', () {
        final errorRu = DiaryValidators.validateFeed(null, locale: 'ru');
        final errorUz = DiaryValidators.validateFeed(null, locale: 'uz');
        final errorEn = DiaryValidators.validateFeed(null, locale: 'en');
        expect(errorRu, contains('Введите количество корма'));
        expect(errorUz, contains('Yem miqdorini kiriting'));
        expect(errorEn, contains('Enter feed amount'));
        expect(DiaryValidators.isValidFeed(null), isFalse);
      });

      test('invalid when feed is 0', () {
        final errorRu = DiaryValidators.validateFeed(0.0, locale: 'ru');
        final errorUz = DiaryValidators.validateFeed(0.0, locale: 'uz');
        final errorEn = DiaryValidators.validateFeed(0.0, locale: 'en');
        expect(errorRu, contains('больше нуля'));
        expect(errorUz, contains('noldan katta'));
        expect(errorEn, contains('Feed amount must be greater than zero'));
        expect(DiaryValidators.isValidFeed(0.0), isFalse);
      });

      test('invalid when feed is negative', () {
        expect(DiaryValidators.validateFeed(-5.0), isNotNull);
        expect(DiaryValidators.isValidFeed(-5.0), isFalse);
      });

      test('rejects NaN and infinity for feed', () {
        expect(DiaryValidators.validateFeed(double.nan, locale: 'en'), contains('Feed amount must be greater than zero'));
        expect(DiaryValidators.validateFeed(double.infinity, locale: 'en'), contains('Feed amount must be greater than zero'));
        expect(DiaryValidators.validateFeed(double.negativeInfinity, locale: 'en'), isNotNull);
        expect(DiaryValidators.isValidFeed(double.nan), isFalse);
        expect(DiaryValidators.isValidFeed(double.infinity), isFalse);
        expect(DiaryValidators.isValidFeed(double.negativeInfinity), isFalse);
      });
    });

    group('String input validators for forms', () {
      test('validateMortalityString handles valid, invalid string formats across locales', () {
        expect(DiaryValidators.validateMortalityString('5', 100), isNull);
        expect(DiaryValidators.validateMortalityString('', 100), isNotNull);
        expect(DiaryValidators.validateMortalityString('', 100, locale: 'en'), contains('Enter mortality count'));
        expect(DiaryValidators.validateMortalityString('abc', 100), isNotNull);
        expect(DiaryValidators.validateMortalityString('abc', 100, locale: 'en'), contains('Enter a whole number'));
        expect(DiaryValidators.validateMortalityString('120', 100), isNotNull);
      });

      test('validateWeightString handles valid and invalid strings including comma decimals', () {
        expect(DiaryValidators.validateWeightString('150.5'), isNull);
        expect(DiaryValidators.validateWeightString('150,5'), isNull);
        expect(DiaryValidators.validateWeightString('480,5'), isNull);
        expect(DiaryValidators.validateWeightString(''), isNotNull);
        expect(DiaryValidators.validateWeightString('', locale: 'en'), contains('Enter bird weight'));
        expect(DiaryValidators.validateWeightString('invalid'), isNotNull);
        expect(DiaryValidators.validateWeightString('invalid', locale: 'en'), contains('Enter a valid number'));
        expect(DiaryValidators.validateWeightString('-5'), isNotNull);
      });

      test('validateFeedString handles valid and invalid strings including comma decimals', () {
        expect(DiaryValidators.validateFeedString('35.2'), isNull);
        expect(DiaryValidators.validateFeedString('35,2'), isNull);
        expect(DiaryValidators.validateFeedString('25,5'), isNull);
        expect(DiaryValidators.validateFeedString(''), isNotNull);
        expect(DiaryValidators.validateFeedString('', locale: 'en'), contains('Enter feed amount'));
        expect(DiaryValidators.validateFeedString('foo'), isNotNull);
        expect(DiaryValidators.validateFeedString('foo', locale: 'en'), contains('Enter a valid number'));
        expect(DiaryValidators.validateFeedString('0'), isNotNull);
      });
    });
  });
}
