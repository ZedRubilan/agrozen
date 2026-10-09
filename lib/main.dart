import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase is optional: the app is fully usable offline (daily plan, diary,
  // alerts, course) via SharedPreferences. When credentials are not supplied
  // the cloud sync / AI path simply stays disabled instead of crashing.
  try {
    if (!SupabaseConfig.isConfigured) {
      debugPrint(
        'AgroZen: Supabase credentials not provided — running in offline mode. '
        'Pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
        'to enable sync and the AI assistant.',
      );
    } else {
      await SupabaseConfig.initialize();
    }
  } catch (e, stack) {
    debugPrint('AgroZen: Supabase init failed, continuing offline. $e\n$stack');
  }

  // Load the persisted language before the first frame so the UI never flashes
  // the wrong locale.
  final prefs = await SharedPreferences.getInstance();
  final initialLanguage = prefs.getString('app_language') ?? 'uz';

  runApp(AgroZenApp(initialLanguage: initialLanguage));
}
