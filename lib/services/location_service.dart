import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location/web_geolocation_bridge.dart';
import 'weather_service.dart';

/// Result of attempting to detect the farmer's geographic location.
class LocationDetectionResult {
  final bool success;
  final String district;
  final double? latitude;
  final double? longitude;
  final String? errorReason;

  const LocationDetectionResult({
    required this.success,
    this.district = 'Toshkent',
    this.latitude,
    this.longitude,
    this.errorReason,
  });
}

/// Service that detects the farmer's geolocation (via browser GPS, mobile permissions,
/// or IP geolocation fallback), maps coordinates to the nearest Uzbekistan region,
/// and persists location preferences in `SharedPreferences`.
class LocationService {
  static final http.Client _sharedClient = http.Client();
  final http.Client _client;
  final WebGeolocationDelegate _webGeo;
  final Future<bool> Function()? permissionChecker;

  LocationService({
    http.Client? client,
    WebGeolocationDelegate? webGeo,
    this.permissionChecker,
  })  : _client = client ?? _sharedClient,
        _webGeo = webGeo ?? WebGeolocationDelegate();

  /// Great-circle Haversine distance in kilometers between two coordinates.
  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);

  /// Finds the nearest Uzbekistan district from [WeatherService.districtCoordinates]
  /// for any given `(lat, lon)`.
  static String resolveNearestDistrict(double lat, double lon) {
    String bestDistrict = 'Toshkent';
    double minDistance = double.infinity;

    for (final entry in WeatherService.districtCoordinates.entries) {
      final dist = distanceKm(lat, lon, entry.value.lat, entry.value.lon);
      if (dist < minDistance) {
        minDistance = dist;
        bestDistrict = entry.key;
      }
    }
    return bestDistrict;
  }

  /// Checks whether the user has already resolved the initial geolocation prompt.
  static Future<bool> isLocationPromptResolved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('location_prompt_resolved') ?? false;
  }

  /// Marks the initial geolocation prompt as resolved so it does not nag again.
  static Future<void> dismissLocationPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_prompt_resolved', true);
  }

  /// Alias for [dismissLocationPrompt].
  static Future<void> markLocationPromptResolved() => dismissLocationPrompt();

  /// Saves a manually selected region as the active farm location and clears
  /// any previous GPS coordinate override so weather uses the region's coordinates.
  static Future<void> saveManualDistrict(String district) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_district', district);
    await prefs.remove('farmer_lat');
    await prefs.remove('farmer_lon');
    await prefs.setBool('location_auto_detected', false);
    await prefs.setBool('location_prompt_resolved', true);
  }

  /// Requests geolocation, maps the detected coordinates to the nearest
  /// Uzbekistan region, and saves it as the default farm location.
  Future<LocationDetectionResult> detectAndSaveLocation() async {
    // 1. Check mobile permission when running on Android / iOS
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      bool granted = true;
      final checker = permissionChecker;
      if (checker != null) {
        granted = await checker();
      } else {
        try {
          final status = await Permission.locationWhenInUse.request();
          granted = status.isGranted || status.isLimited;
        } catch (_) {
          // In test environments without permission plugin, proceed to network lookup
          granted = true;
        }
      }
      if (!granted) {
        return const LocationDetectionResult(
          success: false,
          errorReason: 'permission_denied',
        );
      }
    }

    double? detectedLat;
    double? detectedLon;

    // 2. Try HTML5 Browser Geolocation first when on Web
    if (kIsWeb && _webGeo.isSupported) {
      try {
        final pos = await _webGeo.getCurrentPosition(
          timeout: const Duration(seconds: 4),
        );
        if (pos != null) {
          detectedLat = pos.lat;
          detectedLon = pos.lon;
        }
      } catch (_) {}
    }

    // 3. Fallback / Native coordinate resolution via IP Geolocation API
    if (detectedLat == null || detectedLon == null) {
      final ipPos = await _fetchIpCoordinates();
      if (ipPos != null) {
        detectedLat = ipPos.lat;
        detectedLon = ipPos.lon;
      }
    }

    if (detectedLat == null || detectedLon == null) {
      return const LocationDetectionResult(
        success: false,
        errorReason: 'unavailable',
      );
    }

    final nearestDistrict = resolveNearestDistrict(detectedLat, detectedLon);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_district', nearestDistrict);
    await prefs.setDouble('farmer_lat', detectedLat);
    await prefs.setDouble('farmer_lon', detectedLon);
    await prefs.setBool('location_auto_detected', true);
    await prefs.setBool('location_prompt_resolved', true);
    // Clear cached weather for the district so it refreshes with exact coordinates
    await prefs.remove('weather_cache_$nearestDistrict');

    return LocationDetectionResult(
      success: true,
      district: nearestDistrict,
      latitude: detectedLat,
      longitude: detectedLon,
    );
  }

  Future<({double lat, double lon})?> _fetchIpCoordinates() async {
    final endpoints = [
      Uri.parse('https://ipwho.is/'),
      Uri.parse('https://ipapi.co/json/'),
    ];

    for (final uri in endpoints) {
      try {
        final response = await _client
            .get(uri)
            .timeout(const Duration(milliseconds: 2500));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            if (data['success'] == false) continue;
            final lat = (data['latitude'] as num?)?.toDouble() ??
                (data['lat'] as num?)?.toDouble();
            final lon = (data['longitude'] as num?)?.toDouble() ??
                (data['lon'] as num?)?.toDouble();
            if (lat != null && lon != null) {
              return (lat: lat, lon: lon);
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
