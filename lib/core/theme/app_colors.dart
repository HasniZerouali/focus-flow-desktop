import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Palette (Default & Recommended for focus)
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color darkSurfaceCard = Color(0xFF172033);
  static const Color darkBorder = Color(0xFF2E3D52);
  static const Color darkBorderSubtle = Color(0xFF1F2A3D);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEDF2F7);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Accents & Functional Colors
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryContainer = Color(0xFF312E81);

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successContainer = Color(0xFF064E3B);

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningContainer = Color(0xFF78350F);

  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color dangerContainer = Color(0xFF7F1D1D);

  static const Color info = Color(0xFF0EA5E9); // Sky 500

  // Category Presets
  static const Map<String, Color> categoryColors = {
    'Development': Color(0xFF6366F1),
    'Study': Color(0xFF8B5CF6),
    'Reading': Color(0xFFEC4899),
    'Writing': Color(0xFFF97316),
    'Research': Color(0xFF06B6D4),
    'Exercise': Color(0xFF10B981),
    'Personal': Color(0xFF14B8A6),
    'Other': Color(0xFF64748B),
  };

  static Color getCategoryColor(String categoryName) {
    return categoryColors[categoryName] ?? const Color(0xFF6366F1);
  }
}
