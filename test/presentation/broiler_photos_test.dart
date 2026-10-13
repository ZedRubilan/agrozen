import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrozen/presentation/ui/broiler_photos.dart';

/// The hero photo must look like the farmer's flock: chicks in the starter
/// phase, growers in the middle, finished birds at the end (Ross-308 phases).
void main() {
  group('Photo follows the flock age', () {
    test('starter days 1–10 show chicks', () {
      for (final day in [1, 4, 5, 10]) {
        expect(
          BroilerPhotos.forDay(day),
          BroilerPhotos.starter,
          reason: '$day',
        );
      }
    });

    test('grower days 11–24 show growing birds', () {
      for (final day in [11, 18, 24]) {
        expect(BroilerPhotos.forDay(day), BroilerPhotos.grower, reason: '$day');
      }
    });

    test('finisher days 25–42 show finished birds', () {
      for (final day in [25, 35, 36, 42]) {
        expect(
          BroilerPhotos.forDay(day),
          BroilerPhotos.finisher,
          reason: '$day',
        );
      }
    });
  });

  group('Bundled photos', () {
    test('every credited photo exists and stays small', () {
      for (final credit in PhotoCredit.all) {
        final file = File(credit.asset);
        expect(file.existsSync(), isTrue, reason: credit.asset);
        expect(file.lengthSync(), lessThan(250 * 1024), reason: credit.asset);
      }
    });

    test('every phase photo has a credit', () {
      final credited = PhotoCredit.all.map((c) => c.asset).toSet();
      expect(
        credited,
        containsAll([
          BroilerPhotos.starter,
          BroilerPhotos.grower,
          BroilerPhotos.finisher,
        ]),
      );
    });

    test('every photo in assets/images has a credit', () {
      final credited = PhotoCredit.all.map((c) => c.asset).toSet();
      final photos = Directory('assets/images')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\\', '/'))
          .where((p) => p.endsWith('.jpg'));
      for (final photo in photos) {
        expect(credited, contains(photo), reason: photo);
      }
    });

        test('CC BY-SA photos link their licence', () {
      for (final credit in PhotoCredit.all) {
        if (credit.licence.startsWith('CC BY')) {
          expect(credit.licenceUrl, isNotNull, reason: credit.asset);
        }
      }
    });
  });
}
