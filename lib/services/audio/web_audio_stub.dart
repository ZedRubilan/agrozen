import 'dart:ui';

/// Non-web fallback stub for web audio TTS and speech recognition.
class WebTtsDelegate {
  bool get isSupported => false;
  bool get isSpeaking => false;
  String? get activeVoiceName => null;

  bool hasMicrosoftNaturalVoice(String language) => false;

  Future<bool> playAudioBase64({
    required String base64Data,
    required String mimeType,
    VoidCallback? onComplete,
  }) async {
    return false;
  }

  Future<void> speak({
    required String text,
    required String language,
    bool forceDefaultVoice = false,
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

