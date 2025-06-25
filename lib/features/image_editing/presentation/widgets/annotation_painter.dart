import 'package:flutter/material.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';

/// Custom painter for drawing annotation strokes on an image.
class AnnotationPainter extends CustomPainter {
  const AnnotationPainter({
    required this.strokes,
    this.currentStroke,
    required this.imageSize,
  });

  final List<AnnotationStroke> strokes;
  final AnnotationStroke? currentStroke;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, size, stroke);
    }

    // Draw current stroke being drawn
    if (currentStroke != null) {
      _drawStroke(canvas, size, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Size size, AnnotationStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = Color(stroke.color).withValues(alpha: 0.7)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool isFirst = true;

    for (final point in stroke.points) {
      // Convert normalized coordinates to widget coordinates
      final x = point.x * size.width;
      final y = point.y * size.height;

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw stroke points for better visibility
    final pointPaint = Paint()
      ..color = Color(stroke.color)
      ..style = PaintingStyle.fill;

    for (final point in stroke.points) {
      final x = point.x * size.width;
      final y = point.y * size.height;
      canvas.drawCircle(Offset(x, y), stroke.strokeWidth / 2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.imageSize != imageSize;
  }
}
