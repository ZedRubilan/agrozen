import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/agro_icons.dart';

/// Instantaneous entry handoff screen:
/// Zero loading spinners or artificial delays — immediately routes to `/home`
/// (if onboarded) or `/onboarding/language` (the full-screen Welcome & Language experience).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeImmediately();
  }

  Future<void> _routeImmediately() async {
    // Allow initial frame mount, then transition instantaneously without any loading delay
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final isOnboarded = prefs.getBool('is_onboarded') ?? false;
      if (isOnboarded) {
        context.go('/home');
      } else {
        context.go('/onboarding/language');
      }
    } catch (_) {
      if (!mounted) return;
      context.go('/onboarding/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2214),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/sunset_farm.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFF0B2214),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0B2214).withAlpha(190),
                  const Color(0xFF0B2214).withAlpha(235),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AgroChickIcon(size: 88),
                  const SizedBox(height: 18),
                  const Text(
                    'AgroZen',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AgroProgressDots(
                    currentStep: 0,
                    totalSteps: 4,
                    activeColor: Color(0xFF34D399),
                    inactiveColor: Color(0x55FFFFFF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
