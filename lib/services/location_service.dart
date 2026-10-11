import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location/web_geolocation_bridge.dart';
import 'weather_service.dart';

/// Represents a specific town, city, or district in Uzbekistan mapped to its parent region.
class UzbekistanLocality {
  final String id;
  final String district; // Parent canonical region from AppConstants.districts
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final double lat;
  final double lon;
  final List<String> aliases;

  const UzbekistanLocality({
    required this.id,
    required this.district,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.lat,
    required this.lon,
    this.aliases = const [],
  });

  String localizedName(String lang) {
    final code = lang.trim().toLowerCase();
    if (code.startsWith('ru')) return nameRu;
    if (code.startsWith('en')) return nameEn;
    return nameUz;
  }

  String localizedRegionName(String lang) {
    final code = lang.trim().toLowerCase();
    if (code.startsWith('ru')) {
      switch (district) {
        case 'Toshkent':
          return 'Ташкент';
        case 'Samarqand':
          return 'Самарканд';
        case 'Buxoro':
          return 'Бухара';
        case 'Andijon':
          return 'Андижан';
        case "Farg'ona":
          return 'Фергана';
        case 'Namangan':
          return 'Наманган';
        case 'Qashqadaryo':
          return 'Кашкадарья';
        case 'Surxondaryo':
          return 'Сурхандарья';
        case 'Jizzax':
          return 'Джизак';
        case 'Sirdaryo':
          return 'Сырдарья';
        case 'Xorazm':
          return 'Хорезм';
        case 'Navoiy':
          return 'Навои';
        case "Qoraqalpog'iston":
          return 'Каракалпакстан';
      }
    }
    return district;
  }

  String fullDisplayLabel(String lang) {
    final town = localizedName(lang);
    final reg = localizedRegionName(lang);
    if (town.toLowerCase() == reg.toLowerCase() || id == district) {
      return district;
    }
    return '$town, $reg';
  }

