import 'package:flutter/material.dart';

class AppColors {
  // Primary - Pegadaian React theme
  static const Color primary = Color(0xFF00AA13);
  static const Color primaryDark = Color(0xFF006838);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color secondary = Color(0xFFE8F5E9);
  static const Color accent = Color(0xFFF9A825);

  // Gold / Accent
  static const Color gold = Color(0xFFF9A825);
  static const Color goldLight = Color(0xFFFFD95A);
  static const Color goldBg = Color(0xFFFFF8E1);

  // Greens for UI
  static const Color accentLight = Color(0xFFE8F5E9);
  static const Color accentLighter = Color(0xFFF1F8F1);
  static const Color successGreen = Color(0xFF1B5E20);

  // Background
  static const Color background = Color(0xFFE8F5E9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color muted = Color(0xFFF9FAFB);

  // Text
  static const Color textDark = Color(0xFF212121);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textMuted = Color(0xFF9E9E9E);

  // Status
  static const Color error = Color(0xFFB71C1C);
  static const Color destructive = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFF79009);
  static const Color info = Color(0xFF2E90FA);

  // Category badges
  static const Color categoryGreenBg = Color(0xFFE8F5E9);
  static const Color categoryGreenText = Color(0xFF1B5E20);
  static const Color categoryBlueBg = Color(0xFFE3F2FD);
  static const Color categoryBlueText = Color(0xFF0D47A1);
  static const Color categoryAmberBg = Color(0xFFFFF8E1);
  static const Color categoryAmberText = Color(0xFF8A5A00);
  static const Color categoryPurpleBg = Color(0xFFF3E5F5);
  static const Color categoryPurpleText = Color(0xFF6A1B9A);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF006838), Color(0xFF00AA13), Color(0xFFE8F5E9)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF006838), Color(0xFF00AA13)],
  );

  static Color categoryBadgeBg(String? category) {
    final name = (category ?? '').toLowerCase();
    if (name.contains('perhiasan') || (name.contains('emas') && !name.contains('logam'))) {
      // Perhiasan Emas - amber
      return const Color(0xFFFEF3C7);
    }
    if (name.contains('logam')) {
      // Logam Mulia - slate
      return const Color(0xFFE2E8F0);
    }
    if (name.contains('elektronik')) {
      // Elektronik - indigo
      return const Color(0xFFEDE9FE);
    }
    if (name.contains('kendaraan')) {
      // Kendaraan - dark blue
      return const Color(0xFFDBEAFE);
    }
    return const Color(0xFFF3F4F6);
  }

  static Color categoryBadgeText(String? category) {
    final name = (category ?? '').toLowerCase();
    if (name.contains('perhiasan') || (name.contains('emas') && !name.contains('logam'))) {
      // Perhiasan Emas - amber
      return const Color(0xFFD97706);
    }
    if (name.contains('logam')) {
      // Logam Mulia - slate
      return const Color(0xFF475569);
    }
    if (name.contains('elektronik')) {
      // Elektronik - indigo
      return const Color(0xFF4338CA);
    }
    if (name.contains('kendaraan')) {
      // Kendaraan - dark blue
      return const Color(0xFF1E3A8A);
    }
    return textSecondary;
  }
}
