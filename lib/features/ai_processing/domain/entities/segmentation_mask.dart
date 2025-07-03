import 'dart:convert';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Represents a segmentation mask from Gemini 2.5 segmentation API
///
/// Corresponds to the JSON output format from Gemini 2.5:
/// {
///   "box_2d": [y0, x0, y1, x1],
///   "label": "object name",
///   "mask": "data:image/png;base64,..."
/// }
class SegmentationMask extends Equatable {
  const SegmentationMask({
    required this.boundingBox,
    required this.label,
    required this.maskData,
    required this.confidence,
  });

  /// Bounding box coordinates in normalized format [y0, x0, y1, x1]
  /// Values are between 0 and 1000 as per Gemini API specification
  final BoundingBox2D boundingBox;

  /// Descriptive label for the segmented object
  final String label;

  /// Base64 encoded PNG mask data (probability map with values 0-255)
  final Uint8List maskData;

  /// Confidence score for the segmentation (0.0 to 1.0)
  final double confidence;

  @override
  List<Object?> get props => [boundingBox, label, maskData, confidence];

  /// Factory constructor from Gemini API JSON response
  factory SegmentationMask.fromJson(Map<String, dynamic> json) {
    final box2d = json['box_2d'] as List<dynamic>;
    final maskBase64 = json['mask'] as String;
    
    // Remove the data:image/png;base64, prefix if present
    final cleanBase64 = maskBase64.startsWith('data:image/png;base64,')
        ? maskBase64.substring('data:image/png;base64,'.length)
        : maskBase64;
    
    return SegmentationMask(
      boundingBox: BoundingBox2D(
        y0: (box2d[0] as num).toDouble(),
        x0: (box2d[1] as num).toDouble(),
        y1: (box2d[2] as num).toDouble(),
        x1: (box2d[3] as num).toDouble(),
      ),
      label: json['label'] as String,
      maskData: _base64ToUint8List(cleanBase64),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'box_2d': [boundingBox.y0, boundingBox.x0, boundingBox.y1, boundingBox.x1],
      'label': label,
      'mask': 'data:image/png;base64,${_uint8ListToBase64(maskData)}',
      'confidence': confidence,
    };
  }

  /// Convert normalized coordinates to absolute coordinates
  BoundingBox2D toAbsoluteCoordinates(int imageWidth, int imageHeight) {
    return BoundingBox2D(
      y0: (boundingBox.y0 / 1000) * imageHeight,
      x0: (boundingBox.x0 / 1000) * imageWidth,
      y1: (boundingBox.y1 / 1000) * imageHeight,
      x1: (boundingBox.x1 / 1000) * imageWidth,
    );
  }

  /// Check if a point is inside the segmented object using the mask
  bool containsPoint(int x, int y, int imageWidth, int imageHeight) {
    final absoluteBox = toAbsoluteCoordinates(imageWidth, imageHeight);
    
    // Check if point is within bounding box first
    if (x < absoluteBox.x0 || x >= absoluteBox.x1 || 
        y < absoluteBox.y0 || y >= absoluteBox.y1) {
      return false;
    }
    
    // Calculate relative position within the mask
    final maskWidth = (absoluteBox.x1 - absoluteBox.x0).round();
    final maskHeight = (absoluteBox.y1 - absoluteBox.y0).round();
    
    if (maskWidth <= 0 || maskHeight <= 0) return false;
    
    final relativeX = ((x - absoluteBox.x0) / maskWidth * maskWidth).round();
    final relativeY = ((y - absoluteBox.y0) / maskHeight * maskHeight).round();
    
    // For simplicity, we'll need to decode the PNG mask to check pixel values
    // This is a placeholder - in practice you'd use an image decoding library
    return true; // Placeholder implementation
  }

  static Uint8List _base64ToUint8List(String base64String) {
    try {
      return Uint8List.fromList(
        const Base64Decoder().convert(base64String)
      );
    } catch (e) {
      throw FormatException('Invalid base64 mask data: $e');
    }
  }

  static String _uint8ListToBase64(Uint8List data) {
    return const Base64Encoder().convert(data);
  }
}

/// 2D bounding box with normalized coordinates (0-1000 scale)
class BoundingBox2D extends Equatable {
  const BoundingBox2D({
    required this.y0,
    required this.x0,
    required this.y1,
    required this.x1,
  });

  final double y0; // Top Y coordinate
  final double x0; // Left X coordinate
  final double y1; // Bottom Y coordinate
  final double x1; // Right X coordinate

  @override
  List<Object?> get props => [y0, x0, y1, x1];

  /// Get the width of the bounding box
  double get width => x1 - x0;

  /// Get the height of the bounding box
  double get height => y1 - y0;

  /// Get the area of the bounding box
  double get area => width * height;

  /// Get the center point of the bounding box
  (double x, double y) get center => ((x0 + x1) / 2, (y0 + y1) / 2);

  @override
  String toString() {
    return 'BoundingBox2D(x0: $x0, y0: $y0, x1: $x1, y1: $y1)';
  }
}
