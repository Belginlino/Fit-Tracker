import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Predefined shadow styles for the neumorphic design system.
class AppShadows {
  AppShadows._();

  /// Soft outer shadow for elevated elements (cards, primary buttons)
  static final List<BoxShadow> raised = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.8),
      offset: const Offset(4, 4),
      blurRadius: 10,
      spreadRadius: 1,
    ),
    const BoxShadow(
      color: AppColors.highlight,
      offset: Offset(-4, -4),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  /// Subtle outer shadow for smaller elevated elements
  static final List<BoxShadow> raisedSmall = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.8),
      offset: const Offset(2, 2),
      blurRadius: 5,
      spreadRadius: 0.5,
    ),
    const BoxShadow(
      color: AppColors.highlight,
      offset: Offset(-2, -2),
      blurRadius: 5,
      spreadRadius: 0.5,
    ),
  ];

  /// Deep shadow for floating components like toasts or dialogs
  static final List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.deepShadow.withValues(alpha: 0.6),
      offset: const Offset(0, 8),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  // Note: For 'inset' shadows, Flutter's BoxShadow doesn't natively support inset.
  // We will build a NeumorphicContainer widget that simulates inset using gradients
  // or inner shadows using inner_shadow packages, but typically in pure Flutter we
  // achieve inset by drawing an inner border or using a gradient that reverses the light.
}
