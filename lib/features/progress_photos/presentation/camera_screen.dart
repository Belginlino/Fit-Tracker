import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/constants/app_constants.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String _selectedPose = 'Front';
  bool _showAlignmentGuide = true;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        context.push('/progress/preview', extra: {
          'imagePath': image.path,
          'pose': _selectedPose,
        });
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
    }
  }

  void _simulateCapture() {
    // Navigate to preview with the selected pose
    context.push('/progress/preview', extra: {
      'imagePath': 'simulated_capture.jpg',
      'pose': _selectedPose,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Viewfinder Background Mock
          Container(
            color: const Color(0xFF10141E),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Camera Viewfinder',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Same-Pose Body Alignment Guide / Silhouette Overlay (Section 11)
          if (_showAlignmentGuide)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BodyGuidePainter(color: AppColors.primary.withOpacity(0.35)),
                ),
              ),
            ),

          // Top Header Bar
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showAlignmentGuide ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showAlignmentGuide ? 'Pose Guide ON' : 'Pose Guide OFF',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showAlignmentGuide ? Icons.accessibility_new_rounded : Icons.accessibility_rounded,
                        color: _showAlignmentGuide ? AppColors.primary : Colors.white,
                      ),
                      onPressed: () => setState(() => _showAlignmentGuide = !_showAlignmentGuide),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls & Pose Selector
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pose Selector Chips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: AppConstants.photoPoses.map((pose) {
                          final isSelected = _selectedPose == pose;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPose = pose),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                pose,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Shutter & Gallery Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Fallback
                        IconButton(
                          icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                          onPressed: _pickFromGallery,
                        ),

                        // Shutter Button
                        GestureDetector(
                          onTap: _simulateCapture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),

                        // Placeholder for symmetry
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for subtle same-pose body alignment guide overlay
class BodyGuidePainter extends CustomPainter {
  final Color color;
  BodyGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final topY = size.height * 0.22;

    // Head oval guide
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, topY), width: 70, height: 90),
      paint,
    );

    // Shoulder line guide
    final shoulderY = topY + 65;
    canvas.drawLine(
      Offset(centerX - 95, shoulderY),
      Offset(centerX + 95, shoulderY),
      paint,
    );

    // Torso / Hip guidelines
    final hipY = shoulderY + 160;
    canvas.drawLine(
      Offset(centerX - 70, hipY),
      Offset(centerX + 70, hipY),
      paint,
    );

    // Center vertical alignment axis
    final dashPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(centerX, topY - 60),
      Offset(centerX, hipY + 180),
      dashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
