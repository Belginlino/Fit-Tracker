import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/progress_photo_repository.dart';
import '../domain/progress_photo.dart';

enum ComparisonMode { slider, sideBySide }

class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  ComparisonMode _mode = ComparisonMode.slider;
  double _sliderPosition = 0.5; // 0.0 (all before) to 1.0 (all after)
  String? _selectedBeforeId;
  String? _selectedAfterId;
  String _selectedPose = 'Front';

  void _showPhotoSelectorSheet(
      List<ProgressPhoto> photos, bool isBefore, String currentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBefore ? 'Select "Before" Photo' : 'Select "After" Photo',
                      style: AppTypography.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final isSelected = photo.id == currentId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isBefore) {
                              _selectedBeforeId = photo.id;
                            } else {
                              _selectedAfterId = photo.id;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 14,
                          style: isSelected
                              ? NeumorphicStyle.inset
                              : NeumorphicStyle.raised,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.background,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppPhotoImage(
                                    localPath: photo.localFilePath,
                                    remoteUrl: photo.downloadUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          photo.isDayOne ? '★ Day 1 (Baseline)' : photo.dayLabel,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: photo.isDayOne ? AppColors.primary : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('• ${photo.pose}', style: AppTypography.bodySmall),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormatter.formatTimelineDate(photo.createdAt)} • ${photo.weightAtCapture != null ? "${photo.weightAtCapture!.toStringAsFixed(1)} kg" : "No weight recorded"}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.primary, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final photosAsync =
        ref.watch(progressPhotosStreamProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Progress'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _mode == ComparisonMode.slider
                  ? Icons.splitscreen_rounded
                  : Icons.compare_arrows_rounded,
              color: AppColors.primary,
            ),
            tooltip: _mode == ComparisonMode.slider
                ? 'Switch to Side-by-Side'
                : 'Switch to Split Slider',
            onPressed: () {
              setState(() {
                _mode = _mode == ComparisonMode.slider
                    ? ComparisonMode.sideBySide
                    : ComparisonMode.slider;
              });
            },
          ),
        ],
      ),
      body: photosAsync.when(
        data: (allPhotos) {
          final filtered =
              allPhotos.where((p) => p.pose == _selectedPose).toList();

          if (filtered.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text('Need at least 2 photos',
                        style: AppTypography.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Capture at least two "$_selectedPose" photos to compare your visual transformation from Day 1.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          // Pick before photo: prefer explicit selection, else photo marked as Day 1, else oldest
          final beforePhoto = filtered.firstWhere(
            (p) => p.id == _selectedBeforeId,
            orElse: () => filtered.firstWhere(
              (p) => p.isDayOne,
              orElse: () => filtered.last,
            ),
          );

          // Pick after photo: prefer explicit selection, else newest photo (first in descending list)
          final afterPhoto = filtered.firstWhere(
            (p) => p.id == _selectedAfterId,
            orElse: () => filtered.firstWhere(
              (p) => p.id != beforePhoto.id,
              orElse: () => filtered.first,
            ),
          );

          final daysApart = afterPhoto.createdAt
              .difference(beforePhoto.createdAt)
              .inDays
              .abs();
          final weightDiff = (afterPhoto.weightAtCapture ?? 0) -
              (beforePhoto.weightAtCapture ?? 0);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode & Pose Selector Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mode Pill
                    NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      borderRadius: 20,
                      style: NeumorphicStyle.inset,
                      child: Text(
                        _mode == ComparisonMode.slider
                            ? 'Interactive Slider'
                            : 'Side-by-Side',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),

                    // Pose Filter
                    NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      borderRadius: 12,
                      child: DropdownButton<String>(
                        value: _selectedPose,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down_rounded,
                            color: AppColors.primary),
                        items: ['Front', 'Side', 'Back'].map((pose) {
                          return DropdownMenuItem(
                            value: pose,
                            child: Text(
                              pose,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPose = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Interactive Day Selector Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showPhotoSelectorSheet(
                            filtered, true, beforePhoto.id),
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          borderRadius: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text('BEFORE',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textSecondary)),
                                  SizedBox(width: 4),
                                  Icon(Icons.touch_app_rounded,
                                      size: 12, color: AppColors.primary),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                beforePhoto.isDayOne
                                    ? '★ Day 1 (Baseline)'
                                    : beforePhoto.dayLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormatter.formatTimelineDate(
                                    beforePhoto.createdAt),
                                style: AppTypography.bodySmall
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 18, color: AppColors.textMuted),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showPhotoSelectorSheet(
                            filtered, false, afterPhoto.id),
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          borderRadius: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text('AFTER',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textSecondary)),
                                  SizedBox(width: 4),
                                  Icon(Icons.touch_app_rounded,
                                      size: 12, color: AppColors.primary),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                afterPhoto.dayLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormatter.formatTimelineDate(
                                    afterPhoto.createdAt),
                                style: AppTypography.bodySmall
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Comparison Viewer
                _mode == ComparisonMode.slider
                    ? _buildSliderComparison(beforePhoto, afterPhoto)
                    : _buildSideBySideComparison(beforePhoto, afterPhoto),
                const SizedBox(height: 24),

                // Metadata Delta Summary Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Transformation Metrics',
                              style: AppTypography.titleMedium),
                          NeumorphicContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            style: NeumorphicStyle.inset,
                            borderRadius: 10,
                            child: Text(
                              '$daysApart Days Apart',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              label: 'Before',
                              value:
                                  '${beforePhoto.weightAtCapture ?? "--"} kg',
                              subtitle: DateFormatter.formatTimelineDate(
                                  beforePhoto.createdAt),
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              label: 'After',
                              value: '${afterPhoto.weightAtCapture ?? "--"} kg',
                              subtitle: DateFormatter.formatTimelineDate(
                                  afterPhoto.createdAt),
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              label: 'Delta',
                              value:
                                  '${weightDiff >= 0 ? "+" : ""}${weightDiff.toStringAsFixed(1)} kg',
                              valueColor: AppColors.primary,
                              subtitle: 'Net change',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading photos: $e')),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildSliderComparison(ProgressPhoto before, ProgressPhoto after) {
    return NeumorphicContainer(
      height: 380,
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final dividerX = width * _sliderPosition;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sliderPosition =
                      (details.localPosition.dx / width).clamp(0.05, 0.95);
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // After Photo (Base)
                  _buildPhotoPlaceholder(
                    photo: after,
                    label: 'AFTER',
                    date: DateFormatter.formatTimelineDate(after.createdAt),
                    color: AppColors.surface,
                    accentColor: AppColors.primary,
                  ),

                  // Before Photo (Clipped to left side of divider)
                  ClipRect(
                    clipper: _SliderClipper(dividerX),
                    child: _buildPhotoPlaceholder(
                      photo: before,
                      label: 'BEFORE',
                      date: DateFormatter.formatTimelineDate(before.createdAt),
                      color: AppColors.background,
                      accentColor: AppColors.textSecondary,
                    ),
                  ),

                  // Draggable Divider Line & Handle
                  Positioned(
                    left: dividerX - 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: dividerX - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSideBySideComparison(ProgressPhoto before, ProgressPhoto after) {
    return Row(
      children: [
        Expanded(
          child: NeumorphicContainer(
            height: 340,
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPhotoPlaceholder(
                photo: before,
                label: 'BEFORE',
                date: DateFormatter.formatTimelineDate(before.createdAt),
                color: AppColors.background,
                accentColor: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NeumorphicContainer(
            height: 340,
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPhotoPlaceholder(
                photo: after,
                label: 'AFTER',
                date: DateFormatter.formatTimelineDate(after.createdAt),
                color: AppColors.surface,
                accentColor: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder({
    required ProgressPhoto photo,
    required String label,
    required String date,
    required Color color,
    required Color accentColor,
  }) {
    return Container(
      color: color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppPhotoImage(
            localPath: photo.localFilePath,
            remoteUrl: photo.downloadUrl,
            fit: BoxFit.cover,
            placeholder: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 70, color: accentColor.withValues(alpha: 0.7)),
                  const SizedBox(height: 8),
                  Text(
                    '${photo.weightAtCapture ?? "--"} kg',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: accentColor),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double width;
  _SliderClipper(this.width);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(covariant _SliderClipper oldClipper) =>
      oldClipper.width != width;
}
