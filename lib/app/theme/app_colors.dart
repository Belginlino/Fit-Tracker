import 'package:flutter/material.dart';

/// Centralized color tokens for FitTrack.
/// Built with a premium soft-neumorphic fitness aesthetic.
class AppColors {
  AppColors._();

  // Neumorphic Backgrounds & Surfaces
  static const Color background = Color(0xFFF7F3E8);
  static const Color surface = Color(0xFFEEE8DC);
  static const Color card =
      Color(0xFFEEE8DC); // Same as surface for flat neumorphism
  static const Color cardBackground = Color(0xFFEEE8DC);

  // Shadows
  static const Color shadow = Color(0xFFD1C7B7);
  static const Color deepShadow = Color(0xFFC4B9A8);
  static const Color highlight = Color(0xFFFFFFFF); // For upper-left highlights

  // Vibrant Athletic Accents (Teal)
  static const Color primary = Color(0xFF0D5B5B);
  static const Color secondary = Color(0xFF0F3D3D);
  static const Color lightTeal = Color(0xFFDCEBE7);

  // Status & Accent
  static const Color accentLime =
      Color(0xFF0D5B5B); // Map previous lime usages to primary teal
  static const Color accentOrange =
      Color(0xFF0F3D3D); // Map previous orange to secondary teal
  static const Color accentAmber =
      Color(0xFFDCEBE7); // Map previous gold to light teal

  // Feedback & Status
  static const Color success = Color(0xFF0D6B63);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0D5B5B);

  // Typography & Content Colors
  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF65625C);
  static const Color textMuted = Color(0xFF89847A);
  static const Color divider =
      Color(0xFFD1C7B7); // Use shadow color for dividers
  static const Color border = Color(0xFFC4B9A8); // Use deep shadow for borders

  // Preserve Gradients structurally but use new colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D5B5B), Color(0xFF0F3D3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFF0F3D3D), Color(0xFF0D5B5B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFEEE8DC), Color(0xFFF7F3E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
