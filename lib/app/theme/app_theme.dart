import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'NeoDGM',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE7C46A),
        secondary: Color(0xFF5FD1B7),
        surface: Color(0xFF162019),
        onPrimary: Color(0xFF1A1F1B),
        onSecondary: Color(0xFF0B1512),
        onSurface: Color(0xFFEFF4EE),
      ),
      scaffoldBackgroundColor: const Color(0xFF0E1411),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 46, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFFEFF4EE),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE7C46A),
          foregroundColor: const Color(0xFF1A1F1B),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEFF4EE),
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
