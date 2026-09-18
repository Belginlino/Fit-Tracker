import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/core/appwrite/appwrite_client.dart';
import 'package:fittrack/core/appwrite/appwrite_config.dart';

class AppPhotoImage extends StatefulWidget {
  final String? localPath;
  final String? remoteUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  static void evict(String fileId) {
    _AppPhotoImageState._bytesCache.remove(fileId);
  }

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
  State<AppPhotoImage> createState() => _AppPhotoImageState();
}

class _AppPhotoImageState extends State<AppPhotoImage> {
  static final Map<String, Uint8List> _bytesCache = {};
  static final Map<String, Future<Uint8List?>> _activeFetches = {};

  Uint8List? _loadedBytes;
  bool _isFetchingFallback = false;
  bool _fallbackFailed = false;

  String? _effectiveUrl;
  String? _extractedFileId;

  @override
  void initState() {
    super.initState();
    _resolveUrls();
  }

  @override
  void didUpdateWidget(covariant AppPhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remoteUrl != widget.remoteUrl ||
        oldWidget.localPath != widget.localPath) {
      _resolveUrls();
    }
  }

  void _resolveUrls() {
    String? url = widget.remoteUrl;
    if ((url == null || url.isEmpty) &&
        widget.localPath != null &&
        (widget.localPath!.startsWith('http://') ||
            widget.localPath!.startsWith('https://'))) {
      url = widget.localPath;
    }
    _effectiveUrl = url;

    String? fileId;
    if (_effectiveUrl != null && _effectiveUrl!.isNotEmpty) {
      final match = RegExp(r'/files/([^/]+)/(?:view|preview)')
          .firstMatch(_effectiveUrl!);
      if (match != null) {
        fileId = match.group(1);
      } else if (!_effectiveUrl!.contains('/') && _effectiveUrl!.length >= 15) {
        fileId = _effectiveUrl;
      }
    } else if (widget.localPath != null &&
        !widget.localPath!.contains('/') &&
        !widget.localPath!.contains(r'\') &&
        widget.localPath!.length >= 15) {
      fileId = widget.localPath;
    }
    _extractedFileId = fileId;

    if (_extractedFileId != null &&
        _bytesCache.containsKey(_extractedFileId)) {
      _loadedBytes = _bytesCache[_extractedFileId];
    } else if (_extractedFileId != null &&
        (widget.localPath == null || widget.localPath!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchViaAppwriteSdk();
      });
    }
  }

  Future<void> _fetchViaAppwriteSdk() async {
    if (_extractedFileId == null ||
        _isFetchingFallback ||
        _fallbackFailed ||
        _loadedBytes != null ||
        !mounted) {
      return;
    }

    final fileId = _extractedFileId!;

    if (_bytesCache.containsKey(fileId)) {
      if (mounted) {
        setState(() {
          _loadedBytes = _bytesCache[fileId];
        });
      }
      return;
    }

    setState(() {
      _isFetchingFallback = true;
    });

    try {
      final future = _activeFetches.putIfAbsent(fileId, () async {
        try {
          if (!AppwriteClient.instance.isInitialized) {
            AppwriteClient.instance.init();
          }
          final bytes = await AppwriteClient.instance.storage.getFileView(
            bucketId: AppwriteConfig.photosBucket,
            fileId: fileId,
          );
          _bytesCache[fileId] = bytes;
          return bytes;
        } catch (_) {
          return null;
        } finally {
          _activeFetches.remove(fileId);
        }
      });

      final bytes = await future;
      if (mounted) {
        setState(() {
          _isFetchingFallback = false;
          if (bytes != null) {
            _loadedBytes = bytes;
          } else {
            _fallbackFailed = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetchingFallback = false;
          _fallbackFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // 1. If bytes were already loaded via Appwrite SDK or cache
    if (_loadedBytes != null) {
      imageWidget = Image.memory(
        _loadedBytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stack) => _fallback(context),
      );
    }
    // 2. If SDK fallback fetch is currently in progress
    else if (_isFetchingFallback) {
      imageWidget = _buildLoading();
    }
    // 3. If remote URL is available
    else if (_effectiveUrl != null &&
        _effectiveUrl!.isNotEmpty &&
        !_fallbackFailed) {
      imageWidget = Image.network(
        _effectiveUrl!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildLoading();
        },
        errorBuilder: (context, error, stack) {
          // If network image fails (e.g. 404 unauthorized/CORS), load via Appwrite SDK
          if (_extractedFileId != null && !_fallbackFailed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchViaAppwriteSdk();
            });
            return _buildLoading();
          }
          return _fallback(context);
        },
      );
    }
    // 4. Local file path
    else if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      if (kIsWeb ||
          widget.localPath!.startsWith('blob:') ||
          widget.localPath!.startsWith('http')) {
        imageWidget = Image.network(
          widget.localPath!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stack) => _fallback(context),
        );
      } else {
        final file = File(widget.localPath!);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: (context, error, stack) => _fallback(context),
          );
        } else if (_extractedFileId != null && !_fallbackFailed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchViaAppwriteSdk();
          });
          imageWidget = _buildLoading();
        } else {
          imageWidget = _fallback(context);
        }
      }
    } else {
      imageWidget = _fallback(context);
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoading() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.card,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    if (widget.placeholder != null) return widget.placeholder!;
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF161B28),
      child: const Center(
        child: Icon(Icons.photo_rounded, size: 32, color: AppColors.textMuted),
      ),
    );
  }
}
