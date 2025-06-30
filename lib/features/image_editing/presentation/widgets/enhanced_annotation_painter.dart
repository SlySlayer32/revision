import 'package:flutter/material.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/image_editing/domain/utils/annotation_converter.dart';

/// Enhanced annotation painter that shows both strokes and bounding boxes
class EnhancedAnnotationPainter extends CustomPainter {
  const EnhancedAnnotationPainter({
    required this.strokes,
    this.currentStroke,
    this.imageSize = Size.zero,
    this.showBoundingBoxes = true,
  });

  final List<AnnotationStroke> strokes;
  final AnnotationStroke? currentStroke;
  final Size imageSize;
  final bool showBoundingBoxes;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero) return;

    // Paint completed strokes
    for (final stroke in strokes) {
      _paintStroke(canvas, size, stroke, Colors.red, 3.0);
      
      if (showBoundingBoxes) {
        _paintBoundingBox(canvas, size, stroke);
      }
    }

    // Paint current stroke being drawn
    if (currentStroke != null) {
      _paintStroke(canvas, size, currentStroke!, Colors.red.withValues(alpha: 0.7), 3.0);
    }
  }

  void _paintStroke(Canvas canvas, Size size, AnnotationStroke stroke, Color color, double strokeWidth) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Convert normalized coordinates to canvas coordinates
    final firstPoint = stroke.points.first;
    path.moveTo(
      firstPoint.x * size.width,
      firstPoint.y * size.height,
    );

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      path.lineTo(
        point.x * size.width,
        point.y * size.height,
      );
    }

    canvas.drawPath(path, paint);
  }

  void _paintBoundingBox(Canvas canvas, Size size, AnnotationStroke stroke) {
    if (stroke.points.isEmpty) return;

    // Calculate bounding box using the converter utility
    final boundingBox = AnnotationConverterExtension.calculateStrokeBoundingBox(stroke);
    final center = AnnotationConverterExtension.calculateStrokeCenter(stroke);

    // Convert to canvas coordinates
    final centerX = center.x * size.width;
    final centerY = center.y * size.height;
    final boxWidth = boundingBox.width * size.width;
    final boxHeight = boundingBox.height * size.height;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: boxWidth,
      height: boxHeight,
    );

    // Paint bounding box outline
    final boundingBoxPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, boundingBoxPaint);

    // Paint bounding box fill
    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);

    // Paint center point
    final centerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 4.0, centerPaint);

    // Paint size indicator text
    _paintSizeIndicator(canvas, size, rect, boundingBox);
  }

  void _paintSizeIndicator(Canvas canvas, Size size, Rect rect, ({double width, double height}) boundingBox) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(boundingBox.width * 100).toStringAsFixed(0)}% × ${(boundingBox.height * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position text above the bounding box
    final textOffset = Offset(
      rect.left,
      (rect.top - textPainter.height - 4).clamp(0, size.height - textPainter.height),
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant EnhancedAnnotationPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
           currentStroke != oldDelegate.currentStroke ||
           imageSize != oldDelegate.imageSize ||
           showBoundingBoxes != oldDelegate.showBoundingBoxes;
  }
}

/// Extension to make bounding box calculation accessible
extension AnnotationConverterExtension on AnnotationConverter {
  static ({double width, double height}) calculateStrokeBoundingBox(AnnotationStroke stroke) {
    if (stroke.points.isEmpty) {
      return (width: 0.1, height: 0.1);
    }

    // Find min/max coordinates
    double minX = stroke.points.first.x;
    double maxX = stroke.points.first.x;
    double minY = stroke.points.first.y;
    double maxY = stroke.points.first.y;

    for (final point in stroke.points) {
      minX = minX < point.x ? minX : point.x;
      maxX = maxX > point.x ? maxX : point.x;
      minY = minY < point.y ? minY : point.y;
      maxY = maxY > point.y ? maxY : point.y;
    }

    final width = (maxX - minX).clamp(0.05, 1.0);
    final height = (maxY - minY).clamp(0.05, 1.0);

    // Add padding
    final paddedWidth = (width * 1.4).clamp(0.1, 1.0);
    final paddedHeight = (height * 1.4).clamp(0.1, 1.0);

    return (width: paddedWidth, height: paddedHeight);
  }

  static ({double x, double y}) calculateStrokeCenter(AnnotationStroke stroke) {
    if (stroke.points.isEmpty) {
      return (x: 0.5, y: 0.5);
    }

    double totalX = 0.0;
    double totalY = 0.0;

    for (final point in stroke.points) {
      totalX += point.x;
      totalY += point.y;
    }

    return (
      x: totalX / stroke.points.length,
      y: totalY / stroke.points.length,
    );
  }
}
