import 'package:agrozen/services/audio/text_to_speech_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextToSpeechSanitizer Tests', () {
    test('strips markdown headers, bullets, bold, and links', () {
      const input = '''
# Harorat rejimi
- **1-3 kun:** 32°C harorat kerak.
• Havola: [Ko'rish](https://agrozen.uz/norm)
''';
      final cleaned = TextToSpeechSanitizer.clean(text: input, language: 'uz');
      expect(cleaned, isNot(contains('#')));
      expect(cleaned, isNot(contains('**')));
      expect(cleaned, isNot(contains('•')));
      expect(cleaned, isNot(contains('http')));
      expect(cleaned, contains('32 gradus'));
      expect(cleaned, contains("Ko'rish"));
    });

    test('expands Russian agricultural abbreviations correctly', () {
      const input = '''
## Кормление цыплят
- Норма: ~45g/bosh, температура 30°C.
- Вес партии: 120kg.
''';
      final cleaned = TextToSpeechSanitizer.clean(text: input, language: 'ru');
      expect(cleaned, contains('примерно 45 грамм на голову'));
      expect(cleaned, contains('30 градусов Цельсия'));
      expect(cleaned, contains('120 килограмм'));
    });

    test('handles empty and whitespace-only text gracefully', () {
      expect(TextToSpeechSanitizer.clean(text: '', language: 'uz'), '');
      expect(TextToSpeechSanitizer.clean(text: '   ', language: 'ru'), '');
    });
  });
}
