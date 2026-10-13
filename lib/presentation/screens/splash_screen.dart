import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../widgets/agro_icons.dart';

/// Hands off instantly: to `/home` when onboarded, otherwise to onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Let the first frame mount, then move on without any artificial delay.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    var onboarded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboarded = prefs.getBool('is_onboarded') ?? false;
    } catch (_) {}
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/onboarding/language');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [AppColors.primary, AppColors.heroShade],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AgroChickIcon(size: 88),
              const SizedBox(height: AppSpace.lg),
              Text(
                'AgroZen',
                style: AppText.screenTitle.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
