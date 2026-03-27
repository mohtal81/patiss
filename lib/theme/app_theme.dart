// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark palette
  static const bg          = Color(0xFF0F0C17);
  static const surface     = Color(0xFF1A1625);
  static const surface2    = Color(0xFF231D35);
  static const card        = Color(0xFF1E1830);
  static const border      = Color(0xFF2D2545);

  // Accent
  static const gold        = Color(0xFFD4A017);
  static const goldLight   = Color(0xFFEDBE45);
  static const purple      = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFA78BFA);
  static const green       = Color(0xFF34D399);
  static const red         = Color(0xFFF87171);
  static const orange      = Color(0xFFFB923C);
  static const blue        = Color(0xFF60A5FA);

  // Text
  static const textPrimary   = Color(0xFFF5F0E8);
  static const textSecondary = Color(0xFF9D8FA8);
  static const textMuted     = Color(0xFF665E75);

  // Status
  static const statusEnCours  = Color(0xFFD4A017);
  static const statusTerminee = Color(0xFF34D399);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:    AppColors.gold,
      secondary:  AppColors.purple,
      surface:    AppColors.surface,
      error:      AppColors.red,
      onPrimary:  AppColors.bg,
      onSurface:  AppColors.textPrimary,
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge:  GoogleFonts.playfairDisplay(
        color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.playfairDisplay(
        color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.nunitoSans(
        color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
      headlineMedium:GoogleFonts.nunitoSans(
        color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      bodyLarge:     GoogleFonts.nunitoSans(
        color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      bodyMedium:    GoogleFonts.nunitoSans(
        color: AppColors.textSecondary, fontSize: 13),
      bodySmall:     GoogleFonts.nunitoSans(
        color: AppColors.textMuted, fontSize: 11),
      labelLarge:    GoogleFonts.nunitoSans(
        color: AppColors.bg, fontSize: 14, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      hintStyle: GoogleFonts.nunitoSans(color: AppColors.textMuted, fontSize: 14),
      labelStyle: GoogleFonts.nunitoSans(color: AppColors.textSecondary, fontSize: 13),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: AppColors.border,
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: GoogleFonts.nunitoSans(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.bg,
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface2,
      selectedColor: AppColors.gold.withOpacity(0.25),
      labelStyle: GoogleFonts.nunitoSans(color: AppColors.textSecondary, fontSize: 12),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
