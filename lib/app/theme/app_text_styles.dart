import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale from `DESIGN.md`. Inter is used exclusively across the
/// app for its legibility in data-dense, security-focused screens.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  static TextStyle get displaySm => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 44 / 36,
        letterSpacing: -0.02 * 36,
      );

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
      );

  static TextStyle get titleLg => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 14 / 10,
        letterSpacing: 0.05 * 10,
      );

  static TextStyle get mono => GoogleFonts.robotoMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.01 * 14,
      );
}
