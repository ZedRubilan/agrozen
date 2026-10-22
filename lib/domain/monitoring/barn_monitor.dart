import 'dart:math' as math;
import '../broiler/broiler_grower_library.dart';

/// What the barn sensor kit measures (ESP32 node + SHT31, ZE03-NH3,
/// MH-Z19C, pulse water meter, HX711 weighing platform).
enum BarnSensor { temperature, humidity, ammonia, co2, water, weight }

enum ReadingStatus { ok, watch, alarm }

/// Air-quality limits from the Ross-308 broiler management handbook. They do
/// not change with the flock's age, unlike temperature or humidity.
abstract final class BarnAirLimits {
  /// Ammonia must stay at or below 10 ppm.
  static const double ammoniaMaxPpm = 10;

  /// People only start to smell ammonia at about 20 ppm, so by the time the
  /// farmer notices it the birds have been breathing it for a while.
  static const double ammoniaAlarmPpm = 20;

  /// CO₂ above 3000 ppm means minimum ventilation is too low.
  static const double co2MaxPpm = 3000;
  static const double co2AlarmPpm = 5000;

  /// House temperature may drift this far from the day's target (same as
  /// `critical_thresholds.temp_deviation_celsius` in norms.json).
  static const double tempDeviationC = 2;

  /// A drop in water intake is often the first sign of illness.
  static const double waterWatchBelow = 0.80;
  static const double waterAlarmBelow = 0.65;
  static const double waterWatchAbove = 1.30;

  /// Average sample weight below target (alarm matches the diary's −15 %).
  static const double weightWatchBelow = 0.10;
  static const double weightAlarmBelow = 0.15;
}

/// One sensor value checked against the day's norm.
class SensorCheck {
  final BarnSensor sensor;
  final double value;
  final ReadingStatus status;

  /// Lower and upper edge of the normal range (null = no edge).
  final double? normMin;
  final double? normMax;

  /// The single target the norm is built around, when there is one.
  final double? target;

  const SensorCheck({
    required this.sensor,
    required this.value,
    required this.status,
    this.normMin,
    this.normMax,
    this.target,
  });

  bool get isHigh => normMax != null && value > normMax!;
  bool get isLow => normMin != null && value < normMin!;
}

/// What the edge-AI camera model reports about one frame.
enum CameraFinding {
  /// A bird that has not moved for a long time (possibly dead).
  inactiveBird,

  /// Birds packed together — the house is too cold.
  huddling,

  /// Birds spread to the walls with wings held out — the house is too hot.
  heatStress,
}

/// A finding with its box on the frame, in 0..1 image coordinates.
class CameraDetection {
  final CameraFinding finding;
  final double left;
  final double top;
  final double width;
  final double height;
  final double confidence;

  const CameraDetection({
    required this.finding,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
  });
}

/// One set of readings from the barn, as the edge device sends it.
class BarnFrame {
  final DateTime at;
  final Map<BarnSensor, double> values;
  final List<CameraDetection> detections;

  const BarnFrame({
    required this.at,
    required this.values,
    this.detections = const [],
  });

  int get inactiveBirds =>
      detections.where((d) => d.finding == CameraFinding.inactiveBird).length;

  bool has(CameraFinding finding) =>
      detections.any((d) => d.finding == finding);
}

/// The verdict for one frame: every sensor checked, the camera findings and
/// whether the fans should run.
class BarnStatus {
  final int day;
  final List<SensorCheck> checks;
  final BarnFrame frame;

  const BarnStatus({
    required this.day,
    required this.checks,
    required this.frame,
  });

  SensorCheck? check(BarnSensor sensor) {
    for (final c in checks) {
      if (c.sensor == sensor) return c;
    }
    return null;
  }

  ReadingStatus get overall {
    var worst = ReadingStatus.ok;
    for (final c in checks) {
      if (c.status.index > worst.index) worst = c.status;
    }
    if (frame.inactiveBirds > 0) return ReadingStatus.alarm;
    if ((frame.has(CameraFinding.huddling) ||
            frame.has(CameraFinding.heatStress)) &&
        worst == ReadingStatus.ok) {
      return ReadingStatus.watch;
    }
    return worst;
  }

  /// Checks that are off-norm, worst first.
  List<SensorCheck> get problems {
    final list = checks.where((c) => c.status != ReadingStatus.ok).toList()
      ..sort((a, b) => b.status.index.compareTo(a.status.index));
    return list;
  }

