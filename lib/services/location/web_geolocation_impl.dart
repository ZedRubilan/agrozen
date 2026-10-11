import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation using HTML5 `navigator.geolocation.getCurrentPosition`.
class WebGeolocationDelegate {
  bool get isSupported => true;

  Future<({double lat, double lon})?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 5),
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
          enableHighAccuracy: true,
          timeout: timeout.inMilliseconds,
          maximumAge: 300000,
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
