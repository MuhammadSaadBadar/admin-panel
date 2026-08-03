import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constants.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: ColorConstants.scaffoldBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        backgroundColor: ColorConstants.appBarBackground,
        foregroundColor: ColorConstants.primary,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.dark(
        primary: ColorConstants.primary,
        secondary: ColorConstants.secondary,
        tertiary: ColorConstants.tertiary,
        surface: ColorConstants.surface,
        error: ColorConstants.error,
        onSurface: ColorConstants.onSurface,
        onSurfaceVariant: ColorConstants.onSurfaceVariant,
        onPrimary: ColorConstants.onPrimary,
        onSecondary: ColorConstants.onSecondary,
        onTertiary: ColorConstants.onTertiary,
        surfaceContainerLow: ColorConstants.surfaceContainerLow,
        surfaceContainerHigh: ColorConstants.surfaceContainerHigh,
        surfaceContainerHighest: ColorConstants.surfaceContainerHighest,
        surfaceVariant: ColorConstants.surfaceVariant,
        errorContainer: ColorConstants.errorContainer,
        onError: ColorConstants.onError,
        onErrorContainer: ColorConstants.onErrorContainer,
        onPrimaryContainer: ColorConstants.onPrimaryContainer,
        onSecondaryContainer: ColorConstants.onSecondaryContainer,
        onTertiaryContainer: ColorConstants.onTertiaryContainer,
        secondaryContainer: ColorConstants.secondaryContainer,
        tertiaryContainer: ColorConstants.tertiaryContainer,
      ),
      useMaterial3: true,
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Times New Roman',
      ),
    );
  }
}
