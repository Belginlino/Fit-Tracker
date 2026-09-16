import 'package:flutter/material.dart';

/// Centralized color tokens for FitTrack.
/// Built with a sleek, high-contrast dark aesthetic for premium fitness apps.
class AppColors {
  AppColors._();

  // Dark Theme Backgrounds & Surfaces
  static const Color background = Color(0xFF090B10);
  static const Color surface = Color(0xFF131722);
  static const Color card = Color(0xFF1B2030);
  static const Color cardElevated = Color(0xFF242B40);

  // Vibrant Athletic Accents
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryDark = Color(0xFF00B4CC);
  static const Color accentLime = Color(0xFF39FF14); // High-voltage Green/Lime
  static const Color accentOrange = Color(0xFFFF5722); // Energy Coral
  static const Color accentAmber = Color(0xFFFFB300); // Streak Gold

  // Feedback & Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Typography & Content Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color divider = Color(0xFF262E44);
  static const Color border = Color(0xFF333D56);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF39FF14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1B2030), Color(0xFF151926)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
