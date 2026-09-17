import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';

enum NeumorphicStyle { flat, raised, inset }

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final NeumorphicStyle style;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxShape shape;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.style = NeumorphicStyle.raised,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    List<BoxShadow>? shadows;
    LinearGradient? gradient;

    if (style == NeumorphicStyle.raised) {
      shadows = AppShadows.raised;
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFBF8F1), // Lighter cream
          AppColors.surface, // Base surface
        ],
      );
    } else if (style == NeumorphicStyle.inset) {
      // Fake inset by using an inverse gradient and dark borders if needed
      // Pure CSS-like inset shadow is hard in Flutter without custom painting,
      // but an inverted linear gradient gives a pressed feel.
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE4DECF), // Darker surface
          Color(0xFFF7F3E8), // Lighter
        ],
      );
      // We can also add a subtle inner border effect
    } else {
      gradient = const LinearGradient(
        colors: [AppColors.surface, AppColors.surface],
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
        shape: shape,
        boxShadow: shadows,
        gradient: gradient,
        border: style == NeumorphicStyle.inset
            ? Border.all(
                color: AppColors.shadow.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: child,
    );
  }
}
