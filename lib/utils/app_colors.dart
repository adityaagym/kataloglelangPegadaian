import 'package:flutter/material.dart';

class AppColors {
  // Primary - Pegadaian Green
  static const Color primary = Color(0xFF008444);
  static const Color primaryDark = Color(0xFF006633);
  static const Color primaryLight = Color(0xFF00A656);

  // Gold / Accent
  static const Color gold = Color(0xFFC69D24);
  static const Color goldLight = Color(0xFFE2B93B);
  static const Color goldBg = Color(0xFFFFF8E7);

  // Greens for UI
  static const Color accentLight = Color(0xFFE2F4E9);
  static const Color accentLighter = Color(0xFFF0F9F3);
  static const Color successGreen = Color(0xFF12B76A);

  // Background
  static const Color background = Color(0xFFF2F4F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE4E7EC);

  // Text
  static const Color textDark = Color(0xFF1D2939);
  static const Color textPrimary = Color(0xFF344054);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF98A2B3);

  // Status
  static const Color error = Color(0xFFD92D20);
  static const Color warning = Color(0xFFF79009);
  static const Color info = Color(0xFF2E90FA);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF006633),
      Color(0xFF008444),
      Color(0xFF00A656),
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF008444),
      Color(0xFF00A656),
    ],
  );
}
