import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors_extension.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final AppColorsExtension darkColors = const AppColorsExtension(
    questBlue: AppColors.questBlue,
    midnightSlate: AppColors.midnightSlate,
    surface: AppColors.surface,
    background: AppColors.background,
    card: AppColors.card,
    border: AppColors.border,
    auroraPurple: AppColors.auroraPurple,
    emerald: AppColors.emerald,
    amber: AppColors.amber,
    crimson: AppColors.crimson,
    skyBlue: AppColors.skyBlue,
    gold: AppColors.gold,
    textPrimary: AppColors.textPrimary,
    textPrimary87: AppColors.textPrimary87,
    textPrimary70: AppColors.textPrimary70,
    textPrimary54: AppColors.textPrimary54,
    textPrimary38: AppColors.textPrimary38,
    textPrimary24: AppColors.textPrimary24,
    textPrimary12: AppColors.textPrimary12,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    background87: AppColors.background87,
    background54: AppColors.background54,
    background45: AppColors.background45,
  );

  static final AppColorsExtension lightColors = const AppColorsExtension(
    questBlue: Color(0xFF2563EB), // Same quest blue
    midnightSlate: Color(0xFFF1F5F9), // Slate 100 for light mode midnight Slate
    surface: Color(0xFFFFFFFF), // White surface
    background: Color(0xFFF8FAFC), // Slate 50 background
    card: Color(0xFFFFFFFF), // White cards
    border: Color(0xFFE2E8F0), // Slate 200 borders
    auroraPurple: Color(0xFF8B5CF6), // Slightly brighter purple
    emerald: Color(0xFF10B981),
    amber: Color(0xFFF59E0B),
    crimson: Color(0xFFEF4444),
    skyBlue: Color(0xFF0EA5E9),
    gold: Color(0xFFF59E0B),
    textPrimary: Color(0xFF0F172A), // Slate 900
    textPrimary87: Color(0xDE0F172A),
    textPrimary70: Color(0xB30F172A),
    textPrimary54: Color(0x8A0F172A),
    textPrimary38: Color(0x610F172A),
    textPrimary24: Color(0x3D0F172A),
    textPrimary12: Color(0x1E0F172A),
    textSecondary: Color(0xFF475569), // Slate 600
    textMuted: Color(0xFF64748B), // Slate 500
    background87: Color(0xDEF8FAFC),
    background54: Color(0x8AF8FAFC),
    background45: Color(0x73F8FAFC),
  );

  static ThemeData get dark {
    return _buildTheme(Brightness.dark, darkColors);
  }

  static ThemeData get light {
    return _buildTheme(Brightness.light, lightColors);
  }

  static ThemeData _buildTheme(Brightness brightness, AppColorsExtension colors) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.questBlue,
        onPrimary: Colors.white,
        secondary: colors.auroraPurple,
        onSecondary: Colors.white,
        error: colors.crimson,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.border,
      ),
      extensions: [colors],
      textTheme: GoogleFonts.interTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.questBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.questBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.crimson),
        ),
        hintStyle: TextStyle(color: colors.textMuted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.questBlue,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
    );
  }
}
