import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand color palette (Spotify-inspired dark aesthetic)
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF172033);
  static const Color border = Color(0xFF334155);

  static const Color primary = Color(0xFF10B981); // Emerald accent
  static const Color secondary = Color(0xFF3B82F6); // Electric Blue
  static const Color warning = Color(0xFFF59E0B); // Amber / Price
  static const Color danger = Color(0xFFEF4444); // Error / Clear

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceElevated,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerColor: border,
    );
  }
}
