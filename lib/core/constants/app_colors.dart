import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFF8B7CF7);
  static const primaryDark = Color(0xFF5A4BD1);

  // Accent
  static const accent = Color(0xFF00D2FF);
  static const accentLight = Color(0xFF4DE0FF);

  // Gradient
  static const gradientStart = Color(0xFF6C5CE7);
  static const gradientEnd = Color(0xFF00D2FF);
  static const primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background
  static const backgroundDark = Color(0xFF0D0D0D);
  static const surfaceDark = Color(0xFF1A1A2E);
  static const cardDark = Color(0xFF16213E);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textTertiary = Color(0xFF6C6C6C);

  // Status
  static const success = Color(0xFF00E676);
  static const error = Color(0xFFFF5252);
  static const warning = Color(0xFFFFD740);
  static const info = Color(0xFF448AFF);

  // Pro badge
  static const proBadge = Color(0xFFFFD700);
  static const proBadgeGradientStart = Color(0xFFFFD700);
  static const proBadgeGradientEnd = Color(0xFFFFA000);
}
