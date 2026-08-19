import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constants.dart';

class AppTheme {
  // ===========================================================================
  // LIGHT THEME — ACTIVE / PRIMARY APP THEME
  // ===========================================================================

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: ColorConstants.scaffoldBackground,

      colorScheme: const ColorScheme.light(
        primary: ColorConstants.primary,
        onPrimary: ColorConstants.onPrimary,
        primaryContainer: ColorConstants.primaryContainer,
        onPrimaryContainer: ColorConstants.onPrimaryContainer,

        secondary: ColorConstants.secondary,
        onSecondary: ColorConstants.onSecondary,
        secondaryContainer: ColorConstants.secondaryContainer,
        onSecondaryContainer: ColorConstants.onSecondaryContainer,

        tertiary: ColorConstants.tertiary,
        onTertiary: ColorConstants.onTertiary,
        tertiaryContainer: ColorConstants.tertiaryContainer,
        onTertiaryContainer: ColorConstants.onTertiaryContainer,

        surface: ColorConstants.surface,

        onSurface: ColorConstants.onSurface,
        onSurfaceVariant: ColorConstants.onSurfaceVariant,

        surfaceContainerLowest: ColorConstants.surfaceContainerLowest,
        surfaceContainerLow: ColorConstants.surfaceContainerLow,
        surfaceContainer: ColorConstants.surfaceContainer,
        surfaceContainerHigh: ColorConstants.surfaceContainerHigh,
        surfaceContainerHighest: ColorConstants.surfaceContainerHighest,

        error: ColorConstants.error,
        onError: ColorConstants.onError,
        errorContainer: ColorConstants.errorContainer,
        onErrorContainer: ColorConstants.onErrorContainer,

        outline: ColorConstants.adminOutline,
        outlineVariant: ColorConstants.adminOutlineVariant,
      ),

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        backgroundColor: ColorConstants.appBarBackground,
        foregroundColor: ColorConstants.onSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // -----------------------------------------------------------------------
      // CARD
      // -----------------------------------------------------------------------
      cardTheme: CardThemeData(
        color: ColorConstants.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ColorConstants.border, width: 1),
        ),
      ),

      // -----------------------------------------------------------------------
      // INPUT FIELDS
      // -----------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColorConstants.primary,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.error, width: 1.5),
        ),

        labelStyle: const TextStyle(color: ColorConstants.textMuted),

        hintStyle: const TextStyle(color: ColorConstants.textFaint),

        prefixIconColor: ColorConstants.textMuted,
        suffixIconColor: ColorConstants.textMuted,
      ),

      // -----------------------------------------------------------------------
      // ELEVATED BUTTON
      // -----------------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: ColorConstants.primary,
          foregroundColor: ColorConstants.onPrimary,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // OUTLINED BUTTON
      // -----------------------------------------------------------------------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          side: const BorderSide(color: ColorConstants.primary),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // TEXT BUTTON
      // -----------------------------------------------------------------------
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorConstants.primary,

          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // DIVIDER
      // -----------------------------------------------------------------------
      dividerTheme: const DividerThemeData(
        color: ColorConstants.divider,
        thickness: 1,
        space: 1,
      ),

      // -----------------------------------------------------------------------
      // CHIP
      // -----------------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: ColorConstants.surfaceContainerLow,
        selectedColor: ColorConstants.primaryContainer,
        disabledColor: ColorConstants.surfaceContainerHigh,

        side: const BorderSide(color: ColorConstants.border),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        labelStyle: GoogleFonts.inter(
          color: ColorConstants.textMain,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),

        secondaryLabelStyle: GoogleFonts.inter(
          color: ColorConstants.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // -----------------------------------------------------------------------
      // SWITCH
      // -----------------------------------------------------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorConstants.primary;
          }

          return ColorConstants.textFaint;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorConstants.primaryContainer;
          }

          return ColorConstants.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(ColorConstants.border),
      ),

      // -----------------------------------------------------------------------
      // PROGRESS INDICATOR
      // -----------------------------------------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColorConstants.primary,
        linearTrackColor: ColorConstants.primaryContainer,
        circularTrackColor: ColorConstants.surfaceContainerHigh,
      ),

      // -----------------------------------------------------------------------
      // ICON
      // -----------------------------------------------------------------------
      iconTheme: const IconThemeData(
        color: ColorConstants.onSurfaceVariant,
        size: 24,
      ),

      // -----------------------------------------------------------------------
      // TEXT THEME
      // -----------------------------------------------------------------------
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: ColorConstants.textMain,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: ColorConstants.textMain,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: ColorConstants.textMain,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: ColorConstants.textMain,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: ColorConstants.textMain,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: ColorConstants.textMain,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: ColorConstants.textMain,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: ColorConstants.textMain,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: ColorConstants.textMuted,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: ColorConstants.textMain,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: ColorConstants.textMain,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: ColorConstants.textMuted,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: ColorConstants.textMain,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          color: ColorConstants.textMuted,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: ColorConstants.textFaint,
        ),
      ),
    );
  }

  // ===========================================================================
  // DARK THEME — PRESERVED
  // ===========================================================================

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      useMaterial3: true,

      scaffoldBackgroundColor: ColorConstants.darkThemeBackground,

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        backgroundColor: ColorConstants.darkThemeBackground,
        foregroundColor: ColorConstants.darkThemeOnSurface,
        surfaceTintColor: Colors.transparent,
      ),

      colorScheme: const ColorScheme.dark(
        primary: ColorConstants.darkThemePrimary,
        onPrimary: ColorConstants.darkThemeOnPrimary,
        primaryContainer: ColorConstants.darkThemePrimaryContainer,
        onPrimaryContainer: ColorConstants.darkThemeOnPrimaryContainer,

        secondary: ColorConstants.darkThemeSecondary,
        onSecondary: ColorConstants.darkThemeOnSecondary,
        secondaryContainer: ColorConstants.darkThemeSecondaryContainer,
        onSecondaryContainer: ColorConstants.darkThemeOnSecondaryContainer,

        tertiary: ColorConstants.darkThemeTertiary,
        onTertiary: ColorConstants.darkThemeOnTertiary,
        tertiaryContainer: ColorConstants.darkThemeTertiaryContainer,
        onTertiaryContainer: ColorConstants.darkThemeOnTertiaryContainer,

        surface: ColorConstants.darkThemeSurface,
        onSurface: ColorConstants.darkThemeOnSurface,
        onSurfaceVariant: ColorConstants.darkThemeOnSurfaceVariant,

        surfaceContainerLow: ColorConstants.darkThemeSurfaceLow,
        surfaceContainerHigh: ColorConstants.darkThemeSurfaceHigh,
        surfaceContainerHighest: ColorConstants.darkThemeSurfaceHighest,

        error: ColorConstants.darkThemeError,
        onError: ColorConstants.darkThemeOnError,
        errorContainer: ColorConstants.darkThemeErrorContainer,
        onErrorContainer: ColorConstants.darkThemeOnErrorContainer,
      ),

      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
