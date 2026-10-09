import '../models/diary_entry.dart';
import '../providers/supabase_provider.dart';

class DiaryRepository {
  final SupabaseProvider _provider;

  DiaryRepository({SupabaseProvider? provider})
      : _provider = provider ?? SupabaseProvider();

  /// Add a new diary entry (mortality, feed, weight)
  Future<DiaryEntry> addEntry(DiaryEntry entry) async {
    try {
      final data = await _provider.createDiaryEntry(entry.toJson());
      return DiaryEntry.fromJson(data);
    } catch (e) {
      throw Exception('Failed to add diary entry: $e');
    }
  }

  /// Get all diary entries for a specific batch
  Future<List<DiaryEntry>> getEntriesForBatch(String batchId) async {
    try {
      final list = await _provider.getDiaryEntriesForBatch(batchId);
      return list.map((item) => DiaryEntry.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get entries for batch: $e');
    }
  }

  /// Get diary entries recorded on a specific date for a batch
  Future<List<DiaryEntry>> getEntriesForDate(
    String batchId,
    DateTime date,
  ) async {
    try {
      final list = await _provider.getDiaryEntriesForDate(batchId, date);
      return list.map((item) => DiaryEntry.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get entries for date: $e');
    }
  }

  /// Get total mortality for today for a batch
  Future<double> getTodayMortality(String batchId) async {
    try {
      final todayEntries = await getEntriesForDate(batchId, DateTime.now());
      final mortalityEntries =
          todayEntries.where((entry) => entry.entryType == 'mortality');

      double totalMortality = 0.0;
      for (final entry in mortalityEntries) {
        totalMortality += entry.value;
      }
      return totalMortality;
    } catch (e) {
      throw Exception('Failed to calculate today mortality: $e');
    }
  }

  /// Delete a diary entry by ID
  Future<void> deleteEntry(String id) async {
    try {
      await _provider.deleteDiaryEntry(id);
    } catch (e) {
      throw Exception('Failed to delete diary entry: $e');
    }
  }
}
