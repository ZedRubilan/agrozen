import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// High-performance Web implementation of Text-to-Speech using native Web Speech API.
/// Resolves Chrome issues: utterance reuse bug, 0.5 half-speed sluggishness,
/// 15-second utterance timeout cutoff, and missing initial voices.
class WebTtsDelegate {
  Timer? _keepAliveTimer;
  bool _isSpeaking = false;
  int _sessionId = 0;
  VoidCallback? _onCompleteCallback;
  List<String> _pendingChunks = [];
  int _currentChunkIndex = 0;
  String _currentLanguage = 'uz';

  bool get isSupported {
    try {
      return (web.window as JSObject).has('speechSynthesis');
    } catch (_) {
      return false;
    }
  }

  bool get isSpeaking => _isSpeaking;

  /// Speaks text cleanly on Web, chunking long text into natural sentences
  /// to avoid Chrome's 15-second speech synthesis silent cutoff bug.
  Future<void> speak({
    required String text,
    required String language,
    VoidCallback? onComplete,
  }) async {
    if (!isSupported || text.trim().isEmpty) {
      onComplete?.call();
      return;
    }

    await stop();

    _sessionId++;
    _isSpeaking = true;
    _onCompleteCallback = onComplete;
    _currentLanguage = language;
    _pendingChunks = _splitIntoNaturalChunks(text);
    _currentChunkIndex = 0;

    _startKeepAlive();
    _playNextChunk(_sessionId);
  }

  /// Cancels any active web utterance and cleans timers.
  Future<void> stop() async {
    _sessionId++;
    _stopKeepAlive();
    _isSpeaking = false;
    _pendingChunks = [];
    _currentChunkIndex = 0;
    _onCompleteCallback = null;

    try {
      if (isSupported) {
        web.window.speechSynthesis.cancel();
      }
    } catch (e) {
      debugPrint('WebTtsDelegate stop error: $e');
    }
  }

  void _playNextChunk(int session) {
    if (!_isSpeaking || session != _sessionId) return;

    if (_currentChunkIndex >= _pendingChunks.length) {
      _finishPlayback();
      return;
    }

    final chunk = _pendingChunks[_currentChunkIndex];
    if (chunk.trim().isEmpty) {
      _currentChunkIndex++;
      _playNextChunk(session);
      return;
    }

    try {
      final synth = web.window.speechSynthesis;
      // Chrome unpause heartbeat
      synth.resume();

      final utterance = web.SpeechSynthesisUtterance(chunk);
      // On Web Speech API, 1.0 is standard normal speech rate (0.5 is dragging half-speed)
      utterance.rate = 1.05;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;

      final (targetVoice, targetLang) = _selectBestVoice(_currentLanguage);
      if (targetVoice != null) {
        utterance.voice = targetVoice;
      }
      utterance.lang = targetLang;

      utterance.onend = ((web.Event _) {
        if (!_isSpeaking || session != _sessionId) return;
        _currentChunkIndex++;
        _playNextChunk(session);
      }).toJS;

      utterance.onerror = ((web.SpeechSynthesisErrorEvent err) {
        if (!_isSpeaking || session != _sessionId) return;
        if (err.error == 'canceled' || err.error == 'interrupted') return;
        debugPrint('WebSpeechUtterance error: ${err.error}');
        _currentChunkIndex++;
        _playNextChunk(session);
      }).toJS;

      synth.speak(utterance);
    } catch (e) {
      debugPrint('WebTtsDelegate _playNextChunk error: $e');
      if (!_isSpeaking || session != _sessionId) return;
      _currentChunkIndex++;
      _playNextChunk(session);
    }
  }

  void _finishPlayback() {
    _stopKeepAlive();
    _isSpeaking = false;
    final cb = _onCompleteCallback;
    _onCompleteCallback = null;
    cb?.call();
  }

  /// Selects the best sounding voice available in the browser.
  (web.SpeechSynthesisVoice?, String) _selectBestVoice(String language) {
    final synth = web.window.speechSynthesis;
    final voices = synth.getVoices().toDart;
    final lang = language.toLowerCase();

    if (lang == 'ru') {
      // Prioritize natural Russian voices
      for (final v in voices) {
        final vLang = v.lang.toLowerCase();
        if (vLang.startsWith('ru')) return (v, 'ru-RU');
      }
      return (null, 'ru-RU');
    } else if (lang == 'uz') {
      // 1. Look for native Uzbek voice
      for (final v in voices) {
        final vLang = v.lang.toLowerCase();
        if (vLang.startsWith('uz')) return (v, 'uz-UZ');
      }
      // 2. Turkish voice phonetically reads Latin Uzbek with exceptional accuracy
      for (final v in voices) {
        final vLang = v.lang.toLowerCase();
        if (vLang.startsWith('tr')) return (v, 'tr-TR');
      }
      // 3. Clear Russian/multilingual voice as secondary fallback
      for (final v in voices) {
        final vLang = v.lang.toLowerCase();
        if (vLang.startsWith('ru')) return (v, 'ru-RU');
      }
      return (null, 'uz-UZ');
    } else {
      for (final v in voices) {
        final vLang = v.lang.toLowerCase();
        if (vLang.startsWith('en')) return (v, 'en-US');
      }
      return (null, 'en-US');
    }
  }

