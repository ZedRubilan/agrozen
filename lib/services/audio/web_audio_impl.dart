import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// High-performance Web implementation of Text-to-Speech using native Web Speech API
/// and HTML5 Audio for Gemini Neural TTS.
/// Prioritizes Microsoft Natural / Neural voices first, with automatic retry fallback
/// to the default system TTS voice if an online voice fails.
class WebTtsDelegate {
  Timer? _keepAliveTimer;
  bool _isSpeaking = false;
  int _sessionId = 0;
  VoidCallback? _onCompleteCallback;
  List<String> _pendingChunks = [];
  int _currentChunkIndex = 0;
  String _currentLanguage = 'uz';
  bool _useFallbackDefault = false;
  bool _retriedCurrentChunk = false;
  String? _activeVoiceName;
  web.HTMLAudioElement? _activeAudioElement;

  bool get isSupported {
    try {
      return (web.window as JSObject).has('speechSynthesis');
    } catch (_) {
      return false;
    }
  }

  bool get isSpeaking => _isSpeaking;
  String? get activeVoiceName => _activeVoiceName;

  /// Checks whether the browser currently exposes a Microsoft Natural / Neural voice
  /// for the requested language (or Turkish/Russian phonetic match for Uzbek).
  bool hasMicrosoftNaturalVoice(String language) {
    if (!isSupported) return false;
    try {
      final voices = web.window.speechSynthesis.getVoices().toDart;
      final lang = language.toLowerCase();
      final prefixes = lang == 'ru'
          ? ['ru']
          : (lang == 'uz' ? ['uz', 'tr', 'ru'] : ['en']);
      for (final prefix in prefixes) {
        for (final v in voices) {
          if (v.lang.toLowerCase().startsWith(prefix) &&
              _isMicrosoftNaturalVoice(v)) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Plays base64-encoded audio (e.g., WAV from Gemini TTS) via HTML5 Audio.
  /// Returns `true` if playback started and completed cleanly, or `false` if
  /// playback failed so the caller can fall back to standard TTS.
  Future<bool> playAudioBase64({
    required String base64Data,
    required String mimeType,
    VoidCallback? onComplete,
  }) async {
    if (base64Data.isEmpty) return false;
    await stop();

    _sessionId++;
    final session = _sessionId;
    _isSpeaking = true;
    _activeVoiceName = 'Gemini Voice';
    _onCompleteCallback = onComplete;

    final completer = Completer<bool>();

    try {
      final audio = web.HTMLAudioElement();
      _activeAudioElement = audio;
      audio.src = 'data:$mimeType;base64,$base64Data';

      audio.onended = ((web.Event _) {
        if (session != _sessionId) return;
        _activeAudioElement = null;
        _finishPlayback();
        if (!completer.isCompleted) completer.complete(true);
      }).toJS;

      audio.onerror = ((web.Event _) {
        if (session != _sessionId) return;
        _activeAudioElement = null;
        _isSpeaking = false;
        if (!completer.isCompleted) completer.complete(false);
      }).toJS;

      await audio.play().toDart;
      return await completer.future;
    } catch (e) {
      debugPrint('WebTtsDelegate playAudioBase64 error: $e');
      _activeAudioElement = null;
      _isSpeaking = false;
      return false;
    }
  }

  /// Speaks text cleanly on Web, chunking long text into natural sentences
  /// to avoid Chrome's 15-second speech synthesis silent cutoff bug.
  Future<void> speak({
    required String text,
    required String language,
    bool forceDefaultVoice = false,
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
    _useFallbackDefault = forceDefaultVoice;
    _retriedCurrentChunk = false;
    _pendingChunks = _splitIntoNaturalChunks(text);
    _currentChunkIndex = 0;

    // Warm up voice list if initially empty in Chrome
    try {
      web.window.speechSynthesis.getVoices();
    } catch (_) {}

    _startKeepAlive();
    _playNextChunk(_sessionId);
  }

  /// Cancels any active web utterance or HTML5 audio and cleans timers.
  Future<void> stop() async {
    _sessionId++;
    _stopKeepAlive();
    _isSpeaking = false;
    _pendingChunks = [];
    _currentChunkIndex = 0;
    _retriedCurrentChunk = false;
    _onCompleteCallback = null;

    try {
      final audio = _activeAudioElement;
      _activeAudioElement = null;
      if (audio != null) {
        audio.pause();
        audio.src = '';
      }
    } catch (_) {}

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
      _retriedCurrentChunk = false;
      _playNextChunk(session);
      return;
    }

    try {
      final synth = web.window.speechSynthesis;
      synth.resume();

      final utterance = web.SpeechSynthesisUtterance(chunk);
      utterance.rate = 1.03;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;

      final (targetVoice, targetLang) = _selectBestVoice(
        _currentLanguage,
        useFallbackDefault: _useFallbackDefault,
      );
      if (targetVoice != null) {
        utterance.voice = targetVoice;
        _activeVoiceName = targetVoice.name;
      } else {
        _activeVoiceName = 'System Default ($targetLang)';
      }
      utterance.lang = targetLang;

      utterance.onend = ((web.Event _) {
        if (!_isSpeaking || session != _sessionId) return;
        _currentChunkIndex++;
        _retriedCurrentChunk = false;
        _playNextChunk(session);
      }).toJS;

      utterance.onerror = ((web.SpeechSynthesisErrorEvent err) {
        if (!_isSpeaking || session != _sessionId) return;
        if (err.error == 'canceled' || err.error == 'interrupted') return;
        debugPrint(
          'WebSpeechUtterance error (${_activeVoiceName ?? "default"}): ${err.error}',
        );
        // If Microsoft Natural / online voice failed, fall back to default system TTS
        // and retry the current chunk instead of dropping the audio.
        if (!_useFallbackDefault && !_retriedCurrentChunk) {
          debugPrint('Falling back from natural voice to default system TTS.');
          _useFallbackDefault = true;
          _retriedCurrentChunk = true;
          _playNextChunk(session);
          return;
        }
        _currentChunkIndex++;
        _retriedCurrentChunk = false;
        _playNextChunk(session);
      }).toJS;

      synth.speak(utterance);
    } catch (e) {
      debugPrint('WebTtsDelegate _playNextChunk error: $e');
      if (!_isSpeaking || session != _sessionId) return;
      if (!_useFallbackDefault && !_retriedCurrentChunk) {
        _useFallbackDefault = true;
        _retriedCurrentChunk = true;
        _playNextChunk(session);
        return;
      }
      _currentChunkIndex++;
      _retriedCurrentChunk = false;
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

  bool _isMicrosoftNaturalVoice(web.SpeechSynthesisVoice v) {
    final name = v.name.toLowerCase();
    return name.contains('microsoft') &&
        (name.contains('natural') ||
            name.contains('online') ||
            name.contains('neural'));
  }

  bool _isNeuralOrCloudVoice(web.SpeechSynthesisVoice v) {
    final name = v.name.toLowerCase();
    return name.contains('natural') ||
        name.contains('neural') ||
        name.contains('google') ||
        name.contains('microsoft') ||
        !v.localService;
  }

  /// Selects the best sounding voice available in the browser.
  /// Priority order when [useFallbackDefault] is false:
  /// 1. Microsoft Natural / Online Neural voice (e.g., Microsoft Madina/Sardor/Dmitry/Aria Online Natural)
  /// 2. Google Neural / Cloud voice
  /// 3. Local / Default system voice
  /// When [useFallbackDefault] is true, selects a local/default voice directly.
  (web.SpeechSynthesisVoice?, String) _selectBestVoice(
    String language, {
    bool useFallbackDefault = false,
  }) {
    final synth = web.window.speechSynthesis;
    final voices = synth.getVoices().toDart;
    final lang = language.toLowerCase();

    final List<(String prefix, String tag)> candidates = lang == 'ru'
        ? [('ru', 'ru-RU')]
        : (lang == 'uz'
            ? [('uz', 'uz-UZ'), ('tr', 'tr-TR'), ('ru', 'ru-RU')]
            : [('en', 'en-US')]);

    if (!useFallbackDefault) {
      // 1. Check all candidate languages for a Microsoft Natural Voice first
      for (final (prefix, tag) in candidates) {
        for (final v in voices) {
          if (v.lang.toLowerCase().startsWith(prefix) &&
              _isMicrosoftNaturalVoice(v)) {
            return (v, tag);
          }
        }
      }

      // 2. Check for Google / Neural voices
      for (final (prefix, tag) in candidates) {
        for (final v in voices) {
          if (v.lang.toLowerCase().startsWith(prefix) &&
              _isNeuralOrCloudVoice(v)) {
            return (v, tag);
          }
        }
      }
    }

    // 3. Fallback: prefer local service voice or first matching voice for language
    for (final (prefix, tag) in candidates) {
      for (final v in voices) {
        if (v.lang.toLowerCase().startsWith(prefix) && v.localService) {
          return (v, tag);
        }
      }
      for (final v in voices) {
        if (v.lang.toLowerCase().startsWith(prefix)) {
          return (v, tag);
        }
      }
    }

    final defaultTag =
        lang == 'ru' ? 'ru-RU' : (lang == 'uz' ? 'uz-UZ' : 'en-US');
    return (null, defaultTag);
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
  bool _retriedFallbackLang = false;

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
    _retriedFallbackLang = false;
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
      if (err.error == 'language-not-supported' &&
          !_retriedFallbackLang &&
          _recognizer != null) {
        _retriedFallbackLang = true;
        try {
          _recognizer!.lang = 'tr-TR';
          _recognizer!.start();
          return;
        } catch (_) {}
      }
      if (err.error != 'no-speech' && err.error != 'aborted') {
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

