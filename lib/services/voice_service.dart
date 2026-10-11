import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'audio/web_audio_bridge.dart';

/// Records the farmer's voice and transcribes it via Web Speech API (on Chrome/web)
/// or the `transcribe-voice` Supabase Edge Function (on mobile/cloud).
///
/// Offline or unconfigured behavior is explicit: `startRecording` still works
/// (so the UI never lies), but `transcribe` throws a [VoiceUnavailable]
/// the caller converts into an honest "unavailable, please type" message.
/// The widget must NEVER fabricate a transcript.
class VoiceService {
  final AudioRecorder _recorder;
  final Future<SupabaseClient> Function()? _clientFactory;
  final WebSpeechRecognitionDelegate _webSpeech = WebSpeechRecognitionDelegate();
  String? _lastWebTranscript;
  String? _lastRecordingPath;

  VoiceService({AudioRecorder? recorder, this._clientFactory})
      : _recorder = recorder ?? AudioRecorder();

  /// True while the microphone is capturing.
  Future<bool> isRecording() async {
    if (kIsWeb && _webSpeech.isSupported && _webSpeech.isListening) {
      return true;
    }
    try {
      return await _recorder.isRecording();
    } catch (_) {
      return false;
    }
  }

  /// Requests mic permission and starts capturing.
  /// On Web, uses native Chrome/Edge/Safari SpeechRecognition with live partial results,
  /// falling back to audio recording only when Web Speech Recognition is unavailable.
  Future<String> startRecording({
    String language = 'uz',
    void Function(String partialText)? onPartialResult,
  }) async {
    _lastWebTranscript = null;
    _lastRecordingPath = null;

    if (kIsWeb && _webSpeech.isSupported) {
      final started = await _webSpeech.startListening(
        language: language,
        onResult: (text) {
          _lastWebTranscript = text;
          onPartialResult?.call(text);
        },
      );
      if (started) {
        return 'web_speech_only';
      }
    }

    final permitted = await _recorder.hasPermission();
    if (!permitted) {
      throw const VoiceUnavailable(
        'Microphone permission was not granted.',
        reason: VoiceUnavailableReason.permissionDenied,
      );
    }

    try {
      if (kIsWeb) {
        // On web, path_provider's getTemporaryDirectory throws MissingPluginException.
        // Record package on web supports recording without a file path.
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
        return 'web_audio';
      } else {
        final dir = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${dir.path}/agrozen_$stamp.m4a';
        _lastRecordingPath = path;

        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        return path;
      }
    } catch (e) {
      if (e is VoiceUnavailable) rethrow;
      debugPrint('VoiceService.startRecording error: $e');
      throw VoiceUnavailable(
        'Could not start recording: $e',
        reason: VoiceUnavailableReason.transcribeFailed,
      );
    }
  }

  /// Stops capturing and returns the file path, or null if there was no
  /// active recording.
  Future<String?> stopRecording() async {
    if (kIsWeb && _webSpeech.isSupported && _webSpeech.isListening) {
      final text = await _webSpeech.stopListening();
      if (text.isNotEmpty) {
        _lastWebTranscript = text;
      }
      return 'web_speech_only';
    }

    try {
      final path = await _recorder.stop();
      return path ?? _lastRecordingPath ?? (kIsWeb ? 'web_audio' : null);
    } catch (e) {
      debugPrint('VoiceService.stopRecording: $e');
      return _lastRecordingPath ?? (kIsWeb ? 'web_audio' : null);
    }
  }

  /// Convenience helper: stops active recording and transcribes it in one step.
  Future<String> stopAndTranscribe({required String language}) async {
    final path = await stopRecording();
    if (path == null) {
      throw const VoiceUnavailable(
        'Recording file is missing.',
        reason: VoiceUnavailableReason.noAudio,
      );
    }
    return transcribe(path, language: language);
  }

