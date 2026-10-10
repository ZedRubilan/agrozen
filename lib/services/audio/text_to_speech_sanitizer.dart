/// Sanitizes and prepares written text (markdown, agricultural notation,
/// symbols) into natural, fluent text for Text-to-Speech synthesis engines.
class TextToSpeechSanitizer {
  /// Transforms raw assistant markdown responses into human-like spoken speech.
  static String clean({
    required String text,
    required String language,
  }) {
    if (text.trim().isEmpty) return '';

    final lang = language.toLowerCase();
    String s = text;

    // 0. Strip HTML comments so metadata never gets spoken aloud
    s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

    // 1. Remove markdown links: [Label](url) -> Label
    s = s.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );

    // 2. Remove raw URLs
    s = s.replaceAll(RegExp(r'https?://\S+'), '');

    // 3. Remove code blocks and inline code backticks
    s = s.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    s = s.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // 4. Strip line-leading markdown bullets before inline *italic* matching
    // so consecutive '* item' lines do not get paired as a single italic span.
    s = s.replaceAll(RegExp(r'^[\t ]*[-*+•]\s+', multiLine: true), '');

    // 5. Remove bold, italic, strike formatting
    s = s.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    s = s.replaceAll(RegExp(r'\*([^*\n]+)\*'), r'$1');
    s = s.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    s = s.replaceAll(RegExp(r'_([^_\n]+)_'), r'$1');
    s = s.replaceAll(RegExp(r'~~([^~]+)~~'), r'$1');

    // 6. Expand agricultural / scientific units to natural spoken words
    if (lang == 'uz') {
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*°\s*C', caseSensitive: false),
        (m) => '${m.group(1)} gradus',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*g/bosh', caseSensitive: false),
        (m) => "${m.group(1)} gramm har bir jo'jaga",
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*kg\b', caseSensitive: false),
        (m) => '${m.group(1)} kilogramm',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*g\b', caseSensitive: false),
        (m) => '${m.group(1)} gramm',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*%', caseSensitive: false),
        (m) => '${m.group(1)} foiz',
      );
      s = s.replaceAllMapped(
        RegExp(r'~\s*(\d+(?:[.,]\d+)?)'),
        (m) => 'taxminan ${m.group(1)}',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+)\s*-\s*(\d+)\s*kun', caseSensitive: false),
        (m) => '${m.group(1)} dan ${m.group(2)} kungacha',
      );
    } else if (lang == 'ru') {
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*°\s*C', caseSensitive: false),
        (m) => '${m.group(1)} градусов Цельсия',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:g/bosh|г/голову|г/гол)', caseSensitive: false),
        (m) => '${m.group(1)} грамм на голову',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:kg|кг)\b', caseSensitive: false),
        (m) => '${m.group(1)} килограмм',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:g|г)\b', caseSensitive: false),
        (m) => '${m.group(1)} грамм',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*%', caseSensitive: false),
        (m) => '${m.group(1)} процентов',
      );
      s = s.replaceAllMapped(
        RegExp(r'~\s*(\d+(?:[.,]\d+)?)'),
        (m) => 'примерно ${m.group(1)}',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+)\s*-\s*(\d+)\s*(?:дней|дня|день)', caseSensitive: false),
        (m) => 'от ${m.group(1)} до ${m.group(2)} дней',
      );
    } else {
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*°\s*C', caseSensitive: false),
        (m) => '${m.group(1)} degrees Celsius',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*kg\b', caseSensitive: false),
        (m) => '${m.group(1)} kilograms',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*g\b', caseSensitive: false),
        (m) => '${m.group(1)} grams',
      );
      s = s.replaceAllMapped(
        RegExp(r'(\d+(?:[.,]\d+)?)\s*%', caseSensitive: false),
        (m) => '${m.group(1)} percent',
      );
      s = s.replaceAllMapped(
        RegExp(r'~\s*(\d+(?:[.,]\d+)?)'),
        (m) => 'approximately ${m.group(1)}',
      );
    }

    // 7. Clean headers, bullet points, blockquotes and table markers line-by-line
    final lines = s.split('\n');
    final cleanedLines = <String>[];

    for (var line in lines) {
      var l = line.trim();
      if (l.isEmpty) continue;

      // Ignore horizontal separators
      if (RegExp(r'^[-*_]{3,}$').hasMatch(l)) continue;

      // Strip markdown header hashes (# Title -> Title)
      l = l.replaceAll(RegExp(r'^#{1,6}\s*'), '');

      // Strip bullet symbols (- Item, * Item, + Item, • Item)
      l = l.replaceAll(RegExp(r'^[-*+•]\s*'), '');

      // Strip numbered list markers (1. Item -> Item)
      l = l.replaceAll(RegExp(r'^\d+\.\s*'), '');

      // Strip blockquotes (> Quote -> Quote)
      l = l.replaceAll(RegExp(r'^>\s*'), '');

      // Replace markdown table pipes with commas
      if (l.contains('|')) {
        l = l.split('|').map((part) => part.trim()).where((part) => part.isNotEmpty).join(', ');
      }

      if (l.isNotEmpty) {
        cleanedLines.add(l);
      }
    }

    s = cleanedLines.join('. ');

    // 8. Strip distracting emojis and unicode symbols that TTS engines read out literally
    s = s.replaceAll(
      RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1FA70}-\u{1FAFF}]', unicode: true),
      '',
    );
    s = s.replaceAll(RegExp(r'[•✔✅❌📌💡📞🚨⚠️©®™]'), '');

    // 9. Normalize spacing and punctuation without breaking decimal numbers (e.g. 32.5 or 32,5)
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'\.{2,}'), '.');
    s = s.replaceAll(RegExp(r'\s*,(?!\d)\s*'), ', ');
    s = s.replaceAll(RegExp(r'\s*\.(?!\d)\s*'), '. ');
    s = s.replaceAll(RegExp(r'\s*\?\s*'), '? ');
    s = s.replaceAll(RegExp(r'\s*!\s*'), '! ');

    return s.trim();
  }
}
