import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_card.dart';
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
  int _beforeIndex = 2; // Oldest
  int _afterIndex = 0; // Newest
  String _selectedPose = 'Front';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final photosAsync = ref.watch(progressPhotosStreamProvider(user?.id ?? 'demo-user-101'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transformation Compare'),
        actions: [
          IconButton(
            icon: Icon(
              _mode == ComparisonMode.slider ? Icons.splitscreen_rounded : Icons.compare_arrows_rounded,
              color: AppColors.primary,
            ),
            tooltip: _mode == ComparisonMode.slider ? 'Switch to Side-by-Side' : 'Switch to Split Slider',
            onPressed: () {
              setState(() {
                _mode = _mode == ComparisonMode.slider ? ComparisonMode.sideBySide : ComparisonMode.slider;
              });
            },
          ),
        ],
      ),
      body: photosAsync.when(
        data: (allPhotos) {
          final filtered = allPhotos.where((p) => p.pose == _selectedPose).toList();

          if (filtered.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('Need at least 2 photos', style: AppTypography.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Capture at least two "$_selectedPose" photos to compare your visual transformation.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final beforePhoto = _beforeIndex < filtered.length ? filtered[_beforeIndex] : filtered.last;
          final afterPhoto = _afterIndex < filtered.length ? filtered[_afterIndex] : filtered.first;

          final daysApart = afterPhoto.createdAt.difference(beforePhoto.createdAt).inDays.abs();
          final weightDiff = (afterPhoto.weightAtCapture ?? 0) - (beforePhoto.weightAtCapture ?? 0);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode & Pose Selector Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mode Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        _mode == ComparisonMode.slider ? 'Interactive Slider' : 'Side-by-Side',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                      ),
                    ),

                    // Pose Filter
                    DropdownButton<String>(
                      value: _selectedPose,
                      dropdownColor: AppColors.card,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                      items: ['Front', 'Side', 'Back', 'Free'].map((pose) {
                        return DropdownMenuItem(
                          value: pose,
                          child: Text(
                            pose,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPose = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Comparison Viewer
                _mode == ComparisonMode.slider
                    ? _buildSliderComparison(beforePhoto, afterPhoto)
                    : _buildSideBySideComparison(beforePhoto, afterPhoto),
                const SizedBox(height: 20),

                // Metadata Delta Summary Card (Section 15)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transformation Metrics', style: AppTypography.titleMedium),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                              label: 'Before Weight',
                              value: '${beforePhoto.weightAtCapture ?? "--"} kg',
                              subtitle: DateFormatter.formatTimelineDate(beforePhoto.createdAt),
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppColors.divider,
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              label: 'After Weight',
                              value: '${afterPhoto.weightAtCapture ?? "--"} kg',
                              subtitle: DateFormatter.formatTimelineDate(afterPhoto.createdAt),
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppColors.divider,
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              label: 'Weight Delta',
                              value: '${weightDiff >= 0 ? "+" : ""}${weightDiff.toStringAsFixed(1)} kg',
                              valueColor: weightDiff >= 0 ? AppColors.accentLime : AppColors.primary,
                              subtitle: 'Net change',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Milestone Notes
                if (beforePhoto.notes != null || afterPhoto.notes != null)
                  AppCard(
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recorded Journal Notes', style: AppTypography.labelLarge),
                        const SizedBox(height: 10),
                        if (beforePhoto.notes != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Before: "${beforePhoto.notes}"',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        if (afterPhoto.notes != null)
                          Text(
                            'After: "${afterPhoto.notes}"',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
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
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildSliderComparison(ProgressPhoto before, ProgressPhoto after) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final dividerX = width * _sliderPosition;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sliderPosition = (details.localPosition.dx / width).clamp(0.05, 0.95);
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
                    color: const Color(0xFF1E2638),
                    accentColor: AppColors.accentLime,
                  ),

                  // Before Photo (Clipped to left side of divider)
                  ClipRect(
                    clipper: _SliderClipper(dividerX),
                    child: _buildPhotoPlaceholder(
                      photo: before,
                      label: 'BEFORE',
                      date: DateFormatter.formatTimelineDate(before.createdAt),
                      color: const Color(0xFF161B28),
                      accentColor: AppColors.primary,
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
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.black,
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
          child: Container(
            height: 340,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPhotoPlaceholder(
                photo: before,
                label: 'BEFORE',
                date: DateFormatter.formatTimelineDate(before.createdAt),
                color: const Color(0xFF161B28),
                accentColor: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 340,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentLime.withOpacity(0.4), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPhotoPlaceholder(
                photo: after,
                label: 'AFTER',
                date: DateFormatter.formatTimelineDate(after.createdAt),
                color: const Color(0xFF1E2638),
                accentColor: AppColors.accentLime,
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline_rounded, size: 70, color: accentColor.withOpacity(0.7)),
                const SizedBox(height: 8),
                Text(
                  '${photo.weightAtCapture ?? "--"} kg',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accentColor),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentColor),
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
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
  bool shouldReclip(covariant _SliderClipper oldClipper) => oldClipper.width != width;
}
