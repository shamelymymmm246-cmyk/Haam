import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 48 / 40,
            letterSpacing: -0.02 * 40,
            color: AppColors.onSurface,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 40 / 32,
            letterSpacing: -0.01 * 32,
            color: AppColors.onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 32 / 24,
            color: AppColors.onSurface,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 28 / 20,
            color: AppColors.onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 30 / 20,
            color: AppColors.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 24 / 17,
            color: AppColors.onSurfaceVariant,
          ),
          bodySmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 22 / 14,
            color: AppColors.onSurfaceVariant,
          ),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 20 / 15,
            color: AppColors.onSurface,
          ),
          labelMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 18 / 13,
            color: AppColors.onSurface,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 16 / 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,

      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        outline: AppColors.outline,
        surfaceTint: AppColors.surfaceTint,
        inversePrimary: AppColors.inversePrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x14FFFFFF),
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
