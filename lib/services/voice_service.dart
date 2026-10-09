import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Records the farmer's voice and transcribes it via the
/// `transcribe-voice` Supabase Edge Function.
///
/// Offline or unconfigured behavior is explicit: `startRecording` still works
/// (so the UI never lies), but `transcribe` throws a [VoiceUnavailable]
/// the caller converts into an honest "unavailable, please type" message.
/// The widget must NEVER fabricate a transcript.
class VoiceService {
  final AudioRecorder _recorder;
  final Future<SupabaseClient> Function()? _clientFactory;

  VoiceService({AudioRecorder? recorder, this._clientFactory})
      : _recorder = recorder ?? AudioRecorder();

  /// True while the microphone is capturing.
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (_) {
      return false;
    }
  }

  /// Requests mic permission and starts capturing to a temp `.m4a` file.
  /// Returns the file path, or throws [VoiceUnavailable] when recording
  /// cannot start.
  Future<String> startRecording() async {
    final permitted = await _recorder.hasPermission();
    if (!permitted) {
      throw VoiceUnavailable(
        'Microphone permission was not granted.',
        reason: VoiceUnavailableReason.permissionDenied,
      );
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/agrozen_$stamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    return path;
  }

  /// Stops capturing and returns the file path, or null if there was no
  /// active recording.
  Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } catch (e) {
      debugPrint('VoiceService.stopRecording: $e');
      return null;
    }
  }

  /// Discards the current recording.
  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
    } catch (e) {
      debugPrint('VoiceService.cancelRecording: $e');
    }
  }

  /// Sends [audioPath] to the `transcribe-voice` Edge Function and returns
  /// the transcript. Throws [VoiceUnavailable] when there is no network,
  /// no backend, or the provider returned nothing.
  Future<String> transcribe(String audioPath, {required String language}) async {
    final lang = language.toLowerCase() == 'ru' ? 'ru' : 'uz';

    if (!SupabaseConfig.isConfigured && _clientFactory == null) {
      throw const VoiceUnavailable(
        'Voice transcription needs the cloud backend, which is not configured.',
        reason: VoiceUnavailableReason.notConfigured,
      );
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      throw const VoiceUnavailable(
        'Recording file is missing.',
        reason: VoiceUnavailableReason.noAudio,
      );
    }

    final factory = _clientFactory;
    final client =
        factory != null ? await factory() : SupabaseConfig.client;

    try {
      final bytes = await file.readAsBytes();
      final response = await client.functions.invoke(
        'transcribe-voice',
        body: {
          'audio_base64': base64Encode(bytes),
          'mime_type': 'audio/m4a',
          'language': lang,
        },
      );

      final data = response.data;
      final Map<String, dynamic>? payload = data is Map
          ? Map<String, dynamic>.from(data)
          : (data is String
              ? Map<String, dynamic>.from(jsonDecode(data) as Map)
              : null);

      final text = (payload?['transcribed_text'] as String?)?.trim() ?? '';
      if (response.status != 200 || text.isEmpty) {
        final serverError = payload?['error']?.toString();
        throw VoiceUnavailable(
          serverError ?? 'Could not recognize the speech.',
          reason: VoiceUnavailableReason.transcribeFailed,
        );
      }
      return text;
    } catch (e) {
      if (e is VoiceUnavailable) rethrow;
      throw VoiceUnavailable(
        'Transcription failed: $e',
        reason: VoiceUnavailableReason.transcribeFailed,
      );
    }
  }

  Future<void> dispose() => _recorder.dispose();
}

enum VoiceUnavailableReason {
  permissionDenied,
  notConfigured,
  noAudio,
  transcribeFailed,
}

/// Thrown when a voice step cannot honestly complete. Callers must surface a
/// "please type instead" message — never a fabricated transcript.
class VoiceUnavailable implements Exception {
  final String message;
  final VoiceUnavailableReason reason;

  const VoiceUnavailable(this.message, {required this.reason});

  @override
  String toString() => 'VoiceUnavailable($reason): $message';
}

