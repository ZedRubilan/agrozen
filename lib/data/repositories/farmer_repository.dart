import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farmer.dart';
import '../providers/supabase_provider.dart';

class FarmerRepository {
  final SupabaseProvider _provider;
  static const String _localFarmersKey = 'local_farmers_cache';

  FarmerRepository({SupabaseProvider? provider})
      : _provider = provider ?? SupabaseProvider();

  Future<Map<String, Map<String, dynamic>>> _loadLocalFarmers(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_localFarmersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalFarmer(Farmer farmer) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadLocalFarmers(prefs);
    map[farmer.id] = farmer.toJson();
    await prefs.setString(_localFarmersKey, jsonEncode(map));
    await prefs.setString('farmer_id', farmer.id);
    if (farmer.name != null && farmer.name!.isNotEmpty) {
      await prefs.setString('farmer_name', farmer.name!);
    }
    await prefs.setString('farmer_district', farmer.district);
    await prefs.setString('app_language', farmer.language);
    await prefs.setBool('disclaimer_accepted', farmer.disclaimerAccepted);
  }

  /// Create a new farmer profile
  Future<Farmer> createFarmer(Farmer farmer) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.createFarmer(farmer.toJson());
        final created = Farmer.fromJson(data);
        await _saveLocalFarmer(created);
        return created;
      } catch (_) {}
    }
    await _saveLocalFarmer(farmer);
    return farmer;
  }

  /// Get farmer by ID
  Future<Farmer?> getFarmer(String id) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.getFarmer(id);
        if (data != null) {
          final farmer = Farmer.fromJson(data);
          await _saveLocalFarmer(farmer);
          return farmer;
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadLocalFarmers(prefs);
    if (map.containsKey(id)) {
      return Farmer.fromJson(map[id]!);
    }
    final storedName = prefs.getString('farmer_name');
    final storedDistrict = prefs.getString('farmer_district');
    if (storedName != null || storedDistrict != null) {
      return Farmer(
        id: id,
        name: storedName ?? 'Fermer',
        language: prefs.getString('app_language') ?? 'uz',
        district: storedDistrict ?? 'Toshkent',
        disclaimerAccepted: prefs.getBool('disclaimer_accepted') ?? false,
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  /// Get farmer by phone number
  Future<Farmer?> getFarmerByPhone(String phone) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.getFarmerByPhone(phone);
        if (data != null) return Farmer.fromJson(data);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadLocalFarmers(prefs);
    for (final entry in map.values) {
      if (entry['phone'] == phone) {
        return Farmer.fromJson(entry);
      }
    }
    return null;
  }

  /// Update an existing farmer profile
  Future<Farmer> updateFarmer(Farmer farmer) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.updateFarmer(farmer.id, farmer.toJson());
        final updated = Farmer.fromJson(data);
        await _saveLocalFarmer(updated);
        return updated;
      } catch (_) {}
    }
    await _saveLocalFarmer(farmer);
    return farmer;
  }

  /// Update specific fields for a farmer
  Future<Farmer> updateFarmerFields(
    String id,
    Map<String, dynamic> fields,
  ) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.updateFarmer(id, fields);
        final updated = Farmer.fromJson(data);
        await _saveLocalFarmer(updated);
        return updated;
      } catch (_) {}
    }
    final existing = await getFarmer(id) ??
        Farmer(
          id: id,
          district: 'Toshkent',
          createdAt: DateTime.now(),
        );
    final merged = <String, dynamic>{
      ...existing.toJson(),
      ...fields,
    };
    final updated = Farmer.fromJson(merged);
    await _saveLocalFarmer(updated);
    return updated;
  }

  /// Increment or reset the daily question count for a farmer.
  /// If lastQuestionDate is on a different calendar day, resets count to 1.
  /// Otherwise increments dailyQuestionCount.
  Future<Farmer> updateQuestionCount(String farmerId) async {
    final currentFarmer = await getFarmer(farmerId) ??
        Farmer(
          id: farmerId,
          district: 'Toshkent',
          createdAt: DateTime.now(),
        );

    final now = DateTime.now();
    final lastDate = currentFarmer.lastQuestionDate;

    final bool isSameDay = lastDate != null &&
        lastDate.year == now.year &&
        lastDate.month == now.month &&
        lastDate.day == now.day;

    final int newCount =
        isSameDay ? (currentFarmer.dailyQuestionCount + 1) : 1;

    return updateFarmerFields(farmerId, {
      'daily_question_count': newCount,
      'last_question_date': now.toIso8601String(),
    });
  }
}
