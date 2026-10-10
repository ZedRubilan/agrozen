import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

/// Central Supabase data provider that performs direct database and function calls.
class SupabaseProvider {
  final SupabaseClient? _injectedClient;

  SupabaseProvider({SupabaseClient? client}) : _injectedClient = client;

  bool get isConfigured => _injectedClient != null || SupabaseConfig.isConfigured;

  SupabaseClient get _db => _injectedClient ?? SupabaseConfig.client;

  SupabaseClient get client => _db;

  // ---------------------------------------------------------------------------
  // Table: farmers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createFarmer(Map<String, dynamic> data) async {
    final response = await _db
        .from('farmers')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>?> getFarmer(String id) async {
    final response = await _db
        .from('farmers')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getFarmerByPhone(String phone) async {
    final response = await _db
        .from('farmers')
        .select()
        .eq('phone', phone)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>> updateFarmer(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _db
        .from('farmers')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  Future<void> deleteFarmer(String id) async {
    await _db.from('farmers').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Table: batches
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createBatch(Map<String, dynamic> data) async {
    final response = await _db
        .from('batches')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>?> getBatch(String id) async {
    final response = await _db
        .from('batches')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getActiveBatch(String farmerId) async {
    final response = await _db
        .from('batches')
        .select()
        .eq('farmer_id', farmerId)
        .eq('status', 'active')
        .order('arrival_date', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getBatchesForFarmer(
    String farmerId,
  ) async {
    final response = await _db
        .from('batches')
        .select()
        .eq('farmer_id', farmerId)
        .order('arrival_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> updateBatch(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _db
        .from('batches')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  Future<void> deleteBatch(String id) async {
    await _db.from('batches').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Table: diary_entries
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createDiaryEntry(
    Map<String, dynamic> data,
  ) async {
    final response = await _db
        .from('diary_entries')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getDiaryEntriesForBatch(
    String batchId,
  ) async {
    final response = await _db
        .from('diary_entries')
        .select()
        .eq('batch_id', batchId)
        .order('entry_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDiaryEntriesForDate(
    String batchId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T').first;

    final response = await _db
        .from('diary_entries')
        .select()
        .eq('batch_id', batchId)
        .eq('entry_date', dateStr)
        .order('entry_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDiaryEntriesByType(
    String batchId,
    String entryType,
  ) async {
    final response = await _db
        .from('diary_entries')
        .select()
        .eq('batch_id', batchId)
        .eq('entry_type', entryType)
        .order('entry_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteDiaryEntry(String id) async {
    await _db.from('diary_entries').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Table: question_logs
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createQuestionLog(
    Map<String, dynamic> data,
  ) async {
    final response = await _db
        .from('question_logs')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getQuestionLogsForFarmer(
    String farmerId, {
    int limit = 50,
  }) async {
    final response = await _db
        .from('question_logs')
        .select()
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // Table: course_progress
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> upsertCourseProgress(
    Map<String, dynamic> data,
  ) async {
    final response = await _db
        .from('course_progress')
        .upsert(data, onConflict: 'farmer_id,lesson_number')
        .select()
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getCourseProgressForFarmer(
    String farmerId,
  ) async {
    final response = await _db
        .from('course_progress')
        .select()
        .eq('farmer_id', farmerId)
        .order('lesson_number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getCourseProgressForLesson(
    String farmerId,
    int lessonNumber,
  ) async {
    final response = await _db
        .from('course_progress')
        .select()
        .eq('farmer_id', farmerId)
        .eq('lesson_number', lessonNumber)
        .maybeSingle();
    return response;
  }

  // ---------------------------------------------------------------------------
  // Edge Functions
  // ---------------------------------------------------------------------------

  Future<FunctionResponse> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    return await _db.functions.invoke(
      functionName,
      body: body,
    );
  }
}
