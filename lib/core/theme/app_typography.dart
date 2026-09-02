import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get base => GoogleFonts.inter();

  static TextStyle displayLarge(Color color) => GoogleFonts.inter(
        fontSize: 56.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle displayMedium(Color color) => GoogleFonts.inter(
        fontSize: 40.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle displaySmall(Color color) => GoogleFonts.inter(
        fontSize: 32.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headline(Color color) => GoogleFonts.inter(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle title(Color color) => GoogleFonts.inter(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle body(Color color) => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle caption(Color color) => GoogleFonts.inter(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle timerDisplay(Color color) => GoogleFonts.jetBrainsMono(
        fontSize: 72.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: color,
      );

  static TextStyle timerSmall(Color color) => GoogleFonts.jetBrainsMono(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color,
      );
}
