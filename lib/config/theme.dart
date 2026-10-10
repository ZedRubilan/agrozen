import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AgroZen Modern Agricultural Design System
/// Inspired by clean, photo-first, ultra-rounded organic interfaces.
class AppTheme {
  // Brand Core Colors
  static const Color primaryGreen = Color(0xFF2D7A4C);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF43A047);
  static const Color vibrantGreen = Color(0xFF22C55E);
  static const Color emeraldDeep = Color(0xFF0F3B20);
  static const Color emeraldSoft = Color(0xFFE8F5EC);

  // Harvest & Sunset Warm Ambers (from reference image)
  static const Color secondaryAmber = Color(0xFFE5A338);
  static const Color secondaryAmberDark = Color(0xFFB8781B);
  static const Color secondaryAmberLight = Color(0xFFFFE082);
  static const Color goldWarm = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFFF7ED);

  // Surfaces & Backgrounds
  static const Color backgroundLight = Color(0xFFF6F8F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEAF5ED);
  static const Color surfaceSubtle = Color(0xFFF1F5F2);
  static const Color cardBorder = Color(0xFFE5EDE6);

  // High-contrast ink colors
  static const Color textPrimary = Color(0xFF111E14);
  static const Color textSecondary = Color(0xFF4B5E4F);
  static const Color textMuted = Color(0xFF7A8E7E);
  static const Color textLight = Color(0xFFFFFFFF);

  // Functional alert colors
  static const Color terracottaAlert = Color(0xFFDC2626);
  static const Color warningWarm = Color(0xFFE08119);
  static const Color calmBlue = Color(0xFF2563EB);

  // Backward-compatibility aliases
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color secondaryBrownDark = Color(0xFF4E342E);
  static const Color secondaryBrownLight = Color(0xFFA1887F);
  static const Color errorRed = terracottaAlert;
  static const Color warningOrange = warningWarm;
  static const Color infoBlue = calmBlue;

  // Ultra-Rounded Geometry Tokens (matching reference images)
  static const double radiusSm = 14.0;
  static const double radiusMd = 20.0;
  static const double radiusLg = 28.0;
  static const double radiusXl = 34.0;
  static const double radiusPill = 999.0;

  // Soft Ambient Multi-Layer Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F2617).withAlpha(10),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF1B5E20).withAlpha(8),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get floatingPillShadow => [
        BoxShadow(
          color: Colors.black.withAlpha(28),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: primaryGreenDark.withAlpha(20),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreenDark.withAlpha(70),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  // Motion Tokens (Emil Kowalski Animation Philosophy)
  static const Duration durationFast = Duration(milliseconds: 140);
  static const Duration durationMedium = Duration(milliseconds: 220);
  static const Duration durationSlow = Duration(milliseconds: 320);
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeSpring = Curves.easeOutBack;

  // Signature Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E8252), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetAmberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardOverlay = LinearGradient(
    colors: [
      Color(0x99000000),
      Color(0x33000000),
      Color(0xB3000000),
    ],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Cached Theme Instances
  static final ThemeData _lightTheme = _buildLightTheme();
  static final ThemeData _darkTheme = _buildDarkTheme();

  // Light Theme Configuration
  static ThemeData get lightTheme => _lightTheme;

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: surfaceVariantLight,
      onPrimaryContainer: primaryGreenDark,
      secondary: secondaryBrown,
      onSecondary: Colors.white,
      secondaryContainer: amberSoft,
      onSecondaryContainer: secondaryAmberDark,
      surface: surfaceLight,
      surfaceTint: Colors.transparent,
      error: terracottaAlert,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    TextTheme? textTheme;
    try {
      final base = GoogleFonts.plusJakartaSansTextTheme();
      textTheme = base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: textPrimary,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: textPrimary,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: textPrimary,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: textPrimary,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 15,
          letterSpacing: 0.1,
          height: 1.45,
          color: textPrimary,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 13.5,
          height: 1.4,
          color: textSecondary,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 12,
          color: textMuted,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      );
    } catch (_) {
      textTheme = null;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: cardBorder, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        elevation: 12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shadowColor: primaryGreenDark.withAlpha(90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: primaryGreen, width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: cardBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: cardBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: primaryGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: terracottaAlert, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: terracottaAlert, width: 1.8),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8C9E90),
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSubtle,
        selectedColor: emeraldSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme => _darkTheme;

  static ThemeData _buildDarkTheme() {
    const darkSurface = Color(0xFF162018);
    const darkBorder = Color(0xFF233527);
    const darkTextPrimary = Color(0xFFF1F5F2);
    const darkTextSecondary = Color(0xFFB5C7B9);
    const darkTextMuted = Color(0xFF839687);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: const Color(0xFF81C784),
      onPrimary: const Color(0xFF003300),
      secondary: secondaryAmberLight,
      onSecondary: const Color(0xFF2E1C14),
      surface: darkSurface,
      error: terracottaAlert,
      onError: Colors.white,
    );

    TextTheme? textTheme;
    try {
      final base = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
      textTheme = base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: darkTextPrimary,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: darkTextPrimary,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: darkTextPrimary,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: darkTextPrimary,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: darkTextPrimary,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: darkTextPrimary,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 15,
          letterSpacing: 0.1,
          height: 1.45,
          color: darkTextPrimary,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 13.5,
          height: 1.4,
          color: darkTextSecondary,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 12,
          color: darkTextMuted,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      );
    } catch (_) {
      textTheme = null;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF0F1511),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        elevation: 12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenLight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF81C784),
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: Color(0xFF81C784), width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF81C784),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C291F),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: Color(0xFF81C784), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: terracottaAlert, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: terracottaAlert, width: 1.8),
        ),
        hintStyle: const TextStyle(
          color: darkTextMuted,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1C291F),
        selectedColor: primaryGreenDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
    );
  }
}
