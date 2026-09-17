import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'neumorphic_container.dart';

enum AppButtonType { primary, secondary, outline, danger }

class AppButton extends StatefulWidget {
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
    this.height = 56, // Slightly taller for premium feel
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final Widget child = widget.isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: _getTextColor()),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: _getTextColor(),
                ),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: NeumorphicContainer(
          style: _getNeumorphicStyle(),
          borderRadius: 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: _getBorder(),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  NeumorphicStyle _getNeumorphicStyle() {
    if (widget.type == AppButtonType.outline ||
        widget.type == AppButtonType.danger) {
      return NeumorphicStyle.flat;
    }
    if (_isPressed) {
      return NeumorphicStyle.inset;
    }
    return NeumorphicStyle.raised;
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null && !widget.isLoading) return AppColors.surface;
    switch (widget.type) {
      case AppButtonType.primary:
        return AppColors.primary;
      case AppButtonType.secondary:
        return AppColors.surface; // Will use Neumorphic surface
      case AppButtonType.outline:
        return Colors.transparent;
      case AppButtonType.danger:
        return AppColors.error.withValues(alpha: 0.15);
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null && !widget.isLoading) {
      return AppColors.textMuted;
    }
    switch (widget.type) {
      case AppButtonType.primary:
        return Colors.white;
      case AppButtonType.secondary:
        return AppColors.primary;
      case AppButtonType.outline:
        return AppColors.primary;
      case AppButtonType.danger:
        return AppColors.error;
    }
  }

  Border? _getBorder() {
    if (widget.type == AppButtonType.outline) {
      return Border.all(color: AppColors.primary, width: 1.5);
    }
    if (widget.type == AppButtonType.danger) {
      return Border.all(
          color: AppColors.error.withValues(alpha: 0.4), width: 1);
    }
    return null;
  }
}
