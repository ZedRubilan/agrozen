import 'package:agrozen/domain/broiler/broiler_grower_library.dart';
import 'package:agrozen/domain/monitoring/barn_monitor.dart';
import 'package:agrozen/services/monitoring/barn_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const day = 18;
  const birds = 2000;
  final spec = BroilerGrowerLibrary.specForDay(day);

  BarnStatus evaluate(
    Map<BarnSensor, double> values, [
    List<CameraDetection> detections = const [],
  ]) => BarnMonitor.evaluate(
    frame: BarnFrame(
      at: DateTime(2026, 10, 22),
      values: values,
      detections: detections,
    ),
    day: day,
    birdCount: birds,
  );

  Map<BarnSensor, double> onNorm() => {
    BarnSensor.temperature: spec.targetTempC,
    BarnSensor.humidity: (spec.humidityMinPct + spec.humidityMaxPct) / 2,
    BarnSensor.ammonia: 5,
    BarnSensor.co2: 1800,
    BarnSensor.water: BarnMonitor.expectedWaterL(day, birds),
    BarnSensor.weight: spec.targetWeightG,
  };

  group('BarnMonitor', () {
    test('readings on the day\'s norm are all OK and fans stay off', () {
      final status = evaluate(onNorm());
      expect(status.overall, ReadingStatus.ok);
      expect(status.problems, isEmpty);
      expect(status.ventilationOn, isFalse);
      expect(status.needsVet, isFalse);
    });

    test('ammonia above 10 ppm needs attention and starts the fans', () {
      final status = evaluate({...onNorm(), BarnSensor.ammonia: 14});
      expect(status.check(BarnSensor.ammonia)!.status, ReadingStatus.watch);
      expect(status.ventilationReasons, [BarnSensor.ammonia]);
    });

    test('ammonia past the 20 ppm smell line is an alarm', () {
      final status = evaluate({...onNorm(), BarnSensor.ammonia: 23});
      expect(status.overall, ReadingStatus.alarm);
    });

    test('CO2 above 3000 ppm starts the fans', () {
      final status = evaluate({...onNorm(), BarnSensor.co2: 3400});
      expect(status.ventilationReasons, contains(BarnSensor.co2));
    });

    test('a cold house is flagged but does not start the fans', () {
      final status = evaluate({
        ...onNorm(),
        BarnSensor.temperature: spec.targetTempC - 5,
      });
      expect(status.check(BarnSensor.temperature)!.status, ReadingStatus.alarm);
      expect(status.check(BarnSensor.temperature)!.isLow, isTrue);
      expect(status.ventilationOn, isFalse);
    });

    test('a hot house starts the fans', () {
      final status = evaluate({
        ...onNorm(),
        BarnSensor.temperature: spec.targetTempC + 3,
      });
      expect(status.ventilationReasons, [BarnSensor.temperature]);
    });

    test('a 25 % drop in water intake is a warning, 40 % an alarm', () {
      final expected = BarnMonitor.expectedWaterL(day, birds);
      expect(
        evaluate({
          ...onNorm(),
          BarnSensor.water: expected * 0.75,
        }).check(BarnSensor.water)!.status,
        ReadingStatus.watch,
      );
      expect(
        evaluate({
          ...onNorm(),
          BarnSensor.water: expected * 0.6,
        }).check(BarnSensor.water)!.status,
        ReadingStatus.alarm,
      );
    });

    test('weight 15 % or more below target is an alarm', () {
      final status = evaluate({
        ...onNorm(),
        BarnSensor.weight: spec.targetWeightG * 0.84,
      });
      expect(status.check(BarnSensor.weight)!.status, ReadingStatus.alarm);
    });

    test('an inactive bird on camera is an alarm that needs the vet', () {
      final status = evaluate(onNorm(), const [
        CameraDetection(
          finding: CameraFinding.inactiveBird,
          left: 0,
          top: 0,
          width: 0.1,
          height: 0.1,
          confidence: 0.9,
        ),
      ]);
      expect(status.overall, ReadingStatus.alarm);
      expect(status.needsVet, isTrue);
    });

    test('huddling on camera alone needs attention', () {
      final status = evaluate(onNorm(), const [
        CameraDetection(
          finding: CameraFinding.huddling,
          left: 0,
          top: 0,
          width: 0.1,
          height: 0.1,
          confidence: 0.9,
        ),
      ]);
      expect(status.overall, ReadingStatus.watch);
    });
  });

  group('SimulatedBarnSource', () {
    BarnStatus settled(DemoScenario scenario) {
      final source = SimulatedBarnSource(
        scenario: scenario,
        day: day,
        birdCount: birds,
      );
      // Problems ramp up over the first frames; frame 10 is fully developed.
      final frame = source.frameAt(10);
      source.dispose();
      return BarnMonitor.evaluate(frame: frame, day: day, birdCount: birds);
    }

    test('normal scenario stays within every norm', () {
      final status = settled(DemoScenario.normal);
      expect(status.overall, ReadingStatus.ok);
    });

    test('each problem scenario is caught by the rules', () {
      expect(
        settled(DemoScenario.ammonia).check(BarnSensor.ammonia)!.status,
        ReadingStatus.alarm,
      );
      expect(
        settled(DemoScenario.cold).check(BarnSensor.temperature)!.isLow,
        isTrue,
      );
      expect(settled(DemoScenario.heat).ventilationOn, isTrue);
      expect(settled(DemoScenario.mortality).needsVet, isTrue);
    });
  });
}
