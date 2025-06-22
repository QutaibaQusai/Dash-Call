// lib/themes/app_themes.dart

import 'package:flutter/material.dart';

class AppThemes {
  // Light Theme Colors
  static const Color _lightPrimary = Color(0xFF0077F9);
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFF2F2F7);
  static const Color _lightOnBackground = Color(0xFF000000);
  static const Color _lightOnSurface = Color(0xFF1C1C1E);
  static const Color _lightSecondary = Color(0xFF8E8E93);
  
  // Dark Theme Colors
  static const Color _darkPrimary = Color(0xFF0A84FF);
  static const Color _darkBackground = Color(0xFF000000);
  static const Color _darkSurface = Color(0xFF1C1C1E);
  static const Color _darkOnBackground = Color(0xFFFFFFFF);
  static const Color _darkOnSurface = Color(0xFFFFFFFF);
  static const Color _darkSecondary = Color(0xFF8E8E93);

  // SF UI Text font family constant
  static const String _fontFamily = '.SF UI Text';

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      
      // Set default font family for the entire app
      fontFamily: _fontFamily,
      
      // Color Scheme - This replaces deprecated backgroundColor
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        background: _lightBackground,
        onBackground: _lightOnBackground,
        onSurface: _lightOnSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),

      // Text Theme - Using .SF UI Text font family
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        displayMedium: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        displaySmall: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        headlineLarge: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        headlineMedium: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        headlineSmall: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        titleLarge: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        bodyMedium: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground),
        bodySmall: TextStyle(fontFamily: _fontFamily, color: _lightSecondary),
        labelLarge: TextStyle(fontFamily: _fontFamily, color: _lightOnBackground, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: _fontFamily, color: _lightSecondary),
        labelSmall: TextStyle(fontFamily: _fontFamily, color: _lightSecondary),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _lightBackground,
        foregroundColor: _lightOnBackground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: _lightOnBackground,
          fontFamily: _fontFamily,
        ),
        iconTheme: IconThemeData(color: _lightPrimary),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimary,
          side: const BorderSide(color: _lightPrimary),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: _lightSecondary, fontFamily: _fontFamily),
        hintStyle: const TextStyle(color: _lightSecondary, fontFamily: _fontFamily),
        helperStyle: const TextStyle(color: _lightSecondary, fontFamily: _fontFamily),
        errorStyle: const TextStyle(color: Colors.red, fontFamily: _fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _lightSecondary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _lightSecondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _lightPrimary,
        unselectedItemColor: _lightSecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontFamily: _fontFamily),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: _lightSecondary.withOpacity(0.3),
        thickness: 0.5,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: _lightSecondary),
      primaryIconTheme: const IconThemeData(color: Colors.white),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      
      // Set default font family for the entire app
      fontFamily: _fontFamily,
      
      // Color Scheme - This replaces deprecated backgroundColor
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        background: _darkBackground,
        onBackground: _darkOnBackground,
        onSurface: _darkOnSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
      ),

      // Text Theme - Using .SF UI Text font family
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        displayMedium: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        displaySmall: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        headlineLarge: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        headlineMedium: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        headlineSmall: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        titleLarge: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        bodyMedium: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground),
        bodySmall: TextStyle(fontFamily: _fontFamily, color: _darkSecondary),
        labelLarge: TextStyle(fontFamily: _fontFamily, color: _darkOnBackground, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: _fontFamily, color: _darkSecondary),
        labelSmall: TextStyle(fontFamily: _fontFamily, color: _darkSecondary),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _darkBackground,
        foregroundColor: _darkOnBackground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: _darkOnBackground,
          fontFamily: _fontFamily,
        ),
        iconTheme: IconThemeData(color: _darkPrimary),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: _darkSecondary, fontFamily: _fontFamily),
        hintStyle: const TextStyle(color: _darkSecondary, fontFamily: _fontFamily),
        helperStyle: const TextStyle(color: _darkSecondary, fontFamily: _fontFamily),
        errorStyle: const TextStyle(color: Colors.redAccent, fontFamily: _fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _darkSecondary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _darkSecondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _darkPrimary,
        unselectedItemColor: _darkSecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: _fontFamily),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontFamily: _fontFamily),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: _darkSecondary.withOpacity(0.3),
        thickness: 0.5,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: _darkSecondary),
      primaryIconTheme: const IconThemeData(color: Colors.black),
    );
  }

  // Helper methods for custom colors that adapt to theme
  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF1C1C1E) 
        : Colors.white;
  }

  static Color getSettingsBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF000000) 
        : const Color(0xFFF2F2F7);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF8E8E93) 
        : const Color(0xFF8E8E93);
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF38383A) 
        : const Color(0xFFC6C6C8);
  }
}