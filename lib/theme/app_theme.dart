import 'package:flutter/material.dart';

class AppTheme {
  // Monochrome Minimalist Palette
  static const Color pureBlack = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2E2E2E);
  static const Color mutedTextDark = Color(0xFF9E9E9E);

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color mutedTextLight = Color(0xFF6B7280);

  // Light Theme (Clean Academic Minimalist)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightSurface,
      colorScheme: const ColorScheme.light(
        primary: pureBlack,
        onPrimary: pureWhite,
        secondary: Color(0xFF262626),
        onSecondary: pureWhite,
        surface: cardLight,
        onSurface: pureBlack,
        outline: borderLight,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        foregroundColor: pureBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: pureBlack,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderLight, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: pureWhite,
        indicatorColor: pureBlack,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: pureBlack,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedTextLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: pureWhite, size: 22);
          }
          return const IconThemeData(color: mutedTextLight, size: 22);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureBlack,
          foregroundColor: pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureBlack,
          side: const BorderSide(color: pureBlack, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pureBlack, width: 1.5),
        ),
        labelStyle: const TextStyle(color: mutedTextLight),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),
    );
  }

  // Dark Theme (Ultra-Sleek Monochrome Dark)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      colorScheme: const ColorScheme.dark(
        primary: pureWhite,
        onPrimary: pureBlack,
        secondary: Color(0xFFE5E5E5),
        onSecondary: pureBlack,
        surface: darkSurface,
        onSurface: pureWhite,
        outline: borderDark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderDark, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: pureWhite,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: pureWhite,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedTextDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: pureBlack, size: 22);
          }
          return const IconThemeData(color: mutedTextDark, size: 22);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureWhite,
          foregroundColor: pureBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureWhite,
          side: const BorderSide(color: pureWhite, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pureWhite, width: 1.5),
        ),
        labelStyle: const TextStyle(color: mutedTextDark),
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
      ),
    );
  }
}
