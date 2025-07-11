import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Represents a segmentation mask from Gemini 2.5 segmentation API
///
/// Corresponds to the JSON output format from Gemini 2.5:
/// {
///   "box_2d": [y0, x0, y1, x1],
///   "polygon": [[x1,y1], [x2,y2], [x3,y3], [x4,y4]],
///   "label": "object name",
///   "confidence": 0.95,
///   "area_percentage": 15.2
/// }
class SegmentationMask extends Equatable {
  const SegmentationMask({
    required this.boundingBox,
    required this.label,
    required this.confidence,
    this.polygon = const [],
    this.areaPercentage = 0.0,
    this.maskData,
  });

  /// Bounding box coordinates in normalized format [y0, x0, y1, x1]
  /// Values are between 0 and 1000 as per Gemini API specification
  final BoundingBox2D boundingBox;

  /// Descriptive label for the segmented object
  final String label;

  /// Confidence score for the segmentation (0.0 to 1.0)
  final double confidence;

  /// Polygon coordinates defining the object boundary
  /// Each point is [x, y] in normalized coordinates (0-1000)
  final List<List<double>> polygon;

  /// Estimated percentage of image area occupied by the object
  final double areaPercentage;

  /// Optional base64 encoded PNG mask data (for backward compatibility)
  final Uint8List? maskData;

  @override
  List<Object?> get props => [
    boundingBox,
    label,
    confidence,
    polygon,
    areaPercentage,
    maskData,
  ];

  /// Factory constructor from Gemini API JSON response with production-grade error handling
  factory SegmentationMask.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (!json.containsKey('box_2d') || !json.containsKey('label')) {
        throw const FormatException('Missing required fields: box_2d or label');
      }

      final box2d = json['box_2d'] as List<dynamic>?;
      if (box2d == null || box2d.length != 4) {
        throw const FormatException(
          'Invalid box_2d format: expected [y0, x0, y1, x1]',
        );
      }

      // Parse polygon coordinates if available
      List<List<double>> polygon = [];
      if (json.containsKey('polygon') && json['polygon'] is List) {
        final polygonData = json['polygon'] as List;
        for (final point in polygonData) {
          if (point is List && point.length >= 2) {
            polygon.add([
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ]);
          }
        }
      }

      // Parse area percentage
      double areaPercentage = 0.0;
      if (json.containsKey('area_percentage')) {
        final areaValue = json['area_percentage'];
        if (areaValue is num) {
          areaPercentage = areaValue.toDouble().clamp(0.0, 100.0);
        }
      }

      // Handle legacy mask data gracefully (optional)
      Uint8List? maskData;
      if (json.containsKey('mask') && json['mask'] != null) {
        final maskString = json['mask'] as String;
        String cleanBase64 = '';
        if (maskString.startsWith('data:image/png;base64,')) {
          cleanBase64 = maskString.substring('data:image/png;base64,'.length);
        } else {
          cleanBase64 = maskString;
        }
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        if (cleanBase64.isNotEmpty) {
          maskData = _base64ToUint8List(cleanBase64);
        }
      }

      // Validate label
      final label = json['label'] as String? ?? 'unknown_object';
      if (label.trim().isEmpty) {
        throw const FormatException('Label cannot be empty');
      }

      // Parse confidence with fallback
      double confidence = 0.8; // Default confidence if not provided
      if (json.containsKey('confidence')) {
        final confValue = json['confidence'];
        if (confValue is num) {
          confidence = confValue.toDouble().clamp(0.0, 1.0);
        } else if (confValue is String) {
          confidence = double.tryParse(confValue)?.clamp(0.0, 1.0) ?? 0.8;
        }
      }

      return SegmentationMask(
        boundingBox: BoundingBox2D(
          y0: (box2d[0] as num).toDouble(),
          x0: (box2d[1] as num).toDouble(),
          y1: (box2d[2] as num).toDouble(),
          x1: (box2d[3] as num).toDouble(),
        ),
        label: label.trim(),
        confidence: confidence,
        polygon: polygon,
        areaPercentage: areaPercentage,
        maskData: maskData,
      );
    } catch (e) {
      // Create a fallback mask for production resilience
      return const SegmentationMask(
        boundingBox: BoundingBox2D(y0: 0, x0: 0, y1: 100, x1: 100),
        label: 'parse_error_object',
        confidence: 0.0,
        polygon: [],
        areaPercentage: 0.0,
        maskData: null,
      );
    }
  }

  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    final result = {
      'box_2d': [
        boundingBox.y0,
        boundingBox.x0,
        boundingBox.y1,
        boundingBox.x1,
      ],
      'label': label,
      'confidence': confidence,
      'polygon': polygon,
      'area_percentage': areaPercentage,
    };

    // Include mask data only if available (for backward compatibility)
    if (maskData != null && maskData!.isNotEmpty) {
      result['mask'] = 'data:image/png;base64,${_uint8ListToBase64(maskData!)}';
    }

    return result;
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

  /// Check if a point is inside the segmented object using polygon or bounding box
  bool containsPoint(int x, int y, int imageWidth, int imageHeight) {
    // Convert normalized coordinates to absolute
    final absoluteBox = toAbsoluteCoordinates(imageWidth, imageHeight);

    // Check if point is within bounding box first
    if (x < absoluteBox.x0 ||
        x >= absoluteBox.x1 ||
        y < absoluteBox.y0 ||
        y >= absoluteBox.y1) {
      return false;
    }

    // If polygon is available, use ray casting algorithm for precise detection
    if (polygon.isNotEmpty) {
      return _isPointInPolygon(x, y, imageWidth, imageHeight);
    }

    // If no polygon, use bounding box as fallback
    return true;
  }

  /// Ray casting algorithm to check if point is inside polygon
  bool _isPointInPolygon(int x, int y, int imageWidth, int imageHeight) {
    if (polygon.length < 3) return false;

    // Convert normalized polygon coordinates to absolute
    final absolutePolygon = polygon
        .map(
          (point) => [
            (point[0] / 1000) * imageWidth,
            (point[1] / 1000) * imageHeight,
          ],
        )
        .toList();

    bool inside = false;
    int j = absolutePolygon.length - 1;

    for (int i = 0; i < absolutePolygon.length; i++) {
      final xi = absolutePolygon[i][0];
      final yi = absolutePolygon[i][1];
      final xj = absolutePolygon[j][0];
      final yj = absolutePolygon[j][1];

      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  static Uint8List _base64ToUint8List(String base64String) {
    try {
      return Uint8List.fromList(base64Decode(base64String));
    } catch (e) {
      throw FormatException('Invalid base64 mask data: $e');
    }
  }

  static String _uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
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
