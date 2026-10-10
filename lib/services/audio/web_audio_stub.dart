import 'dart:ui';

/// Non-web fallback stub for web audio TTS and speech recognition.
class WebTtsDelegate {
  bool get isSupported => false;
  bool get isSpeaking => false;

  Future<void> speak({
    required String text,
    required String language,
    VoidCallback? onComplete,
  }) async {
    onComplete?.call();
  }

  Future<void> stop() async {}
}

class WebSpeechRecognitionDelegate {
  bool get isSupported => false;
  bool get isListening => false;

  Future<bool> startListening({
    required String language,
    void Function(String partialText)? onResult,
    void Function(String error)? onError,
  }) async {
    return false;
  }

  Future<String> stopListening() async {
    return '';
  }

  Future<void> cancelListening() async {}
}
