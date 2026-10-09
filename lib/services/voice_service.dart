abstract class SpeechToTextService {
  Future<String> transcribe(String audioFilePath, String languageCode);
}
class GoogleCloudSTT implements SpeechToTextService {
  @override
  Future<String> transcribe(String audioFilePath, String languageCode) async {
    return "Transcribed text";
  }
}
class WhisperSTT implements SpeechToTextService {
  @override
  Future<String> transcribe(String audioFilePath, String languageCode) async {
    return "Transcribed text";
  }
}
