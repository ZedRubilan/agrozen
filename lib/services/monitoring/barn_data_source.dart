import 'dart:async';
import 'dart:math' as math;
import '../../domain/broiler/broiler_grower_library.dart';
import '../../domain/monitoring/barn_monitor.dart';

/// Where barn readings come from. Today only [SimulatedBarnSource] exists;
/// the pilot's ESP32 nodes and Jetson camera box will plug in here (MQTT or
/// Supabase Realtime) without changing the screens or [BarnMonitor].
abstract class BarnDataSource {
  Stream<BarnFrame> frames();
  void dispose();
}

/// Situations the demo can play, each one a real problem from the
/// Ross-308 handbook that the sensors or the camera would catch.
enum DemoScenario { normal, ammonia, cold, heat, mortality }

/// Plays plausible readings around the norms for the flock's day, with a
/// little noise, so the monitor can be shown before the hardware exists.
class SimulatedBarnSource implements BarnDataSource {
  final DemoScenario scenario;
  final int day;
  final int birdCount;
  final Duration interval;
  final math.Random _random;

  final _controller = StreamController<BarnFrame>.broadcast();
  Timer? _timer;
  int _tick = 0;

  SimulatedBarnSource({
    required this.scenario,
    required this.day,
    required this.birdCount,
    this.interval = const Duration(seconds: 2),
    int seed = 42,
  }) : _random = math.Random(seed);

  @override
  Stream<BarnFrame> frames() {
    _timer ??= Timer.periodic(interval, (_) => _emit());
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(frameAt(_tick++));
  }

  /// The frame for step [tick]; public so tests can check each scenario.
  BarnFrame frameAt(int tick) {
    final spec = BroilerGrowerLibrary.specForDay(day);
    final water = BarnMonitor.expectedWaterL(day, birdCount);
    final humidityMid = (spec.humidityMinPct + spec.humidityMaxPct) / 2;

    double noise(double amplitude) =>
        (_random.nextDouble() * 2 - 1) * amplitude;

    // Problems build up over the first few frames instead of jumping.
    final ramp = math.min(1.0, (tick + 1) / 6);

    var temp = spec.targetTempC + noise(0.4);
    var humidity = humidityMid + noise(2);
    var nh3 = 5.5 + noise(1.2);
    var co2 = 1700 + noise(150);
    var waterL = water * (1 + noise(0.04));
    var weight = spec.targetWeightG * (1.01 + noise(0.02));
    final detections = <CameraDetection>[];

    switch (scenario) {
      case DemoScenario.normal:
        break;
      case DemoScenario.ammonia:
        // Wet litter: humidity up, ammonia climbing past the 20 ppm smell line.
        humidity = spec.humidityMaxPct + 9 * ramp + noise(1.5);
        nh3 = 6 + 17 * ramp + noise(1);
        co2 = 2400 + 900 * ramp + noise(120);
      case DemoScenario.cold:
        temp = spec.targetTempC - 4.6 * ramp + noise(0.3);
        detections.add(_huddle);
      case DemoScenario.heat:
        temp = spec.targetTempC + 5.2 * ramp + noise(0.3);
        waterL = water * (1 + 0.38 * ramp + noise(0.03));
        detections.addAll(_heatStress);
      case DemoScenario.mortality:
        waterL = water * (1 - 0.3 * ramp + noise(0.03));
        weight = spec.targetWeightG * (0.88 + noise(0.01));
        detections.addAll(_inactive);
    }

    return BarnFrame(
      at: DateTime.now(),
      values: {
        BarnSensor.temperature: _round(temp, 1),
        BarnSensor.humidity: _round(humidity, 0),
        BarnSensor.ammonia: _round(math.max(0, nh3), 1),
        BarnSensor.co2: _round(co2, -1),
        BarnSensor.water: _round(waterL, 0),
        BarnSensor.weight: _round(weight, 0),
      },
      detections: detections,
    );
  }

  static double _round(double v, int decimals) {
    if (decimals < 0) {
      final step = math.pow(10, -decimals).toDouble();
      return (v / step).round() * step;
    }
    return double.parse(v.toStringAsFixed(decimals));
  }

  // Boxes drawn on `broiler_finisher.jpg` over birds that really are lying
  // still or packed together in that photo.
  static const _inactive = [
    CameraDetection(
      finding: CameraFinding.inactiveBird,
      left: 0.015,
      top: 0.80,
      width: 0.12,
      height: 0.11,
      confidence: 0.94,
    ),
    CameraDetection(
      finding: CameraFinding.inactiveBird,
      left: 0.315,
      top: 0.775,
      width: 0.075,
      height: 0.10,
      confidence: 0.91,
    ),
    CameraDetection(
      finding: CameraFinding.inactiveBird,
      left: 0.395,
      top: 0.76,
      width: 0.09,
      height: 0.115,
      confidence: 0.87,
    ),
  ];

  static const _huddle = CameraDetection(
    finding: CameraFinding.huddling,
    left: 0.37,
    top: 0.40,
    width: 0.36,
    height: 0.22,
    confidence: 0.89,
  );

  static const _heatStress = [
    CameraDetection(
      finding: CameraFinding.heatStress,
      left: 0.63,
      top: 0.79,
      width: 0.13,
      height: 0.14,
      confidence: 0.86,
    ),
    CameraDetection(
      finding: CameraFinding.heatStress,
      left: 0.92,
      top: 0.82,
      width: 0.08,
      height: 0.17,
      confidence: 0.81,
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
