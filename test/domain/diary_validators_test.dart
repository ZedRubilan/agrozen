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
        expect(errorRu, contains('Введите количество падежа'));
        expect(errorUz, contains('Nobod sonini kiriting'));
        expect(DiaryValidators.isValidMortality(null, 100), isFalse);
      });

      test('invalid when mortality is 0', () {
        final errorRu = DiaryValidators.validateMortality(0, 100, locale: 'ru');
        final errorUz = DiaryValidators.validateMortality(0, 100, locale: 'uz');
        expect(errorRu, contains('больше нуля'));
        expect(errorUz, contains("noldan katta"));
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
        expect(errorRu, contains('меньше текущего поголовья'));
        expect(errorUz, contains('kam bo\'lishi kerak'));
        expect(DiaryValidators.isValidMortality(100, 100), isFalse);
      });

      test('invalid when mortality exceeds current count', () {
        final error = DiaryValidators.validateMortality(105, 100);
        expect(error, isNotNull);
        expect(DiaryValidators.isValidMortality(105, 100), isFalse);
      });

      test('invalid when current count is non-positive', () {
        final errorRu = DiaryValidators.validateMortality(5, 0, locale: 'ru');
        expect(errorRu, contains('Текущее поголовье должно быть больше нуля'));
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
        expect(errorRu, contains('Введите вес птицы'));
        expect(errorUz, contains('Parranda vaznini kiriting'));
        expect(DiaryValidators.isValidWeight(null), isFalse);
      });

      test('invalid when weight is 0', () {
        final errorRu = DiaryValidators.validateWeight(0.0, locale: 'ru');
        final errorUz = DiaryValidators.validateWeight(0.0, locale: 'uz');
        expect(errorRu, contains('больше нуля'));
        expect(errorUz, contains('noldan katta'));
        expect(DiaryValidators.isValidWeight(0.0), isFalse);
      });

      test('invalid when weight is negative', () {
        expect(DiaryValidators.validateWeight(-10.0), isNotNull);
        expect(DiaryValidators.isValidWeight(-10.0), isFalse);
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
        expect(errorRu, contains('Введите количество корма'));
        expect(errorUz, contains('Yem miqdorini kiriting'));
        expect(DiaryValidators.isValidFeed(null), isFalse);
      });

      test('invalid when feed is 0', () {
        final errorRu = DiaryValidators.validateFeed(0.0, locale: 'ru');
        final errorUz = DiaryValidators.validateFeed(0.0, locale: 'uz');
        expect(errorRu, contains('больше нуля'));
        expect(errorUz, contains('noldan katta'));
        expect(DiaryValidators.isValidFeed(0.0), isFalse);
      });

      test('invalid when feed is negative', () {
        expect(DiaryValidators.validateFeed(-5.0), isNotNull);
        expect(DiaryValidators.isValidFeed(-5.0), isFalse);
      });
    });

    group('String input validators for forms', () {
      test('validateMortalityString handles valid, invalid string formats', () {
        expect(DiaryValidators.validateMortalityString('5', 100), isNull);
        expect(DiaryValidators.validateMortalityString('', 100), isNotNull);
        expect(DiaryValidators.validateMortalityString('abc', 100), isNotNull);
        expect(DiaryValidators.validateMortalityString('120', 100), isNotNull);
      });

      test('validateWeightString handles valid and invalid strings', () {
        expect(DiaryValidators.validateWeightString('150.5'), isNull);
        expect(DiaryValidators.validateWeightString('150,5'), isNull); // comma as decimal separator
        expect(DiaryValidators.validateWeightString(''), isNotNull);
        expect(DiaryValidators.validateWeightString('invalid'), isNotNull);
        expect(DiaryValidators.validateWeightString('-5'), isNotNull);
      });

      test('validateFeedString handles valid and invalid strings', () {
        expect(DiaryValidators.validateFeedString('35.2'), isNull);
        expect(DiaryValidators.validateFeedString('35,2'), isNull); // comma as decimal separator
        expect(DiaryValidators.validateFeedString(''), isNotNull);
        expect(DiaryValidators.validateFeedString('foo'), isNotNull);
        expect(DiaryValidators.validateFeedString('0'), isNotNull);
      });
    });
  });
}
