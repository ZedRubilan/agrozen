import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  VoidCallback? _currentCompletionCallback;

  bool get isPlaying => kIsWeb ? (_webTts.isSpeaking || _isPlaying) : _isPlaying;

  Future<void> _initTts() async {
    if (_isInitialized) return;
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

  /// Speak text aloud in the designated language ('uz', 'ru', 'en').
  /// Automatically cleans markdown, scientific notations, and punctuation
  /// for natural, pleasing human voice delivery.
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

      // On Web (Chrome/Edge/Safari), use the native Web Speech API delegate
      // to avoid flutter_tts_web's utterance freeze, rate mismatch, and cancelled speech bugs.
      if (kIsWeb && _webTts.isSupported) {
        _isPlaying = true;
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
        final isAvailable = await _flutterTts?.isLanguageAvailable('uz-UZ') ?? false;
        ttsLang = isAvailable ? 'uz-UZ' : 'tr-TR';
      }

      await _flutterTts?.setLanguage(ttsLang);
      _isPlaying = true;
      final result = await _flutterTts?.speak(cleaned);
      if (result == 0) {
        // Did not start speaking (e.g. desktop/test environment)
        _isPlaying = false;
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