  /// Discards the current recording and deletes any temporary audio file.
  Future<void> cancelRecording() async {
    if (kIsWeb && _webSpeech.isSupported) {
      await _webSpeech.cancelListening();
    }
    _lastWebTranscript = null;
    final tempPath = _lastRecordingPath;
    _lastRecordingPath = null;
    try {
      await _recorder.cancel();
    } catch (e) {
      debugPrint('VoiceService.cancelRecording: $e');
    }
    if (!kIsWeb && tempPath != null && tempPath.isNotEmpty) {
      try {
        final f = File(tempPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
  }

  static const Set<String> _serverFallbackPhrases = {
    'не удалось распознать речь',
    'не удалось распознать речь.',
    "ovozli xabardagi nutqni aniqlab bo'lmadi",
    "ovozli xabardagi nutqni aniqlab bo'lmadi.",
    'could not recognize speech',
    'could not recognize speech.',
    'could not recognize the speech',
    'could not recognize the speech.',
  };

  /// Sends [audioPath] to the `transcribe-voice` Edge Function, direct Gemini audio API,
  /// or returns native browser SpeechRecognition transcript (on Web).
  Future<String> transcribe(String audioPath, {required String language}) async {
    final norm = language.trim().toLowerCase();
    final lang = norm.startsWith('ru')
        ? 'ru'
        : (norm.startsWith('en') ? 'en' : 'uz');

    try {
      // 1. If Web Speech Recognition captured speech during recording on Chrome/Edge/Safari:
      if (kIsWeb &&
          _lastWebTranscript != null &&
          _lastWebTranscript!.trim().isNotEmpty) {
        final transcript = _lastWebTranscript!.trim();
        _lastWebTranscript = null;
        return transcript;
      }

      if (audioPath == 'web_speech_only') {
        throw const VoiceUnavailable(
          'Could not recognize the speech.',
          reason: VoiceUnavailableReason.transcribeFailed,
        );
      }

      // 2. Otherwise require configured cloud backend or Gemini key:
      if (!SupabaseConfig.isConfigured &&
          !SupabaseConfig.hasGeminiKey &&
          _clientFactory == null) {
        throw const VoiceUnavailable(
          'Voice transcription needs the cloud backend, which is not configured.',
          reason: VoiceUnavailableReason.notConfigured,
        );
      }

      List<int> bytes;
      String mimeType = 'audio/m4a';

      if (kIsWeb) {
        try {
          if (audioPath.startsWith('blob:') || audioPath.startsWith('http')) {
            final res = await http.get(Uri.parse(audioPath));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              bytes = res.bodyBytes;
              mimeType = 'audio/webm';
            } else {
              throw const VoiceUnavailable(
                'Recording file is missing.',
                reason: VoiceUnavailableReason.noAudio,
              );
            }
          } else {
            throw const VoiceUnavailable(
              'Recording file is missing.',
              reason: VoiceUnavailableReason.noAudio,
            );
          }
        } catch (e) {
          if (e is VoiceUnavailable) rethrow;
          throw const VoiceUnavailable(
            'Recording file is missing.',
            reason: VoiceUnavailableReason.noAudio,
          );
        }
      } else {
        final file = File(audioPath);
        if (!await file.exists()) {
          throw const VoiceUnavailable(
            'Recording file is missing.',
            reason: VoiceUnavailableReason.noAudio,
          );
        }
        bytes = await file.readAsBytes();
      }

      final audioBase64 = base64Encode(bytes);

      if (SupabaseConfig.isConfigured || _clientFactory != null) {
        try {
          final factory = _clientFactory;
          final client =
              factory != null ? await factory() : SupabaseConfig.client;

          final response = await client.functions.invoke(
            'transcribe-voice',
            body: {
              'audio_base64': audioBase64,
              'mime_type': mimeType,
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
          if (response.status == 200 &&
              text.isNotEmpty &&
              !_serverFallbackPhrases.contains(text.toLowerCase())) {
            return text;
          }
          if (!SupabaseConfig.hasGeminiKey) {
            final serverError = payload?['error']?.toString();
            throw VoiceUnavailable(
              serverError ?? 'Could not recognize the speech.',
              reason: VoiceUnavailableReason.transcribeFailed,
            );
          }
        } catch (edgeErr) {
          if (!SupabaseConfig.hasGeminiKey) {
            rethrow;
          }
          debugPrint(
            'transcribe-voice edge function failed, falling back to direct Gemini: $edgeErr',
          );
        }
      }

      if (SupabaseConfig.hasGeminiKey) {
        final directText = await _transcribeDirectGemini(
          audioBase64: audioBase64,
          mimeType: mimeType,
          lang: lang,
        );
        if (directText.isNotEmpty &&
            !_serverFallbackPhrases.contains(directText.toLowerCase())) {
          return directText;
        }
      }

      throw const VoiceUnavailable(
        'Could not recognize the speech.',
        reason: VoiceUnavailableReason.transcribeFailed,
      );
    } catch (e) {
      if (e is VoiceUnavailable) rethrow;
      throw VoiceUnavailable(
        'Transcription failed: $e',
        reason: VoiceUnavailableReason.transcribeFailed,
      );
    } finally {
      _lastRecordingPath = null;
      if (!kIsWeb &&
          audioPath.isNotEmpty &&
          audioPath != 'web_audio' &&
          audioPath != 'web_speech_only') {
        try {
          final file = File(audioPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
  }

  Future<String> _transcribeDirectGemini({
    required String audioBase64,
    required String mimeType,
    required String lang,
  }) async {
    final apiKey = SupabaseConfig.geminiApiKey;
    if (apiKey.isEmpty) return '';

    final prompt = lang == 'ru'
        ? 'Точно транскрибируй эту аудиозапись на русском языке. Верни только распознанный текст без комментариев.'
        : (lang == 'en'
            ? 'Accurately transcribe this audio recording. Return only the recognized speech text without commentary.'
            : "Ushbu ovozli yozuvni o'zbek tilida (lotin alifbosida) aniq matnga aylantirib ber. Faqat aniqlangan nutq matnini qaytar, izoh yozma.");

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    );
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': audioBase64,
                    },
                  },
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 256,
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final text =
          decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text is String) {
        return text.trim();
      }
    }
    return '';
  }

  Future<void> dispose() async {
    if (kIsWeb && _webSpeech.isSupported) {
      await _webSpeech.cancelListening();
    }
    await _recorder.dispose();
  }
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
