import 'package:flutter/material.dart';

/// Neumorphic + Material 3 hybrid design system for Dailathon.
/// All colours, radii, shadow helpers, and ThemeData live here.
abstract final class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color bg          = Color(0xFFE0E5EC);
  static const Color bgDark      = Color(0xFFD3D8E3);
  static const Color surface     = Color(0xFFE8ECF4);
  static const Color primary     = Color(0xFF4A7CF7);
  static const Color primaryDark = Color(0xFF3465D4);
  static const Color success     = Color(0xFF4CAF50);
  static const Color warning     = Color(0xFFFF9500);
  static const Color errorColor  = Color(0xFFE05C5C);
  static const Color info        = Color(0xFF2196F3);

  // Response category colours
  static const Color catInterested    = Color(0xFF4CAF50);
  static const Color catFollowUp      = Color(0xFFFF9500);
  static const Color catNotInterested = Color(0xFFE05C5C);
  static const Color catNotReachable  = Color(0xFF9E9E9E);
  static const Color catNoResponse    = Color(0xFF607D8B);

  // ── Text colours ─────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF2D3444);
  static const Color textSecondary = Color(0xFF6B738B);
  static const Color textHint      = Color(0xFF9EA8BC);

  // ── Neumorphic shadow colours ─────────────────────────────────────────────
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark  = Color(0xFFA3B1C6);

  // ── Border radii ──────────────────────────────────────────────────────────
  static const double radiusSm   = 10;
  static const double radiusMd   = 16;
  static const double radiusLg   = 24;
  static const double radiusFull = 100;

  // ── Neumorphic shadow helpers ─────────────────────────────────────────────

  /// Outset (raised / extruded) shadow — default for cards and buttons.
  static List<BoxShadow> raisedShadow({
    double distance = 5,
    double blur = 15,
  }) =>
      [
        BoxShadow(
          color: shadowLight.withOpacity(0.85),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: shadowDark.withOpacity(0.55),
          offset: Offset(distance, distance),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];

  /// Flat (minimal depth) shadow — for subtle floating elements.
  static List<BoxShadow> flatShadow() => [
        BoxShadow(
          color: shadowLight.withOpacity(0.55),
          offset: const Offset(-2, -2),
          blurRadius: 6,
        ),
        BoxShadow(
          color: shadowDark.withOpacity(0.3),
          offset: const Offset(2, 2),
          blurRadius: 6,
        ),
      ];

  /// Inset (pressed / depressed) shadow — for text fields and pressed states.
  static List<BoxShadow> insetShadow() => [
        BoxShadow(
          color: shadowDark.withOpacity(0.45),
          offset: const Offset(3, 3),
          blurRadius: 8,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: shadowLight.withOpacity(0.9),
          offset: const Offset(-3, -3),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];

  // ── Material ThemeData ────────────────────────────────────────────────────
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          surface: bg,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bg,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showUnselectedLabels: true,
          selectedLabelStyle:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        textTheme: const TextTheme(
          displayMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
          headlineLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          headlineSmall:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(
              color: textSecondary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textHint, fontSize: 12),
          labelLarge:
              TextStyle(color: primary, fontWeight: FontWeight.w600),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusFull),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textHint),
          prefixIconColor: textSecondary,
          suffixIconColor: textSecondary,
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: textSecondary,
          labelStyle:
              TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 13),
          dividerColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFD0D7E3),
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: bg,
          selectedColor: primary.withOpacity(0.15),
          labelStyle: const TextStyle(
              color: textPrimary, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          side: const BorderSide(color: Color(0xFFCDD3DF)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
}
