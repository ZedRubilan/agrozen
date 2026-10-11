import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation using HTML5 `navigator.geolocation.getCurrentPosition`
/// with automatic fallback from high-accuracy GPS to low-accuracy Wi-Fi/cell triangulation.
class WebGeolocationDelegate {
  bool get isSupported => true;

  Future<({double lat, double lon})?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 7),
  }) async {
    final highAcc = await _requestPosition(
      enableHighAccuracy: true,
      timeout: timeout,
      maximumAgeMs: 300000,
    );
    if (highAcc != null) return highAcc;

    // Fallback to low-accuracy (Wi-Fi / cell positioning) if satellite GPS times out
    return _requestPosition(
      enableHighAccuracy: false,
      timeout: const Duration(seconds: 6),
      maximumAgeMs: 3600000,
    );
  }

  Future<({double lat, double lon})?> _requestPosition({
    required bool enableHighAccuracy,
    required Duration timeout,
    required int maximumAgeMs,
  }) async {
    final completer = Completer<({double lat, double lon})?>();

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    try {
      final geo = web.window.navigator.geolocation;
      geo.getCurrentPosition(
        ((web.GeolocationPosition pos) {
          timer.cancel();
          if (!completer.isCompleted) {
            final coords = pos.coords;
            completer.complete((
              lat: coords.latitude.toDouble(),
              lon: coords.longitude.toDouble(),
            ));
          }
        }).toJS,
        ((web.GeolocationPositionError err) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }).toJS,
        web.PositionOptions(
          enableHighAccuracy: enableHighAccuracy,
          timeout: timeout.inMilliseconds,
          maximumAge: maximumAgeMs,
        ),
      );
    } catch (_) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    return completer.future;
  }
}

