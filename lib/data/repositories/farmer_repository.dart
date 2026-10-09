import '../models/farmer.dart';
import '../providers/supabase_provider.dart';

class FarmerRepository {
  final SupabaseProvider _provider;

  FarmerRepository({SupabaseProvider? provider})
      : _provider = provider ?? SupabaseProvider();

  /// Create a new farmer profile
  Future<Farmer> createFarmer(Farmer farmer) async {
    try {
      final data = await _provider.createFarmer(farmer.toJson());
      return Farmer.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create farmer: $e');
    }
  }

  /// Get farmer by ID
  Future<Farmer?> getFarmer(String id) async {
    try {
      final data = await _provider.getFarmer(id);
      if (data == null) return null;
      return Farmer.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get farmer with ID $id: $e');
    }
  }

  /// Get farmer by phone number
  Future<Farmer?> getFarmerByPhone(String phone) async {
    try {
      final data = await _provider.getFarmerByPhone(phone);
      if (data == null) return null;
      return Farmer.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get farmer with phone $phone: $e');
    }
  }

  /// Update an existing farmer profile
  Future<Farmer> updateFarmer(Farmer farmer) async {
    try {
      final data = await _provider.updateFarmer(farmer.id, farmer.toJson());
      return Farmer.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update farmer: $e');
    }
  }

  /// Update specific fields for a farmer
  Future<Farmer> updateFarmerFields(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final data = await _provider.updateFarmer(id, fields);
      return Farmer.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update farmer fields: $e');
    }
  }

  /// Increment or reset the daily question count for a farmer.
  /// If lastQuestionDate is on a different calendar day, resets count to 1.
  /// Otherwise increments dailyQuestionCount.
  Future<Farmer> updateQuestionCount(String farmerId) async {
    try {
      final currentFarmer = await getFarmer(farmerId);
      if (currentFarmer == null) {
        throw Exception('Farmer not found with ID: $farmerId');
      }

      final now = DateTime.now();
      final lastDate = currentFarmer.lastQuestionDate;

      final bool isSameDay = lastDate != null &&
          lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;

      final int newCount = isSameDay ? (currentFarmer.dailyQuestionCount + 1) : 1;

      final updatedData = await _provider.updateFarmer(farmerId, {
        'daily_question_count': newCount,
        'last_question_date': now.toIso8601String(),
      });

      return Farmer.fromJson(updatedData);
    } catch (e) {
      throw Exception('Failed to update question count: $e');
    }
  }
}
