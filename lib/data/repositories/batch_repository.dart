import '../models/batch.dart';
import '../providers/supabase_provider.dart';

class BatchRepository {
  final SupabaseProvider _provider;

  BatchRepository({SupabaseProvider? provider})
      : _provider = provider ?? SupabaseProvider();

  /// Create a new poultry batch
  Future<Batch> createBatch(Batch batch) async {
    try {
      final data = await _provider.createBatch(batch.toJson());
      return Batch.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create batch: $e');
    }
  }

  /// Get the currently active batch for a given farmer
  Future<Batch?> getActiveBatch(String farmerId) async {
    try {
      final data = await _provider.getActiveBatch(farmerId);
      if (data == null) return null;
      return Batch.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get active batch: $e');
    }
  }

  /// Get a batch by ID
  Future<Batch?> getBatch(String id) async {
    try {
      final data = await _provider.getBatch(id);
      if (data == null) return null;
      return Batch.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get batch with ID $id: $e');
    }
  }

  /// Get all batches (active and completed) for a farmer
  Future<List<Batch>> getBatchesForFarmer(String farmerId) async {
    try {
      final list = await _provider.getBatchesForFarmer(farmerId);
      return list.map((item) => Batch.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get batches for farmer: $e');
    }
  }

  /// Update the current head count for a batch
  Future<Batch> updateBatchCount(String batchId, int newCount) async {
    try {
      final data = await _provider.updateBatch(batchId, {
        'current_count': newCount,
      });
      return Batch.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update batch count: $e');
    }
  }

  /// Mark a batch as completed
  Future<Batch> completeBatch(String batchId) async {
    try {
      final data = await _provider.updateBatch(batchId, {
        'status': 'completed',
      });
      return Batch.fromJson(data);
    } catch (e) {
      throw Exception('Failed to complete batch: $e');
    }
  }
}