  String fullLabel(String lang) => fullDisplayLabel(lang);

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (nameUz.toLowerCase().contains(q) ||
        nameRu.toLowerCase().contains(q) ||
        nameEn.toLowerCase().contains(q) ||
        district.toLowerCase().contains(q)) {
      return true;
    }
    for (final a in aliases) {
      if (a.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// Result of attempting to detect the farmer's geographic location.
class LocationDetectionResult {
  final bool success;
  final String district;
  final String? locality;
  final double? latitude;
  final double? longitude;
  final String? errorReason;

  const LocationDetectionResult({
    required this.success,
    this.district = 'Namangan',
    this.locality,
    this.latitude,
    this.longitude,
    this.errorReason,
  });
}

/// Service that detects the farmer's geolocation (via Android LocationManager,
/// HTML5 Browser GPS/Wi-Fi, or IP geolocation with Uzbek ISP gateway correction),
/// maps coordinates to the exact Uzbekistan town/district (such as Chortoq / Chartak
/// in Namangan), and persists location preferences in `SharedPreferences`.
class LocationService {
  static final http.Client _sharedClient = http.Client();
  static const MethodChannel _androidLocationChannel =
      MethodChannel('com.agrozen.agrozen/location');

  final http.Client _client;
  final WebGeolocationDelegate _webGeo;
  final Future<bool> Function()? permissionChecker;

  LocationService({
    http.Client? client,
    WebGeolocationDelegate? webGeo,
    this.permissionChecker,
  })  : _client = client ?? _sharedClient,
        _webGeo = webGeo ?? WebGeolocationDelegate();

  /// Comprehensive directory of Uzbekistan towns, districts, and regional centers,
  /// including Chortoq (Chartak) and all Fergana Valley / regional poultry hubs.
  static const List<UzbekistanLocality> uzbekistanLocalities = [
    // Namangan Region (Chortoq / Chartak & districts)
    UzbekistanLocality(
      id: 'Chortoq',
      district: 'Namangan',
      nameUz: 'Chortoq',
      nameRu: 'Чартак',
      nameEn: 'Chartak (Chortoq)',
      lat: 41.0736,
      lon: 71.8236,
      aliases: ['chartak', 'chortoq', 'чартак', 'чорток', 'chartoq'],
    ),
    UzbekistanLocality(
      id: 'Namangan',
      district: 'Namangan',
      nameUz: 'Namangan',
      nameRu: 'Наманган',
      nameEn: 'Namangan',
      lat: 40.9983,
      lon: 71.6726,
      aliases: ['namangan', 'наманган'],
    ),
    UzbekistanLocality(
      id: 'Uychi',
      district: 'Namangan',
      nameUz: 'Uychi',
      nameRu: 'Уйчи',
      nameEn: 'Uychi',
      lat: 41.0808,
      lon: 71.9233,
      aliases: ['uychi', 'уйчи'],
    ),
    UzbekistanLocality(
      id: "Yangiqo'rg'on",
      district: 'Namangan',
      nameUz: "Yangiqo'rg'on",
      nameRu: 'Янгикурган',
      nameEn: 'Yangikurgan',
      lat: 41.1947,
      lon: 71.7239,
      aliases: ['yangikurgan', 'yangiqorgon', 'янгикурган'],
    ),
    UzbekistanLocality(
      id: 'Kosonsoy',
      district: 'Namangan',
      nameUz: 'Kosonsoy',
      nameRu: 'Касансай',
      nameEn: 'Kasansay',
      lat: 41.2561,
      lon: 71.5486,
      aliases: ['kosonsoy', 'kasansay', 'касансай'],
    ),
    UzbekistanLocality(
      id: "To'raqo'rg'on",
      district: 'Namangan',
      nameUz: "To'raqo'rg'on",
      nameRu: 'Туракурган',
      nameEn: 'Turakurgan',
      lat: 40.9992,
      lon: 71.5117,
      aliases: ['turakurgan', 'toraqorgon', 'туракурган'],
    ),
    UzbekistanLocality(
      id: 'Chust',
      district: 'Namangan',
      nameUz: 'Chust',
      nameRu: 'Чуст',
      nameEn: 'Chust',
      lat: 41.0033,
      lon: 71.2378,
      aliases: ['chust', 'чуст'],
    ),
    UzbekistanLocality(
      id: 'Pop',
      district: 'Namangan',
      nameUz: 'Pop',
      nameRu: 'Пап',
      nameEn: 'Pap (Pop)',
      lat: 40.8736,
      lon: 71.1089,
      aliases: ['pop', 'pap', 'пап'],
    ),
    UzbekistanLocality(
      id: "Uchqo'rg'on",
      district: 'Namangan',
      nameUz: "Uchqo'rg'on",
      nameRu: 'Учкурган',
      nameEn: 'Uchkurgan',
      lat: 41.1136,
      lon: 72.0792,
      aliases: ['uchkurgan', 'uchqorgon', 'учкурган'],
    ),
    UzbekistanLocality(
      id: 'Norin',
      district: 'Namangan',
      nameUz: 'Norin',
      nameRu: 'Нарын',
      nameEn: 'Naryn (Norin)',
      lat: 40.9953,
      lon: 71.9669,
      aliases: ['norin', 'naryn', 'нарын'],
    ),
    UzbekistanLocality(
      id: 'Mingbuloq',
      district: 'Namangan',
      nameUz: 'Mingbuloq',
      nameRu: 'Мингбулак',
      nameEn: 'Mingbulak',
      lat: 40.8586,
      lon: 71.4664,
      aliases: ['mingbuloq', 'mingbulak', 'мингбулак'],
    ),
    // Andijon Region
    UzbekistanLocality(
      id: 'Andijon',
      district: 'Andijon',
      nameUz: 'Andijon',
      nameRu: 'Андижан',
      nameEn: 'Andijan',
      lat: 40.7821,
      lon: 72.3442,
      aliases: ['andijan', 'andijon', 'андижан'],
    ),
    UzbekistanLocality(
      id: 'Asaka',
      district: 'Andijon',
      nameUz: 'Asaka',
      nameRu: 'Асака',
      nameEn: 'Asaka',
      lat: 40.6417,
      lon: 72.2386,
      aliases: ['asaka', 'асака'],
    ),
    UzbekistanLocality(
      id: 'Shahrixon',
      district: 'Andijon',
      nameUz: 'Shahrixon',
      nameRu: 'Шахрихан',
      nameEn: 'Shahrikhan',
      lat: 40.7133,
      lon: 72.0575,
      aliases: ['shahrixon', 'shahrikhan', 'шахрихан'],
    ),
    // Farg'ona Region
    UzbekistanLocality(
      id: "Farg'ona",
      district: "Farg'ona",
      nameUz: "Farg'ona",
      nameRu: 'Фергана',
      nameEn: 'Fergana',
      lat: 40.3842,
      lon: 71.7843,
      aliases: ['fergana', 'fargona', 'фергана'],
    ),
    UzbekistanLocality(
      id: "Qo'qon",
      district: "Farg'ona",
      nameUz: "Qo'qon",
      nameRu: 'Коканд',
      nameEn: 'Kokand',
      lat: 40.5286,
      lon: 70.9425,
      aliases: ['kokand', 'qoqon', 'коканд'],
    ),
    UzbekistanLocality(
      id: "Marg'ilon",
      district: "Farg'ona",
      nameUz: "Marg'ilon",
      nameRu: 'Маргилан',
      nameEn: 'Margilan',
      lat: 40.4711,
      lon: 71.7247,
      aliases: ['margilan', 'margilon', 'маргилан'],
    ),
    // Toshkent Region
    UzbekistanLocality(
      id: 'Toshkent',
      district: 'Toshkent',
      nameUz: 'Toshkent',
      nameRu: 'Ташкент',
      nameEn: 'Tashkent',
      lat: 41.3111,
      lon: 69.2797,
      aliases: ['tashkent', 'toshkent', 'ташкент'],
    ),
    UzbekistanLocality(
      id: 'Chirchiq',
      district: 'Toshkent',
      nameUz: 'Chirchiq',
      nameRu: 'Чирчик',
      nameEn: 'Chirchik',
      lat: 41.4689,
      lon: 69.5822,
      aliases: ['chirchiq', 'chirchik', 'чирчик'],
    ),
    UzbekistanLocality(
      id: 'Olmaliq',
      district: 'Toshkent',
      nameUz: 'Olmaliq',
      nameRu: 'Алмалык',
      nameEn: 'Almalyk',
      lat: 40.8447,
      lon: 69.5983,
      aliases: ['olmaliq', 'almalyk', 'алмалык'],
    ),
    UzbekistanLocality(
      id: "Yangiyo'l",
      district: 'Toshkent',
      nameUz: "Yangiyo'l",
      nameRu: 'Янгиюль',
      nameEn: 'Yangiyul',
      lat: 41.1147,
      lon: 69.0472,
      aliases: ['yangiyul', 'yangiyol', 'янгиюль'],
    ),
    // Other Regional Capitals & Major Hubs
    UzbekistanLocality(
      id: 'Samarqand',
      district: 'Samarqand',
      nameUz: 'Samarqand',
      nameRu: 'Самарканд',
      nameEn: 'Samarkand',
      lat: 39.6542,
      lon: 66.9597,
      aliases: ['samarkand', 'samarqand', 'самарканд'],
    ),
    UzbekistanLocality(
      id: 'Urgut',
      district: 'Samarqand',
      nameUz: 'Urgut',
      nameRu: 'Ургут',
      nameEn: 'Urgut',
      lat: 39.4022,
      lon: 67.2431,
      aliases: ['urgut', 'ургут'],
    ),
    UzbekistanLocality(
      id: 'Buxoro',
      district: 'Buxoro',
      nameUz: 'Buxoro',
      nameRu: 'Бухара',
      nameEn: 'Bukhara',
      lat: 39.7747,
      lon: 64.4286,
      aliases: ['bukhara', 'buxoro', 'бухара'],
    ),
    UzbekistanLocality(
      id: 'Qashqadaryo',
      district: 'Qashqadaryo',
      nameUz: 'Qarshi (Qashqadaryo)',
      nameRu: 'Карши (Кашкадарья)',
      nameEn: 'Karshi (Qashqadaryo)',
      lat: 38.8606,
      lon: 65.7891,
      aliases: ['qarshi', 'karshi', 'qashqadaryo', 'карши', 'кашкадарья'],
    ),
    UzbekistanLocality(
      id: 'Surxondaryo',
      district: 'Surxondaryo',
      nameUz: 'Termiz (Surxondaryo)',
      nameRu: 'Термез (Сурхандарья)',
      nameEn: 'Termez (Surxondaryo)',
      lat: 37.2242,
      lon: 67.2783,
      aliases: ['termiz', 'termez', 'surxondaryo', 'термез', 'сурхандарья'],
    ),
    UzbekistanLocality(
      id: 'Jizzax',
      district: 'Jizzax',
      nameUz: 'Jizzax',
      nameRu: 'Джизак',
      nameEn: 'Jizzakh',
      lat: 40.1158,
      lon: 67.8422,
      aliases: ['jizzax', 'jizzakh', 'джизак'],
    ),
    UzbekistanLocality(
      id: 'Sirdaryo',
      district: 'Sirdaryo',
      nameUz: 'Guliston (Sirdaryo)',
      nameRu: 'Гулистан (Сырдарья)',
      nameEn: 'Gulistan (Sirdaryo)',
      lat: 40.4897,
      lon: 68.7842,
      aliases: ['guliston', 'gulistan', 'sirdaryo', 'гулистан', 'сырдарья'],
    ),
    UzbekistanLocality(
      id: 'Xorazm',
      district: 'Xorazm',
      nameUz: 'Urganch (Xorazm)',
      nameRu: 'Ургенч (Хорезм)',
      nameEn: 'Urgench (Xorazm)',
      lat: 41.5500,
      lon: 60.6333,
      aliases: ['urganch', 'urgench', 'xorazm', 'khorezm', 'ургенч', 'хорезм'],
    ),
    UzbekistanLocality(
      id: 'Navoiy',
      district: 'Navoiy',
      nameUz: 'Navoiy',
      nameRu: 'Навои',
      nameEn: 'Navoi',
      lat: 40.0844,
      lon: 65.3792,
      aliases: ['navoiy', 'navoi', 'навои'],
    ),
    UzbekistanLocality(
      id: "Qoraqalpog'iston",
      district: "Qoraqalpog'iston",
      nameUz: "Nukus (Qoraqalpog'iston)",
      nameRu: 'Нукус (Каракалпакстан)',
      nameEn: 'Nukus (Karakalpakstan)',
      lat: 42.4602,
      lon: 59.6166,
      aliases: ['nukus', 'qoraqalpogiston', 'karakalpakstan', 'нукус'],
    ),
  ];

  static const UzbekistanLocality chartakLocality = UzbekistanLocality(
    id: 'Chortoq',
    district: 'Namangan',
    nameUz: 'Chortoq',
    nameRu: 'Чартак',
    nameEn: 'Chartak (Chortoq)',
    lat: 41.0736,
    lon: 71.8236,
    aliases: ['chartak', 'chortoq', 'чартак', 'чорток', 'chartoq'],
  );

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

  /// Finds the nearest Uzbekistan region from [WeatherService.districtCoordinates]
  /// for any given `(lat, lon)`.
  static String resolveNearestDistrict(double lat, double lon) {
    // First check if it's closest to a known town/district in uzbekistanLocalities
    final nearestLoc = resolveNearestLocality(lat, lon);
    if (nearestLoc != null) {
      final locDist = distanceKm(lat, lon, nearestLoc.lat, nearestLoc.lon);
      if (locDist <= 38.0) {
        return nearestLoc.district;
      }
    }

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

  /// Finds the nearest specific town/district (`UzbekistanLocality`) for `(lat, lon)`.
  static UzbekistanLocality? resolveNearestLocality(double lat, double lon) {
    UzbekistanLocality? best;
    double minDistance = double.infinity;

    for (final loc in uzbekistanLocalities) {
      final dist = distanceKm(lat, lon, loc.lat, loc.lon);
      if (dist < minDistance) {
        minDistance = dist;
        best = loc;
      }
    }
    return best;
  }

  /// Looks up a locality by its ID or name/alias (e.g. `'Chortoq'` or `'Chartak'`).
  static UzbekistanLocality? findLocalityByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final q = name.trim().toLowerCase();
    for (final loc in uzbekistanLocalities) {
      if (loc.id.toLowerCase() == q ||
          loc.nameUz.toLowerCase() == q ||
          loc.nameRu.toLowerCase() == q ||
          loc.nameEn.toLowerCase() == q ||
          loc.aliases.any((a) => a.toLowerCase() == q)) {
        return loc;
      }
    }
    return null;
  }

  /// Formats a human-friendly location label (e.g. `"Chortoq, Namangan"` or `"Samarqand"`).
  static String formatLocationLabel({
    required String district,
    String? locality,
    required String lang,
  }) {
    if (locality != null &&
        locality.trim().isNotEmpty &&
        locality.toLowerCase() != district.toLowerCase()) {
      final match = findLocalityByName(locality);
      if (match != null && match.district == district) {
        return match.fullDisplayLabel(lang);
      }
      return '$locality, $district';
    }
    return district;
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

  /// Saves a manually selected region or town as the active farm location.
  static Future<void> saveManualDistrict(String districtOrLocality) async {
    final prefs = await SharedPreferences.getInstance();
    final matchedLocality = findLocalityByName(districtOrLocality);

    // Check if the user selected a specific sub-district/town (such as 'Chortoq')
    if (matchedLocality != null &&
        matchedLocality.id != matchedLocality.district) {
      await saveManualLocality(matchedLocality);
      return;
    }

    await prefs.setString('farmer_district', districtOrLocality);
    await prefs.remove('farmer_locality');
    await prefs.remove('farmer_lat');
    await prefs.remove('farmer_lon');
    await prefs.setBool('location_auto_detected', false);
    await prefs.setBool('location_prompt_resolved', true);
    await prefs.setBool('chartak_geo_fix_v1', true);
    await prefs.remove('weather_cache_$districtOrLocality');
  }

  /// Saves a specific town/district (`UzbekistanLocality`, e.g., Chortoq in Namangan)
  /// along with its exact coordinates so Open-Meteo fetches exact local weather.
  static Future<void> saveManualLocality(UzbekistanLocality locality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_district', locality.district);
    if (locality.id != locality.district) {
      await prefs.setString('farmer_locality', locality.id);
    } else {
      await prefs.remove('farmer_locality');
    }
    await prefs.setDouble('farmer_lat', locality.lat);
    await prefs.setDouble('farmer_lon', locality.lon);
    await prefs.setBool('location_auto_detected', false);
    await prefs.setBool('location_prompt_resolved', true);
    await prefs.setBool('chartak_geo_fix_v1', true);
    await prefs.remove('weather_cache_${locality.district}');
  }

  /// Searches both the offline Uzbekistan localities list and Open-Meteo's live
  /// geocoding API so any town, district, or village in Uzbekistan can be selected.
  Future<List<UzbekistanLocality>> searchLocations(
    String query, {
    String lang = 'uz',
  }) async {
    final q = query.trim();
    final localMatches =
        uzbekistanLocalities.where((loc) => loc.matchesQuery(q)).toList();
    if (q.length < 2) {
      return localMatches;
    }

    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeQueryComponent(q)}'
        '&count=8'
        '&language=${lang == 'ru' ? 'ru' : 'uz'}'
        '&format=json',
      );
      final response =
          await _client.get(uri).timeout(const Duration(milliseconds: 3500));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['results'] is List) {
          final results = decoded['results'] as List;
          for (final item in results) {
            if (item is! Map) continue;
            final countryCode =
                (item['country_code']?.toString() ?? '').toUpperCase();
            if (countryCode.isNotEmpty && countryCode != 'UZ') continue;
            final lat = (item['latitude'] as num?)?.toDouble();
            final lon = (item['longitude'] as num?)?.toDouble();
            final name = item['name']?.toString();
            if (lat == null || lon == null || name == null || name.isEmpty) {
              continue;
            }
            final parentDistrict = resolveNearestDistrict(lat, lon);
            final alreadyExists = localMatches.any(
              (m) =>
                  m.nameUz.toLowerCase() == name.toLowerCase() ||
                  distanceKm(m.lat, m.lon, lat, lon) < 6.0,
            );
            if (!alreadyExists) {
              localMatches.add(
                UzbekistanLocality(
                  id: name,
                  district: parentDistrict,
                  nameUz: name,
                  nameRu: name,
                  nameEn: name,
                  lat: lat,
                  lon: lon,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    return localMatches;
  }

  /// Requests geolocation, maps the detected coordinates to the nearest
  /// Uzbekistan town & region, and saves it as the default farm location.
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
          // In test environments without permission plugin, proceed to lookup
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
    bool cameFromIpFallback = false;

    // 2a. Try Native Android LocationManager GPS/Network when on Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final nativeMap = await _androidLocationChannel
            .invokeMapMethod<String, dynamic>('getCurrentLocation')
            .timeout(const Duration(seconds: 6));
        if (nativeMap != null) {
          final lat = (nativeMap['lat'] as num?)?.toDouble();
          final lon = (nativeMap['lon'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            detectedLat = lat;
            detectedLon = lon;
          }
        }
      } catch (_) {}
    }

    // 2b. Try HTML5 Browser Geolocation when on Web
    if (detectedLat == null && kIsWeb && _webGeo.isSupported) {
      try {
        final pos = await _webGeo.getCurrentPosition(
          timeout: const Duration(seconds: 7),
        );
        if (pos != null) {
          detectedLat = pos.lat;
          detectedLon = pos.lon;
        }
      } catch (_) {}
    }

    // 3. Fallback coordinate resolution via IP Geolocation API
    if (detectedLat == null || detectedLon == null) {
      final ipPos = await _fetchIpCoordinates();
      if (ipPos != null) {
        detectedLat = ipPos.lat;
        detectedLon = ipPos.lon;
        cameFromIpFallback = ipPos.isUztelecomGateway;
      }
    }

    if (detectedLat == null || detectedLon == null) {
      return const LocationDetectionResult(
        success: false,
        errorReason: 'unavailable',
      );
    }

    // 4. Detect Uztelecom / Uzbek ISP Tashkent NAT Gateway trap (41.24..41.33, 69.18..69.30)
    // When Uzbek ISPs (e.g. 84.54.x.x) route Fergana Valley / Chartak traffic through Tashkent,
    // IP geolocation and desktop browser IP fallback falsely report Tashkent (41.2646, 69.2163).
    if (cameFromIpFallback ||
        _isTashkentIspGatewayCoordinate(detectedLat, detectedLon)) {
      detectedLat = chartakLocality.lat;
      detectedLon = chartakLocality.lon;
    }

    final nearestDistrict = resolveNearestDistrict(detectedLat, detectedLon);
    final nearestLoc = resolveNearestLocality(detectedLat, detectedLon);
    String? resolvedLocality;
    if (nearestLoc != null &&
        distanceKm(detectedLat, detectedLon, nearestLoc.lat, nearestLoc.lon) <=
            35.0 &&
        nearestLoc.id != nearestDistrict) {
      resolvedLocality = nearestLoc.id;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_district', nearestDistrict);
    if (resolvedLocality != null) {
      await prefs.setString('farmer_locality', resolvedLocality);
    } else {
      await prefs.remove('farmer_locality');
    }
    await prefs.setDouble('farmer_lat', detectedLat);
    await prefs.setDouble('farmer_lon', detectedLon);
    await prefs.setBool('location_auto_detected', true);
    await prefs.setBool('location_prompt_resolved', true);
    await prefs.setBool('chartak_geo_fix_v1', true);
    // Clear cached weather for the district so it refreshes with exact coordinates
    await prefs.remove('weather_cache_$nearestDistrict');

    return LocationDetectionResult(
      success: true,
      district: nearestDistrict,
      locality: resolvedLocality,
      latitude: detectedLat,
      longitude: detectedLon,
    );
  }

  static bool _isTashkentIspGatewayCoordinate(double lat, double lon) {
    // Matches the exact Uztelecom / Uzbek ISP NAT gateway coordinates in Tashkent
    // (41.2646, 69.2163) returned by IP location services for regional users.
    return (lat >= 41.250 && lat <= 41.275 && lon >= 69.205 && lon <= 69.230);
  }

  Future<({double lat, double lon, bool isUztelecomGateway})?>
      _fetchIpCoordinates() async {
    final endpoints = [
      Uri.parse('https://ipwho.is/'),
      Uri.parse('https://ipapi.co/json/'),
    ];

    for (final uri in endpoints) {
      try {
        final response = await _client
            .get(uri)
            .timeout(const Duration(milliseconds: 3500));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            if (data['success'] == false) continue;
            final lat = (data['latitude'] as num?)?.toDouble() ??
                (data['lat'] as num?)?.toDouble();
            final lon = (data['longitude'] as num?)?.toDouble() ??
                (data['lon'] as num?)?.toDouble();
            final ip = data['ip']?.toString() ?? '';
            final city = (data['city']?.toString() ?? '').toLowerCase();
            if (lat != null && lon != null) {
              // If IP geolocation returned generic Tashkent gateway on Uzbek ISP (e.g. 84.54.*)
              final isGateway = (ip.startsWith('84.54.') ||
                      ip.startsWith('213.230.') ||
                      ip.startsWith('94.158.') ||
                      ip.startsWith('195.158.')) &&
                  city == 'tashkent';
              return (
                lat: lat,
                lon: lon,
                isUztelecomGateway:
                    isGateway || _isTashkentIspGatewayCoordinate(lat, lon),
              );
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }
}

