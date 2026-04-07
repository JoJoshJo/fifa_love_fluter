import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: TurfArdorColors.deepBackground,
    colorScheme: const ColorScheme.dark(
      primary:   TurfArdorColors.emeraldSpring,
      secondary: TurfArdorColors.gold,
      surface:   TurfArdorColors.cardSurface,
      error:     TurfArdorColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: TurfArdorColors.textPrimary,
        letterSpacing: 1.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: TurfArdorColors.textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: TurfArdorColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: TurfArdorColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: TurfArdorColors.textMuted,
      ),
      labelSmall: GoogleFonts.spaceMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        color: TurfArdorColors.textMuted,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TurfArdorColors.emeraldForest,
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
      fillColor: TurfArdorColors.inputSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: TurfArdorColors.emeraldSpring,
          width: 1.5,
        ),
      ),
      hintStyle: GoogleFonts.inter(
        color: TurfArdorColors.textMuted,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: TurfArdorColors.cardSurface,
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
      backgroundColor: TurfArdorColors.deepBackground,
      elevation: 0,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: TurfArdorColors.textPrimary,
      ),
    ),
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F0E8),
    colorScheme: const ColorScheme.light(
      primary: TurfArdorColors.emeraldForest,
      secondary: TurfArdorColors.emeraldSpring,
      surface: Colors.white,
      error: TurfArdorColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0D1A13),
        letterSpacing: 1.5,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0D1A13),
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0D1A13),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF0D1A13),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF4A5D55),
      ),
      labelSmall: GoogleFonts.spaceMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        color: const Color(0xFF4A5D55),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TurfArdorColors.emeraldForest,
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
      fillColor: const Color(0xFFEDF2F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: TurfArdorColors.emeraldSpring,
          width: 1.5,
        ),
      ),
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF9BB3AF),
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF4CB572).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF8FAF9),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF0D1A13)),
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0D1A13),
      ),
    ),
  );
}
