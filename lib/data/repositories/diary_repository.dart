import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../providers/supabase_provider.dart';

class DiaryRepository {
  final SupabaseProvider _provider;
  static const String _localEntriesKey = 'local_diary_entries_cache';

  DiaryRepository({SupabaseProvider? provider})
      : _provider = provider ?? SupabaseProvider();

  Future<List<DiaryEntry>> _loadLocalEntries(SharedPreferences prefs) async {
    final raw = prefs.getString(_localEntriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => DiaryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalEntries(
    SharedPreferences prefs,
    List<DiaryEntry> entries,
  ) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_localEntriesKey, encoded);
  }

  /// Add a new diary entry (mortality, feed, weight)
  Future<DiaryEntry> addEntry(DiaryEntry entry) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.createDiaryEntry(entry.toJson());
        final created = DiaryEntry.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        final list = await _loadLocalEntries(prefs);
        list.insert(0, created);
        await _saveLocalEntries(prefs, list);
        return created;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadLocalEntries(prefs);
    list.insert(0, entry);
    await _saveLocalEntries(prefs, list);
    return entry;
  }

  /// Get all diary entries for a specific batch
  Future<List<DiaryEntry>> getEntriesForBatch(String batchId) async {
    if (_provider.isConfigured) {
      try {
        final list = await _provider.getDiaryEntriesForBatch(batchId);
        return list.map((item) => DiaryEntry.fromJson(item)).toList();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadLocalEntries(prefs);
    return list
        .where((e) => e.batchId == batchId || batchId == 'local-batch')
        .toList();
  }

  /// Get diary entries recorded on a specific date for a batch
  Future<List<DiaryEntry>> getEntriesForDate(
    String batchId,
    DateTime date,
  ) async {
    if (_provider.isConfigured) {
      try {
        final list = await _provider.getDiaryEntriesForDate(batchId, date);
        return list.map((item) => DiaryEntry.fromJson(item)).toList();
      } catch (_) {}
    }
    final entries = await getEntriesForBatch(batchId);
    return entries.where((e) {
      final d = e.entryDate.toLocal();
      final target = date.toLocal();
      return d.year == target.year &&
          d.month == target.month &&
          d.day == target.day;
    }).toList();
  }

  /// Get total mortality for today for a batch
  Future<double> getTodayMortality(String batchId) async {
    final todayEntries = await getEntriesForDate(batchId, DateTime.now());
    final mortalityEntries =
        todayEntries.where((entry) => entry.entryType == 'mortality');

    double totalMortality = 0.0;
    for (final entry in mortalityEntries) {
      totalMortality += entry.value;
    }
    return totalMortality;
  }

  /// Delete a diary entry by ID
  Future<void> deleteEntry(String id) async {
    if (_provider.isConfigured) {
      try {
        await _provider.deleteDiaryEntry(id);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadLocalEntries(prefs);
    list.removeWhere((e) => e.id == id);
    await _saveLocalEntries(prefs, list);
  }
}
