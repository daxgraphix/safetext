import 'package:flutter/material.dart';

/// The app uses a strict color palette: Red, Black, Green, and White.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color red = Color(0xFFD32F2F); // High visibility red
  static const Color green = Color(0xFF2E7D32); // High visibility green

  // Light Theme (Default)
  static const Color lightSurface = white;
  static const Color lightOnSurface = black;
  static const Color lightOnSurfaceVariant = Color(0xFF616161); // Darker gray for better contrast
  static const Color lightOutline = black;
  static const Color lightOutlineVariant = Color(0xFFEEEEEE);

  static const Color lightPrimary = black;
  static const Color lightOnPrimary = white;
  
  static const Color lightSecondary = green;
  static const Color lightOnSecondary = white;

  static const Color lightTertiary = red;
  static const Color lightOnTertiary = white;

  static const Color lightError = red;
  static const Color lightOnError = white;

  // Dark Theme
  static const Color darkSurface = black;
  static const Color darkOnSurface = white;
  static const Color darkOnSurfaceVariant = Color(0xFFBDBDBD);
  static const Color darkOutline = white;
  static const Color darkOutlineVariant = Color(0xFF212121); // Darker for brutalist depth

  static const Color darkPrimary = white;
  static const Color darkOnPrimary = black;
  
  static const Color darkSecondary = green; // Unified green for brutalism
  static const Color darkOnSecondary = white;

  static const Color darkTertiary = red; // Unified red for brutalism
  static const Color darkOnTertiary = white;

  static const Color darkError = red;
  static const Color darkOnError = white;
}
