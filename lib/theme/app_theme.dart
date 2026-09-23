import 'package:flutter/material.dart';

/// Generation X Color Palette (Picture 2)
class GenXPalette {
  // DC-001: Warm soft ivory white / cream background
  static const Color whippedCream = Color(0xFFF7F5EE);

  // MQ3-32: Pale crisp gray-white for borders, input fields, subtle cards
  static const Color cameoWhite = Color(0xFFE5E7E2);

  // N400-7: Rich deep forest vine leaf green for success badges, available pills, accents
  static const Color vineLeaf = Color(0xFF3B4D3C);

  // N480-7: Deep slate midnight blue for primary buttons, prominent typography, brand
  static const Color midnightBlue = Color(0xFF38454D);

  // Text & Status Palette
  static const Color textDark = Color(0xFF1E2830);
  static const Color textMuted = Color(0xFF6B7680);
  static const Color cardBg = Colors.white;
  static const Color inputBg = Color(0xFFF4F5F2);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: GenXPalette.whippedCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GenXPalette.midnightBlue,
        primary: GenXPalette.midnightBlue,
        secondary: GenXPalette.vineLeaf,
        surface: GenXPalette.cardBg,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: GenXPalette.whippedCream,
        foregroundColor: GenXPalette.midnightBlue,
        titleTextStyle: TextStyle(
          color: GenXPalette.midnightBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: GenXPalette.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: GenXPalette.cameoWhite, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GenXPalette.midnightBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GenXPalette.cameoWhite, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GenXPalette.cameoWhite, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GenXPalette.midnightBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GenXPalette.danger, width: 1.2),
        ),
        hintStyle: const TextStyle(color: GenXPalette.textMuted, fontSize: 14),
      ),
    );
  }
}
