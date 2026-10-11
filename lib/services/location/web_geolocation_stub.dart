/// Non-web stub for browser geolocation.
class WebGeolocationDelegate {
  bool get isSupported => false;

  Future<({double lat, double lon})?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return null;
  }
}
