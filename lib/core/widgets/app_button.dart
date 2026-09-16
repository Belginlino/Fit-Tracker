import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum AppButtonType { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: _getTextColor(),
                ),
              ),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: _getBorder(),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (onPressed == null) return AppColors.surface;
    switch (type) {
      case AppButtonType.primary:
        return AppColors.primary;
      case AppButtonType.secondary:
        return AppColors.cardElevated;
      case AppButtonType.outline:
        return Colors.transparent;
      case AppButtonType.danger:
        return AppColors.error.withOpacity(0.15);
    }
  }

  Color _getTextColor() {
    if (onPressed == null) return AppColors.textMuted;
    switch (type) {
      case AppButtonType.primary:
        return Colors.black;
      case AppButtonType.secondary:
        return AppColors.textPrimary;
      case AppButtonType.outline:
        return AppColors.textPrimary;
      case AppButtonType.danger:
        return AppColors.error;
    }
  }

  Border? _getBorder() {
    if (type == AppButtonType.outline) {
      return Border.all(color: AppColors.border, width: 1.2);
    }
    if (type == AppButtonType.danger) {
      return Border.all(color: AppColors.error.withOpacity(0.4), width: 1);
    }
    return null;
  }
}
