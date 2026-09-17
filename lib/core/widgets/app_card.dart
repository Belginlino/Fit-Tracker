import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double borderRadius;
  final Gradient?
      gradient; // Keeping for compatibility but we will rely on NeumorphicContainer
  final NeumorphicStyle style;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(
        20), // Increased default padding for more whitespace
    this.margin,
    this.onTap,
    this.color,
    this.border,
    this.borderRadius = 16,
    this.gradient,
    this.style = NeumorphicStyle.raised,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = NeumorphicContainer(
      padding: padding,
      style: style,
      borderRadius: borderRadius,
      child: child,
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
