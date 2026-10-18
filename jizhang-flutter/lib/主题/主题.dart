import 'package:flutter/material.dart';

import '令牌.dart';

ThemeData buildAppTheme() {
  const tokens = AppTokens.light;
  final scheme = ColorScheme.light(
    primary: tokens.primary,
    onPrimary: Colors.white,
    primaryContainer: tokens.primaryLight,
    onPrimaryContainer: tokens.primary,
    secondary: tokens.primaryHover,
    onSecondary: Colors.white,
    error: tokens.expense,
    onError: Colors.white,
    surface: tokens.bg,
    onSurface: tokens.textPrimary,
    surfaceContainerHighest: tokens.surface2,
    outline: tokens.border,
    outlineVariant: tokens.divider,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.bg,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    fontFamily: null,
  );

  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[tokens],
    textTheme: base.textTheme.copyWith(
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: tokens.textPrimary),
      bodyMedium: TextStyle(fontSize: 13, color: tokens.textSecondary),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tokens.textSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bg,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: tokens.bg,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        side: BorderSide(color: tokens.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.primary,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.bg,
      modalBackgroundColor: tokens.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusXl),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
    ),
  );
}