  /// Splits long text into pleasant spoken phrases (100-200 chars) around punctuation.
  List<String> _splitIntoNaturalChunks(String text) {
    final sentences = text.split(RegExp(r'(?<=[.?!])\s+'));
    final chunks = <String>[];
    var current = StringBuffer();

    for (final s in sentences) {
      if (current.length + s.length > 180 && current.isNotEmpty) {
        chunks.add(current.toString().trim());
        current = StringBuffer();
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(s);
    }

    if (current.isNotEmpty) {
      chunks.add(current.toString().trim());
    }

    return chunks.where((c) => c.isNotEmpty).toList();
  }

  /// Workaround for notorious Chromium issue where SpeechSynthesis pauses after 14s.
  /// Note: we already chunk utterances under 180 chars (~10s), so only `resume()` is
  /// needed; calling `pause()` before `resume()` causes audible word clipping.
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isSpeaking && isSupported) {
        web.window.speechSynthesis.resume();
      }
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }
}

/// Native browser Speech Recognition for Chrome, Edge, and Safari on Web.
/// Gives instant, real-time voice-to-text without requiring cloud keys during testing.
class WebSpeechRecognitionDelegate {
  web.SpeechRecognition? _recognizer;
  bool _isListening = false;
  String _accumulatedTranscript = '';
  Completer<void>? _endCompleter;

  bool get isSupported {
    try {
      final win = web.window as JSObject;
      return win.has('SpeechRecognition') || win.has('webkitSpeechRecognition');
    } catch (_) {
      return false;
    }
  }

  bool get isListening => _isListening;

  web.SpeechRecognition? _getOrCreateRecognizer() {
    if (!isSupported) return null;
    try {
      final win = web.window as JSObject;
      if (!win.has('SpeechRecognition') && win.has('webkitSpeechRecognition')) {
        win['SpeechRecognition'] = win['webkitSpeechRecognition'];
      }
      return web.SpeechRecognition();
    } catch (e) {
      debugPrint('Failed to instantiate WebSpeechRecognition: $e');
      return null;
    }
  }

  Future<bool> startListening({
    required String language,
    void Function(String partialText)? onResult,
    void Function(String error)? onError,
  }) async {
    if (!isSupported) return false;

    await cancelListening();

    _recognizer = _getOrCreateRecognizer();
    if (_recognizer == null) return false;

    _accumulatedTranscript = '';
    _isListening = true;
    _endCompleter = Completer<void>();

    final lang = language.toLowerCase();
    _recognizer!.lang = lang == 'ru'
        ? 'ru-RU'
        : (lang == 'uz' ? 'uz-UZ' : 'en-US');
    _recognizer!.continuous = true;
    _recognizer!.interimResults = true;

    _recognizer!.onresult = ((web.SpeechRecognitionEvent event) {
      final results = event.results;
      final buffer = StringBuffer();
      for (int i = 0; i < results.length; i++) {
        final res = results.item(i);
        if (res.length > 0) {
          buffer.write(res.item(0).transcript);
          buffer.write(' ');
        }
      }
      final fullText = buffer.toString().trim();
      if (fullText.isNotEmpty) {
        _accumulatedTranscript = fullText;
        onResult?.call(fullText);
      }
    }).toJS;

    _recognizer!.onerror = ((web.SpeechRecognitionErrorEvent err) {
      debugPrint('WebSpeechRecognition error: ${err.error}');
      if (err.error != 'no-speech') {
        onError?.call(err.error);
      }
    }).toJS;

    _recognizer!.onend = ((web.Event _) {
      _isListening = false;
      final completer = _endCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }).toJS;

    try {
      _recognizer!.start();
      return true;
    } catch (e) {
      debugPrint('Failed to start WebSpeechRecognition: $e');
      _isListening = false;
      return false;
    }
  }

  Future<String> stopListening() async {
    if (_recognizer != null && _isListening) {
      try {
        _recognizer!.stop();
        final completer = _endCompleter;
        if (completer != null && !completer.isCompleted) {
          await completer.future.timeout(
            const Duration(milliseconds: 350),
            onTimeout: () {},
          );
        }
      } catch (e) {
        debugPrint('WebSpeechRecognition stop error: $e');
      }
    }
    _isListening = false;
    return _accumulatedTranscript.trim();
  }

  Future<void> cancelListening() async {
    if (_recognizer != null) {
      try {
        _recognizer!.abort();
      } catch (_) {}
    }
    final completer = _endCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _endCompleter = null;
    _isListening = false;
    _accumulatedTranscript = '';
  }
}
