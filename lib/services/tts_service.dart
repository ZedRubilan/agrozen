import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import 'audio/text_to_speech_sanitizer.dart';
import 'audio/web_audio_bridge.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  final WebTtsDelegate _webTts = WebTtsDelegate();
  bool _isInitialized = false;
  bool _isPlaying = false;
  String _activeVoiceEngine = 'Default TTS';
  VoidCallback? _currentCompletionCallback;

  bool get isPlaying => kIsWeb ? (_webTts.isSpeaking || _isPlaying) : _isPlaying;

  /// Human-readable label of the active or most recently selected TTS voice tier
  /// ('Microsoft Natural', 'Gemini Voice', or 'Default TTS').
  String get activeVoiceEngine {
    if (kIsWeb) {
      final webName = _webTts.activeVoiceName ?? '';
      if (webName.toLowerCase().contains('gemini')) return 'Gemini Voice';
      if (webName.toLowerCase().contains('microsoft') &&
          (webName.toLowerCase().contains('natural') ||
              webName.toLowerCase().contains('online') ||
              webName.toLowerCase().contains('neural'))) {
        return 'Microsoft Natural';
      }
    }
    return _activeVoiceEngine;
  }

  Future<void> _initTts() async {
    if (_isInitialized) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      // flutter_tts does not provide a native Linux plugin implementation
      _isInitialized = true;
      return;
    }
    try {
      _flutterTts = FlutterTts();
      // On mobile (Android/iOS), 0.5 corresponds to standard 1.0x conversational speed.
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);

      _flutterTts?.setCompletionHandler(() {
        _isPlaying = false;
        _currentCompletionCallback?.call();
        _currentCompletionCallback = null;
      });

      _flutterTts?.setCancelHandler(() {
        _isPlaying = false;
        _currentCompletionCallback = null;
      });

      _flutterTts?.setErrorHandler((msg) {
        debugPrint('TtsService error: $msg');
        _isPlaying = false;
        _currentCompletionCallback?.call();
        _currentCompletionCallback = null;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize FlutterTts: $e');
    }
  }

  /// Selects the best voice map `{'name': ..., 'locale': ...}` from a list of
  /// platform voices returned by `FlutterTts.getVoices`.
  /// Priority when [forceDefault] is false:
  /// 1. Microsoft Natural / Online Neural voices
  /// 2. Gemini / Google Neural / WaveNet / Network voices
  /// 3. Standard local/default voice for the language
  @visibleForTesting
  static Map<String, String>? selectBestNativeVoice(
    List<dynamic> rawVoices,
    String lang, {
    bool forceDefault = false,
  }) {
    final normalizedLang = lang.trim().toLowerCase();
    final prefixes = normalizedLang == 'ru'
        ? ['ru']
        : (normalizedLang == 'uz' ? ['uz', 'tr', 'ru'] : ['en']);

    final parsed = <Map<String, String>>[];
    for (final item in rawVoices) {
      if (item is Map) {
        final name = (item['name'] ?? '').toString();
        final locale = (item['locale'] ?? item['lang'] ?? '').toString();
        if (name.isNotEmpty && locale.isNotEmpty) {
          parsed.add({'name': name, 'locale': locale});
        }
      }
    }

    if (!forceDefault) {
      // Tier 1: Microsoft Natural / Neural voice
      for (final prefix in prefixes) {
        for (final v in parsed) {
          final nameLower = v['name']!.toLowerCase();
          final localeLower = v['locale']!.toLowerCase();
          if (localeLower.startsWith(prefix) &&
              nameLower.contains('microsoft') &&
              (nameLower.contains('natural') ||
                  nameLower.contains('online') ||
                  nameLower.contains('neural'))) {
            return v;
          }
        }
      }

      // Tier 2: Gemini / Google Neural / WaveNet / Network natural voice
      for (final prefix in prefixes) {
        for (final v in parsed) {
          final nameLower = v['name']!.toLowerCase();
          final localeLower = v['locale']!.toLowerCase();
          if (localeLower.startsWith(prefix) &&
              (nameLower.contains('gemini') ||
                  nameLower.contains('natural') ||
                  nameLower.contains('neural') ||
                  nameLower.contains('wavenet') ||
                  nameLower.contains('network'))) {
            return v;
          }
        }
      }
    }

    // Tier 3: Default / local voice for the language
    for (final prefix in prefixes) {
      for (final v in parsed) {
        final nameLower = v['name']!.toLowerCase();
        final localeLower = v['locale']!.toLowerCase();
        if (localeLower.startsWith(prefix) &&
            !nameLower.contains('network') &&
            !nameLower.contains('online')) {
          return v;
        }
      }
      for (final v in parsed) {
        if (v['locale']!.toLowerCase().startsWith(prefix)) {
          return v;
        }
      }
    }

    return null;
  }

  /// Wraps raw 16-bit little-endian mono PCM audio bytes (as returned by Gemini TTS
  /// `audio/L16;codec=pcm;rate=24000`) in a standard 44-byte RIFF WAV header so any
  /// HTML5 `<audio>` or standard player can play it.
  @visibleForTesting
  static Uint8List wrapPcm16LeToWav(
    Uint8List pcmBytes, {
    int sampleRate = 24000,
    int channels = 1,
  }) {
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;
    final dataSize = pcmBytes.length;
    final totalSize = 44 + dataSize;

    final header = ByteData(44);
    // "RIFF"
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, totalSize - 8, Endian.little);
    // "WAVE"
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // "fmt "
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little); // PCM chunk size
    header.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little); // BitsPerSample = 16
    // "data"
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(totalSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, totalSize, pcmBytes);
    return wav;
  }

  /// Synthesizes speech using Gemini's native TTS model (`gemini-2.5-flash-preview-tts`)
  /// when a Gemini API key is configured. Returns `(base64Audio, mimeType)` on success,
  /// or `null` if unavailable/failed so the caller can fall back to standard TTS.
  Future<(String, String)?> _synthesizeGeminiAudio({
    required String text,
    required String lang,
  }) async {
    final apiKey = SupabaseConfig.geminiApiKey;
    if (apiKey.isEmpty) return null;

    // Limit length for fast low-latency TTS generation
    final trimmed =
        text.length > 650 ? '${text.substring(0, 650)}...' : text;
    final voiceName = lang.toLowerCase() == 'ru'
        ? 'Aoede'
        : (lang.toLowerCase() == 'uz' ? 'Kore' : 'Puck');

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent',
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
                  'parts': [
                    {'text': trimmed},
                  ],
                },
              ],
              'generationConfig': {
                'responseModalities': ['AUDIO'],
                'speechConfig': {
                  'voiceConfig': {
                    'prebuiltVoiceConfig': {'voiceName': voiceName},
                  },
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final parts = decoded['candidates']?[0]?['content']?['parts'];
      if (parts is List && parts.isNotEmpty) {
        final inlineData = parts[0]['inlineData'] ?? parts[0]['inline_data'];
        if (inlineData is Map) {
          final b64 = (inlineData['data'] ?? '').toString();
          final mime = (inlineData['mimeType'] ?? inlineData['mime_type'] ?? '')
              .toString();
          if (b64.isNotEmpty) {
            if (mime.toLowerCase().contains('l16') ||
                mime.toLowerCase().contains('pcm')) {
              final rawBytes = base64Decode(b64);
              final wavBytes = wrapPcm16LeToWav(rawBytes);
              return (base64Encode(wavBytes), 'audio/wav');
            }
            return (b64, mime.isEmpty ? 'audio/wav' : mime);
          }
        }
      }
    } catch (e) {
      debugPrint('Gemini TTS synthesis fallback trigger: $e');
    }
    return null;
  }

  /// Speak text aloud in the designated language ('uz', 'ru', 'en').
  /// Priority order:
  /// 1. Microsoft Natural Voice (Web / System neural voice) or Gemini Voice
  /// 2. Automatic fallback to default system Text-to-Speech if primary fails
  Future<void> speak({
    required String text,
    required String lang,
    VoidCallback? onComplete,
  }) async {
    final cleaned = TextToSpeechSanitizer.clean(
      text: text,
      language: lang,
    );

    if (cleaned.isEmpty) {
      onComplete?.call();
      return;
    }

    try {
      await stop();

      // Web path:
      // 1. If Microsoft Natural Voice is available in the browser, use it immediately.
      // 2. Otherwise, if Gemini API key is configured, try Gemini TTS neural voice first.
      // 3. Fall back to Web Speech API (with automatic retry on default system voice if an online voice fails).
      if (kIsWeb && _webTts.isSupported) {
        _isPlaying = true;
        final hasMsNatural = _webTts.hasMicrosoftNaturalVoice(lang);
        if (!hasMsNatural && SupabaseConfig.hasGeminiKey) {
          final geminiAudio = await _synthesizeGeminiAudio(
            text: cleaned,
            lang: lang,
          );
          if (geminiAudio != null && _isPlaying) {
            _activeVoiceEngine = 'Gemini Voice';
            final played = await _webTts.playAudioBase64(
              base64Data: geminiAudio.$1,
              mimeType: geminiAudio.$2,
              onComplete: () {
                _isPlaying = false;
                onComplete?.call();
              },
            );
            if (played) return;
          }
        }

        _activeVoiceEngine =
            hasMsNatural ? 'Microsoft Natural' : 'Default TTS';
        await _webTts.speak(
          text: cleaned,
          language: lang,
          onComplete: () {
            _isPlaying = false;
            onComplete?.call();
          },
        );
        return;
      }

      // Mobile / Desktop path via FlutterTts:
      await _initTts();
      if (_flutterTts == null) {
        onComplete?.call();
        return;
      }

      _currentCompletionCallback = onComplete;

      String ttsLang = 'en-US';
      if (lang.toLowerCase() == 'ru') {
        ttsLang = 'ru-RU';
      } else if (lang.toLowerCase() == 'uz') {
        final isAvailable =
            await _flutterTts?.isLanguageAvailable('uz-UZ') ?? false;
        ttsLang = isAvailable ? 'uz-UZ' : 'tr-TR';
      }

      // 1. Try selecting a Microsoft Natural or Gemini/Google Neural voice first
      bool spokeWithNaturalVoice = false;
      try {
        final rawVoices = await _flutterTts?.getVoices;
        if (rawVoices is List && rawVoices.isNotEmpty) {
          final bestVoice = selectBestNativeVoice(rawVoices, lang);
          if (bestVoice != null) {
            final vName = bestVoice['name']!.toLowerCase();
            _activeVoiceEngine = vName.contains('microsoft')
                ? 'Microsoft Natural'
                : (vName.contains('gemini') ||
                        vName.contains('neural') ||
                        vName.contains('natural')
                    ? 'Gemini Voice'
                    : 'Default TTS');
            await _flutterTts?.setLanguage(bestVoice['locale'] ?? ttsLang);
            await _flutterTts?.setVoice(bestVoice);
            _isPlaying = true;
            final res = await _flutterTts?.speak(cleaned);
            if (res != null && res != 0) {
              spokeWithNaturalVoice = true;
            }
          }
        }
      } catch (naturalErr) {
        debugPrint(
          'Primary natural voice failed, falling back to default TTS: $naturalErr',
        );
      }

      if (spokeWithNaturalVoice) return;

      // 2. Automatic fallback to default system Text-to-Speech
      _activeVoiceEngine = 'Default TTS';
      await _flutterTts?.setLanguage(ttsLang);
      _isPlaying = true;
      final result = await _flutterTts?.speak(cleaned);
      if (result != 1) {
        // Did not start speaking (e.g. headless desktop/test environment where channel returns null or 0)
        _isPlaying = false;
        _currentCompletionCallback = null;
        onComplete?.call();
      }
    } catch (e) {
      debugPrint('TtsService speak failed: $e');
      _isPlaying = false;
      onComplete?.call();
    }
  }

  /// Stop active playback.
  Future<void> stop() async {
    try {
      if (kIsWeb && _webTts.isSupported) {
        await _webTts.stop();
      }
      if (_flutterTts != null && _isPlaying) {
        await _flutterTts?.stop();
      }
      _isPlaying = false;
      _currentCompletionCallback = null;
    } catch (e) {
      debugPrint('TtsService stop error: $e');
    }
  }
}

