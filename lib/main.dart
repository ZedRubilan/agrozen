import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted language immediately so the first frame renders instantaneously
  final prefs = await SharedPreferences.getInstance();
  final initialLanguage = prefs.getString('app_language') ?? 'uz';

  runApp(AgroZenApp(initialLanguage: initialLanguage));

  // Initialize optional Supabase in background without delaying the Welcome Screen
  unawaited(_initSupabaseInBackground());
}

Future<void> _initSupabaseInBackground() async {
  try {
    await SupabaseConfig.loadDotEnvIfPresent();
    await SupabaseConfig.initialize();
  } catch (e, stack) {
    debugPrint('AgroZen: Supabase init failed, continuing offline. $e\n$stack');
  }
}
