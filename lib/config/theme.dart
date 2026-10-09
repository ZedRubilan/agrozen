import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors: Warm, organic, sunlight-friendly palette (no harsh neons or stark contrast)
  static const Color primaryGreen = Color(0xFF2D7A4C);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF43A047);
  static const Color secondaryAmber = Color(0xFFE5A338);
  static const Color secondaryAmberDark = Color(0xFFB8781B);
  static const Color secondaryAmberLight = Color(0xFFFFE082);
  static const Color backgroundLight = Color(0xFFF8F9F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEAF5ED);
  static const Color terracottaAlert = Color(0xFFC84B31);
  static const Color warningWarm = Color(0xFFE08119);
  static const Color calmBlue = Color(0xFF2E6F9E);

  // Backward-compatibility aliases
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color secondaryBrownDark = Color(0xFF4E342E);
  static const Color secondaryBrownLight = Color(0xFFA1887F);
  static const Color errorRed = terracottaAlert;
  static const Color warningOrange = warningWarm;
  static const Color infoBlue = calmBlue;

  // Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEAF5ED),
      onPrimaryContainer: primaryGreenDark,
      secondary: secondaryBrown,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFFF7E6),
      onSecondaryContainer: const Color(0xFF5D3E08),
      surface: surfaceLight,
      error: terracottaAlert,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    TextTheme? textTheme;
    try {
      textTheme = GoogleFonts.plusJakartaSansTextTheme();
    } catch (_) {
      textTheme = null;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.15,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: primaryGreen, width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: terracottaAlert),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: const Color(0xFFEAF5ED),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF757575),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreenDark);
          }
          return const IconThemeData(color: Color(0xFF757575));
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantLight,
        selectedColor: const Color(0xFFEAF5ED),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: const Color(0xFF81C784),
      onPrimary: const Color(0xFF003300),
      secondary: secondaryAmberLight,
      onSecondary: const Color(0xFF2E1C14),
      surface: const Color(0xFF1E241E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121612),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B2E1D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E241E),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
