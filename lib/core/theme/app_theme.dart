import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FifaColors.deepBackground,
    colorScheme: const ColorScheme.dark(
      primary:   FifaColors.emeraldSpring,
      secondary: FifaColors.gold,
      surface:   FifaColors.cardSurface,
      error:     FifaColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: FifaColors.textPrimary,
        letterSpacing: 1.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: FifaColors.textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: FifaColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: FifaColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: FifaColors.textMuted,
      ),
      labelSmall: GoogleFonts.spaceMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        color: FifaColors.textMuted,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FifaColors.emeraldForest,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FifaColors.inputSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: FifaColors.emeraldSpring,
          width: 1.5,
        ),
      ),
      hintStyle: GoogleFonts.inter(
        color: FifaColors.textMuted,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: FifaColors.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFF1E4A33),
          width: 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FifaColors.deepBackground,
      elevation: 0,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: FifaColors.textPrimary,
      ),
    ),
  );
}
