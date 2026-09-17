import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppPhotoImage extends StatelessWidget {
  final String? localPath;
  final String? remoteUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const AppPhotoImage({
    super.key,
    this.localPath,
    this.remoteUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      imageWidget = Image.network(
        remoteUrl!,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildLoading();
        },
        errorBuilder: (context, error, stack) => _fallback(context),
      );
    } else if (localPath != null && localPath!.isNotEmpty) {
      if (kIsWeb ||
          localPath!.startsWith('blob:') ||
          localPath!.startsWith('http')) {
        imageWidget = Image.network(
          localPath!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stack) => _fallback(context),
        );
      } else {
        imageWidget = Image.file(
          File(localPath!),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stack) => _fallback(context),
        );
      }
    } else {
      imageWidget = _fallback(context);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: AppColors.card,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF161B28),
      child: const Center(
        child: Icon(Icons.photo_rounded, size: 32, color: AppColors.textMuted),
      ),
    );
  }
}
