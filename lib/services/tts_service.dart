import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;
  VoidCallback? _currentCompletionCallback;

  bool get isPlaying => _isPlaying;

  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();
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
  Future<void> speak({
    required String text,
    required String lang,
    VoidCallback? onComplete,
  }) async {
    try {
      await _initTts();
      if (_flutterTts == null) {
        onComplete?.call();
        return;
      }

      await stop();
      _currentCompletionCallback = onComplete;

      String ttsLang = 'en-US';
      if (lang.toLowerCase() == 'ru') {
        ttsLang = 'ru-RU';
      } else if (lang.toLowerCase() == 'uz') {
        // Some Android TTS engines support 'uz-UZ', others fall back to 'tr-TR' or 'ru-RU'
        final isAvailable = await _flutterTts?.isLanguageAvailable('uz-UZ') ?? false;
        ttsLang = isAvailable ? 'uz-UZ' : 'tr-TR';
      }

      await _flutterTts?.setLanguage(ttsLang);
      _isPlaying = true;
      final result = await _flutterTts?.speak(text);
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