  /// Why the fans are running, or an empty list when they should be off.
  /// Only the air is used: ammonia, CO₂ or an overheated house.
  List<BarnSensor> get ventilationReasons {
    final reasons = <BarnSensor>[];
    final nh3 = check(BarnSensor.ammonia);
    if (nh3 != null && nh3.isHigh) reasons.add(BarnSensor.ammonia);
    final co2 = check(BarnSensor.co2);
    if (co2 != null && co2.isHigh) reasons.add(BarnSensor.co2);
    final temp = check(BarnSensor.temperature);
    if (temp != null && temp.isHigh) reasons.add(BarnSensor.temperature);
    return reasons;
  }

  bool get ventilationOn => ventilationReasons.isNotEmpty;

  /// A dead or long-still bird needs the vet, not an app.
  bool get needsVet => frame.inactiveBirds > 0;
}

/// Compares barn readings with the Ross-308 / Cobb-500 norms for the day.
/// Plain rules, no AI: the same readings always give the same verdict.
class BarnMonitor {
  const BarnMonitor._();

  static BarnStatus evaluate({
    required BarnFrame frame,
    required int day,
    required int birdCount,
  }) {
    final spec = BroilerGrowerLibrary.specForDay(day);
    final checks = <SensorCheck>[];
    frame.values.forEach((sensor, value) {
      checks.add(_check(sensor, value, spec, math.max(1, birdCount)));
    });
    checks.sort((a, b) => a.sensor.index.compareTo(b.sensor.index));
    return BarnStatus(day: spec.day, checks: checks, frame: frame);
  }

  /// Expected water for the whole flock today, in litres.
  static double expectedWaterL(int day, int birdCount) =>
      BroilerGrowerLibrary.specForDay(day).dailyWaterPerBirdMl *
      math.max(1, birdCount) /
      1000.0;

  static SensorCheck _check(
    BarnSensor sensor,
    double value,
    BroilerDaySpec spec,
    int birds,
  ) {
    switch (sensor) {
      case BarnSensor.temperature:
        const dev = BarnAirLimits.tempDeviationC;
        final diff = (value - spec.targetTempC).abs();
        return SensorCheck(
          sensor: sensor,
          value: value,
          target: spec.targetTempC,
          normMin: spec.targetTempC - dev,
          normMax: spec.targetTempC + dev,
          status: diff > dev * 2
              ? ReadingStatus.alarm
              : (diff > dev ? ReadingStatus.watch : ReadingStatus.ok),
        );
      case BarnSensor.humidity:
        final min = spec.humidityMinPct.toDouble();
        final max = spec.humidityMaxPct.toDouble();
        final off = value < min ? min - value : (value > max ? value - max : 0);
        return SensorCheck(
          sensor: sensor,
          value: value,
          normMin: min,
          normMax: max,
          status: off > 10
              ? ReadingStatus.alarm
              : (off > 0 ? ReadingStatus.watch : ReadingStatus.ok),
        );
      case BarnSensor.ammonia:
        return SensorCheck(
          sensor: sensor,
          value: value,
          normMax: BarnAirLimits.ammoniaMaxPpm,
          status: value > BarnAirLimits.ammoniaAlarmPpm
              ? ReadingStatus.alarm
              : (value > BarnAirLimits.ammoniaMaxPpm
                    ? ReadingStatus.watch
                    : ReadingStatus.ok),
        );
      case BarnSensor.co2:
        return SensorCheck(
          sensor: sensor,
          value: value,
          normMax: BarnAirLimits.co2MaxPpm,
          status: value > BarnAirLimits.co2AlarmPpm
              ? ReadingStatus.alarm
              : (value > BarnAirLimits.co2MaxPpm
                    ? ReadingStatus.watch
                    : ReadingStatus.ok),
        );
      case BarnSensor.water:
        final expected = spec.dailyWaterPerBirdMl * birds / 1000.0;
        final ratio = expected > 0 ? value / expected : 1.0;
        return SensorCheck(
          sensor: sensor,
          value: value,
          target: expected,
          normMin: expected * BarnAirLimits.waterWatchBelow,
          normMax: expected * BarnAirLimits.waterWatchAbove,
          status: ratio < BarnAirLimits.waterAlarmBelow
              ? ReadingStatus.alarm
              : (ratio < BarnAirLimits.waterWatchBelow ||
                        ratio > BarnAirLimits.waterWatchAbove
                    ? ReadingStatus.watch
                    : ReadingStatus.ok),
        );
      case BarnSensor.weight:
        final target = spec.targetWeightG;
        final deficit = target > 0 ? (target - value) / target : 0.0;
        return SensorCheck(
          sensor: sensor,
          value: value,
          target: target,
          normMin: target * (1 - BarnAirLimits.weightWatchBelow),
          status: deficit > BarnAirLimits.weightAlarmBelow
              ? ReadingStatus.alarm
              : (deficit > BarnAirLimits.weightWatchBelow
                    ? ReadingStatus.watch
                    : ReadingStatus.ok),
        );
    }
  }
}
