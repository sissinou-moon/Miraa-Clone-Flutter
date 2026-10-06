import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Miraa brand colors
  static const Color primaryGreen = Color(0xFF4C6A4B);
  static const Color primaryGreenDark = Color(0xFF385137);
  static const Color softGreen = Color(0xFFD6ECC7);
  static const Color brightGreen = Color(0xFFAFE08B);

  static const Color bgCream = Color(0xFFF9F8F3);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color cardCream = Color(0xFFF5F4EC);
  static const Color cardCreamBorder = Color(0xFFEBE9DD);

  static const Color textDark = Color(0xFF1F2421);
  static const Color textMuted = Color(0xFF717770);
  static const Color textLight = Color(0xFF9EA39D);

  // Word tag pastel highlights like in Miraa
  static const List<Color> pastelWordColors = [
    Color(0xFFFEF3C7), // warm amber/yellow
    Color(0xFFE0F2FE), // soft sky blue
    Color(0xFFFCE7F3), // light pink/rose
    Color(0xFFDCFCE7), // mint green
    Color(0xFFEDE9FE), // soft lavender
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: softGreen,
        surface: bgWhite,
        surfaceContainerHighest: cardCream,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCream,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textDark),
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: Color(0xFFD7DCD5),
        thumbColor: primaryGreen,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 4,
        overlayColor: Color(0x294C6A4B),
      ),
    );
  }
}
