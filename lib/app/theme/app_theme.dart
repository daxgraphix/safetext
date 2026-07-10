import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppRadius {
  AppRadius._();
  static const double sm = 4;
  static const double base = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 9999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double margin = 20;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(brightness: Brightness.light);
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final scheme = isDark
        ? const ColorScheme.dark(
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkOnSurface,
            onSurfaceVariant: AppColors.darkOnSurfaceVariant,
            primary: AppColors.darkPrimary,
            onPrimary: AppColors.darkOnPrimary,
            secondary: AppColors.darkSecondary,
            onSecondary: AppColors.darkOnSecondary,
            tertiary: AppColors.darkTertiary,
            onTertiary: AppColors.darkOnTertiary,
            error: AppColors.darkError,
            onError: AppColors.darkOnError,
            outline: AppColors.darkOutline,
            outlineVariant: AppColors.darkOutlineVariant,
          )
        : const ColorScheme.light(
            surface: AppColors.lightSurface,
            onSurface: AppColors.lightOnSurface,
            onSurfaceVariant: AppColors.lightOnSurfaceVariant,
            primary: AppColors.lightPrimary,
            onPrimary: AppColors.lightOnPrimary,
            secondary: AppColors.lightSecondary,
            onSecondary: AppColors.lightOnSecondary,
            tertiary: AppColors.lightTertiary,
            onTertiary: AppColors.lightOnTertiary,
            error: AppColors.lightError,
            onError: AppColors.lightOnError,
            outline: AppColors.lightOutline,
            outlineVariant: AppColors.lightOutlineVariant,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      fontFamily: 'Roboto Mono',
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: scheme.outline, width: 2)),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          fontFamily: 'Roboto Mono',
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: scheme.outline, width: 2),
        ),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontFamily: 'Roboto Mono',
            letterSpacing: 0.5,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: scheme.outline, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: BorderSide(color: scheme.outline, width: 2),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto Mono',
            letterSpacing: 1.5,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.outline, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: 'Roboto Mono', fontWeight: FontWeight.bold),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.5), fontFamily: 'Roboto Mono'),
      ),
    );
  }
}
