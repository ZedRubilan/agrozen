import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AgroZen design tokens.
///
/// Every screen and widget reads colours, spacing, radii and text styles from
/// here. If a value is not defined here, it does not belong in the UI — add a
/// token instead of hard-coding a one-off `Color(0x…)` or font size.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(
    0xFF15803D,
  ); // Agro Emerald — actions, progress
  static const Color primaryDark = Color(0xFF14532D); // Text on soft green
  static const Color primarySoft = Color(
    0xFFE6F4EA,
  ); // Selected / positive backgrounds

  // Surfaces
  static const Color background = Color(0xFFF4F7F4); // Alabaster Mist
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F2); // Tiles inside cards
  static const Color border = Color(0xFFE2EBE4);

  // Ink
  static const Color ink = Color(0xFF0F172A); // Slate Ink
  static const Color inkSecondary = Color(0xFF52665A); // Muted Sage
  static const Color inkMuted = Color(0xFF63796A);

  // Status
  static const Color warning = Color(0xFFB45309);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // Accent — warmth / temperature only
  static const Color gold = Color(0xFFF59E0B);

  // Sun — the one filled "hero" tile per screen (brooder heat, key action)
  static const Color sun = Color(0xFFF97316);
  static const Color sunDeep = Color(0xFFEA580C);

  // Hero photo overlay — deep barn green that keeps white text readable
  static const Color heroShade = Color(0xFF052E16);
}

/// Soft, low elevation shadows. Cards float slightly above the background
/// instead of being outlined.
class AppShadow {
  AppShadow._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x080F172A), blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x100F172A), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withAlpha(90),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

/// 4-point spacing scale.
class AppSpace {
  AppSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal padding of every screen.
  static const double screen = 16;
}

class AppRadius {
  AppRadius._();

  static const double sm = 12; // Inputs, buttons
  static const double md = 18; // Tiles inside a section
  static const double lg = 24; // Cards, sheets
  static const double hero = 32; // Photo hero bottom corners
  static const double pill = 999;
}

/// Font fallbacks: Plus Jakarta Sans has no basic Cyrillic, so Russian
/// letters come from the bundled Noto Sans Cyrillic subset (pubspec.yaml).
class AppFonts {
  AppFonts._();

  static const List<String> fallback = ['NotoSansCyrillic'];
}

/// Text styles. They carry no font family, so they inherit the app font from
/// the surrounding [DefaultTextStyle]; each names the Cyrillic fallback so
/// Russian renders the same even outside that chain (dialogs, overlays).
class AppText {
  AppText._();

  static const TextStyle screenTitle = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
    color: AppColors.ink,
  );

  static const TextStyle section = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.ink,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.inkSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.inkMuted,
  );

  static const TextStyle metric = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.1,
    color: AppColors.ink,
  );

  /// Big number on photos and rings (day counter).
  static const TextStyle display = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1,
    color: AppColors.ink,
  );

  static const TextStyle label = TextStyle(
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
}

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 220);
  static const Curve curve = Curves.easeOutCubic;

  /// Screen entrance: sections fade and rise one after another.
  static const Duration enter = Duration(milliseconds: 520);
  static const Duration stagger = Duration(milliseconds: 70);

  /// Numbers counting up and rings filling when a screen opens.
  static const Duration count = Duration(milliseconds: 900);
}

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primarySoft,
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.primaryDark,
          onSecondary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.inkSecondary,
          surfaceTint: Colors.transparent,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
          error: AppColors.danger,
          onError: Colors.white,
        );

    TextTheme textTheme = const TextTheme(
      headlineSmall: AppText.screenTitle,
      titleLarge: AppText.screenTitle,
      titleMedium: AppText.section,
      titleSmall: AppText.cardTitle,
      bodyLarge: AppText.body,
      bodyMedium: AppText.bodyMuted,
      bodySmall: AppText.caption,
      labelLarge: TextStyle(
        fontFamilyFallback: AppFonts.fallback,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: AppText.label,
    );
    try {
      textTheme = GoogleFonts.plusJakartaSansTextTheme(textTheme);
    } catch (_) {
      // Font unavailable (offline first run / tests) — system font is fine.
    }
    textTheme = textTheme.apply(fontFamilyFallback: AppFonts.fallback);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    const buttonText = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      fontFamilyFallback: AppFonts.fallback,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      fontFamilyFallback: AppFonts.fallback,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamilyFallback: AppFonts.fallback,
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: const StadiumBorder(),
        height: 66,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamilyFallback: AppFonts.fallback,
            fontSize: 12.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.inkSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.inkSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 44),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontFamilyFallback: AppFonts.fallback,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 1.6),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 1.6),
        hintStyle: const TextStyle(
          fontFamilyFallback: AppFonts.fallback,
          color: AppColors.inkMuted,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
          fontFamilyFallback: AppFonts.fallback,
          color: AppColors.inkSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
          fontFamilyFallback: AppFonts.fallback,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamilyFallback: AppFonts.fallback,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.primarySoft,
          selectedForegroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(
            fontFamilyFallback: AppFonts.fallback,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.inkSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
      ),
    );
  }
}
