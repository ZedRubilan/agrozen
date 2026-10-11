import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String _envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
  static const String _envGeminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static String? _runtimeUrl;
  static String? _runtimeAnonKey;
  static String? _runtimeGeminiKey;
  static bool _initialized = false;

  static String get url =>
      (_runtimeUrl != null && _runtimeUrl!.isNotEmpty) ? _runtimeUrl! : _envUrl;

  static String get anonKey =>
      (_runtimeAnonKey != null && _runtimeAnonKey!.isNotEmpty)
          ? _runtimeAnonKey!
          : _envAnonKey;

  static String get geminiApiKey =>
      (_runtimeGeminiKey != null && _runtimeGeminiKey!.isNotEmpty)
          ? _runtimeGeminiKey!
          : _envGeminiKey;

  static bool get _hasValidCredentials =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('your-project.supabase.co') &&
      !anonKey.contains('your-anon-key');

  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty &&
      !geminiApiKey.contains('your-gemini-api-key');

  /// True when real credentials were supplied at build time or initialized from .env.
  /// Without them the app runs offline and never touches the network.
  static bool get isConfigured =>
      _hasValidCredentials &&
      (_initialized ||
          (_envUrl != 'https://your-project.supabase.co' &&
              _envAnonKey != 'your-anon-key'));

  static SupabaseClient get client => Supabase.instance.client;

  /// Attempts to read `.env` from the local working directory when running on
  /// mobile/desktop without `--dart-define` flags.
  static Future<void> loadDotEnvIfPresent() async {
    if (kIsWeb) return;
    try {
      final envFile = File('.env');
      if (!await envFile.exists()) return;
      final lines = await envFile.readAsLines();
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#') || !line.contains('=')) {
          continue;
        }
        final eqIndex = line.indexOf('=');
        final key = line.substring(0, eqIndex).trim();
        var value = line.substring(eqIndex + 1).trim();
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }
        if (key == 'SUPABASE_URL' && value.isNotEmpty) {
          _runtimeUrl = value;
        } else if (key == 'SUPABASE_ANON_KEY' && value.isNotEmpty) {
          _runtimeAnonKey = value;
        } else if (key == 'GEMINI_API_KEY' && value.isNotEmpty) {
          _runtimeGeminiKey = value;
        }
      }
    } catch (_) {
      // Ignore filesystem errors in restricted environments
    }
  }

  static Future<void> initialize() async {
    await loadDotEnvIfPresent();
    if (!_hasValidCredentials) return;
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
    );
    _initialized = true;
  }
}

