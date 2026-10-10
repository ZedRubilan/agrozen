import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batch.dart';
import '../providers/supabase_provider.dart';

class BatchRepository {
  final SupabaseProvider _provider;
  static const String _localBatchesKey = 'local_batches_cache';

  BatchRepository({SupabaseProvider? provider})
      : _provider = provider ?? SupabaseProvider();

  Future<Map<String, Map<String, dynamic>>> _loadLocalBatches(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_localBatchesKey);
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

  Future<void> _saveLocalBatch(Batch batch) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadLocalBatches(prefs);
    map[batch.id] = batch.toJson();
    await prefs.setString(_localBatchesKey, jsonEncode(map));
    if (batch.status == 'active') {
      await prefs.setString('batch_id', batch.id);
      await prefs.setString('arrival_date', batch.arrivalDate.toIso8601String());
      await prefs.setInt('initial_count', batch.initialCount);
      await prefs.setInt(
        'current_count',
        batch.currentCount ?? batch.initialCount,
      );
    }
  }

  /// Create a new poultry batch
  Future<Batch> createBatch(Batch batch) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.createBatch(batch.toJson());
        final created = Batch.fromJson(data);
        await _saveLocalBatch(created);
        return created;
      } catch (_) {}
    }
    await _saveLocalBatch(batch);
    return batch;
  }

  /// Get the currently active batch for a given farmer
  Future<Batch?> getActiveBatch(String farmerId) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.getActiveBatch(farmerId);
        if (data != null) {
          final batch = Batch.fromJson(data);
          await _saveLocalBatch(batch);
          return batch;
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadLocalBatches(prefs);
    for (final entry in map.values) {
      if (entry['farmer_id'] == farmerId && entry['status'] == 'active') {
        return Batch.fromJson(entry);
      }
    }
    final arrivalStr = prefs.getString('arrival_date');
    final initialCount = prefs.getInt('initial_count');
    if (arrivalStr != null || initialCount != null) {
      final init = initialCount ?? 500;
      final arrival = arrivalStr != null
          ? (DateTime.tryParse(arrivalStr) ?? DateTime.now())
          : DateTime.now();
      return Batch(
        id: prefs.getString('batch_id') ?? 'local-batch',
        farmerId: farmerId,
        arrivalDate: arrival,
        initialCount: init,
        currentCount: prefs.getInt('current_count') ?? init,
        status: 'active',
        createdAt: arrival,
      );
    }
    return null;
  }

  /// Get a batch by ID
  Future<Batch?> getBatch(String id) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.getBatch(id);
        if (data != null) return Batch.fromJson(data);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadLocalBatches(prefs);
    if (map.containsKey(id)) {
      return Batch.fromJson(map[id]!);
    }
    return getActiveBatch(prefs.getString('farmer_id') ?? 'local-farmer');
  }

  /// Get all batches (active and completed) for a farmer
  Future<List<Batch>> getBatchesForFarmer(String farmerId) async {
    if (_provider.isConfigured) {
      try {
        final list = await _provider.getBatchesForFarmer(farmerId);
        return list.map((item) => Batch.fromJson(item)).toList();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadLocalBatches(prefs);
    final batches = map.values
        .where((e) => e['farmer_id'] == farmerId)
        .map(Batch.fromJson)
        .toList();
    if (batches.isNotEmpty) return batches;
    final active = await getActiveBatch(farmerId);
    return active != null ? [active] : [];
  }

  /// Update the current head count for a batch
  Future<Batch> updateBatchCount(String batchId, int newCount) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.updateBatch(batchId, {
          'current_count': newCount,
        });
        final updated = Batch.fromJson(data);
        await _saveLocalBatch(updated);
        return updated;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_count', newCount);
    final existing = await getBatch(batchId) ??
        Batch(
          id: batchId,
          farmerId: prefs.getString('farmer_id') ?? 'local-farmer',
          arrivalDate: DateTime.now(),
          initialCount: prefs.getInt('initial_count') ?? newCount,
          currentCount: newCount,
          createdAt: DateTime.now(),
        );
    final updated = existing.copyWith(currentCount: newCount);
    await _saveLocalBatch(updated);
    return updated;
  }

  /// Mark a batch as completed
  Future<Batch> completeBatch(String batchId) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.updateBatch(batchId, {
          'status': 'completed',
        });
        final updated = Batch.fromJson(data);
        await _saveLocalBatch(updated);
        return updated;
      } catch (_) {}
    }
    final existing = await getBatch(batchId) ??
        Batch(
          id: batchId,
          farmerId: 'local-farmer',
          arrivalDate: DateTime.now(),
          initialCount: 500,
          status: 'completed',
          createdAt: DateTime.now(),
        );
    final updated = existing.copyWith(status: 'completed');
    await _saveLocalBatch(updated);
    return updated;
  }
}
