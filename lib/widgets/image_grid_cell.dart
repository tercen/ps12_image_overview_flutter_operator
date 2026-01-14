import 'package:flutter/material.dart';
import 'package:ps12_image_overview/models/image_metadata.dart';

/// Widget that displays a single image cell in the grid.
class ImageGridCell extends StatelessWidget {
  final ImageMetadata image;
  final bool showLabel;

  const ImageGridCell({
    super.key,
    required this.image,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Image ID label at the top (only shown for first row)
        if (showLabel && image.row == 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            child: Text(
              image.id,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        // Image cell
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Container(
              color: Colors.black,
              child: Center(
                child: _buildImage(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the image widget - from bytes, asset path, or placeholder.
  ///
  /// Priority:
  /// 1. imageBytes - runtime-loaded images (from API + TIFF conversion)
  /// 2. imagePath - bundled asset images
  /// 3. placeholder - fallback dot pattern
  Widget _buildImage() {
    // First priority: image bytes (for runtime-converted images)
    if (image.imageBytes != null) {
      return Image.memory(
        image.imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }

    // Second priority: asset path (for bundled images)
    if (image.imagePath != null) {
      return Image.asset(
        image.imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }

    // Fallback: placeholder
    return _buildPlaceholderImage();
  }

  /// Builds a placeholder image with dots pattern (similar to the reference image).
  Widget _buildPlaceholderImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: DotPatternPainter(),
        );
      },
    );
  }
}

/// Custom painter that creates a dot pattern similar to the reference images.
/// Simulates microscopy/scientific imaging with scattered bright spots.
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Create scattered dots that resemble the reference image
    // Pattern inspired by microscopy imaging with varying intensities
    final dots = [
      // Top-left scattered dots
      (0.15, 0.12, 2.0, 0.9),
      (0.2, 0.15, 1.5, 0.6),
      (0.12, 0.2, 2.5, 0.8),
      (0.18, 0.25, 1.8, 0.5),

      // Top-center brighter cluster
      (0.42, 0.15, 2.5, 1.0),
      (0.48, 0.18, 3.0, 0.95),
      (0.45, 0.22, 2.0, 0.7),
      (0.52, 0.2, 2.2, 0.8),

      // Top-right scattered
      (0.75, 0.15, 2.0, 0.75),
      (0.82, 0.18, 1.8, 0.6),
      (0.78, 0.23, 2.3, 0.7),

      // Middle-left
      (0.1, 0.4, 1.8, 0.6),
      (0.15, 0.45, 2.2, 0.75),
      (0.08, 0.5, 1.5, 0.5),

      // Center-right bright vertical cluster
      (0.58, 0.35, 3.0, 1.0),
      (0.62, 0.38, 2.8, 0.95),
      (0.6, 0.42, 3.2, 1.0),
      (0.58, 0.46, 2.5, 0.9),
      (0.62, 0.5, 3.0, 0.95),
      (0.6, 0.54, 2.8, 0.85),
      (0.58, 0.58, 2.5, 0.8),
      (0.62, 0.62, 2.2, 0.75),

      // Right side scattered
      (0.78, 0.45, 2.0, 0.7),
      (0.85, 0.48, 1.8, 0.6),
      (0.82, 0.52, 2.2, 0.65),

      // Bottom-left
      (0.15, 0.75, 2.0, 0.7),
      (0.2, 0.78, 1.8, 0.6),
      (0.12, 0.82, 2.3, 0.75),

      // Bottom-center scattered
      (0.45, 0.75, 2.2, 0.8),
      (0.5, 0.78, 1.9, 0.65),
      (0.48, 0.82, 2.5, 0.7),

      // Bottom-right
      (0.75, 0.75, 2.0, 0.75),
      (0.82, 0.78, 1.7, 0.6),
      (0.78, 0.85, 2.1, 0.7),

      // Additional scattered faint dots
      (0.25, 0.35, 1.5, 0.4),
      (0.35, 0.55, 1.3, 0.35),
      (0.7, 0.35, 1.6, 0.45),
      (0.3, 0.65, 1.4, 0.4),
      (0.68, 0.68, 1.5, 0.45),
    ];

    for (final dot in dots) {
      final x = size.width * dot.$1;
      final y = size.height * dot.$2;
      final radius = dot.$3;
      final opacity = dot.$4;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
