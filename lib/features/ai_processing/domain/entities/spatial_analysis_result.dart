import 'package:revision/features/ai_processing/domain/entities/spatial_point.dart';
import 'package:revision/features/ai_processing/domain/entities/spatial_region.dart';

/// Result of spatial analysis containing detected objects and their relationships
///
/// This class encapsulates the complete spatial understanding analysis
/// based on Gemini's spatial capabilities
class SpatialAnalysisResult {
  const SpatialAnalysisResult({
    required this.objects,
    required this.relationships,
    required this.summary,
    required this.timestamp,
    this.confidence,
    this.metadata,
  });

  /// List of detected spatial regions/objects
  final List<SpatialRegion> objects;

  /// Map of spatial relationships between objects
  /// Key format: "object1_object2", Value: relationship description
  final Map<String, String> relationships;

  /// Summary description of the spatial analysis
  final String summary;

  /// When the analysis was performed
  final DateTime timestamp;

  /// Overall confidence score for the analysis
  final double? confidence;

  /// Additional metadata about the analysis
  final Map<String, dynamic>? metadata;

  /// Gets all objects of a specific type
  List<SpatialRegion> getObjectsOfType(String objectType) {
    return objects.where((obj) => obj.objectType == objectType).toList();
  }

  /// Gets objects with confidence above a threshold
  List<SpatialRegion> getHighConfidenceObjects(double threshold) {
    return objects.where((obj) => obj.confidence >= threshold).toList();
  }

  /// Finds the relationship between two specific objects
  String? getRelationshipBetween(String object1, String object2) {
    final key1 = '${object1}_$object2';
    final key2 = '${object2}_$object1';

    return relationships[key1] ?? relationships[key2];
  }

  /// Gets all objects within a specified area
  List<SpatialRegion> getObjectsInArea({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    return objects.where((obj) {
      final center = obj.centerPoint;
      return center.isWithinRegion(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      );
    }).toList();
  }

  /// Gets the largest object by area
  SpatialRegion? getLargestObject() {
    if (objects.isEmpty) return null;

    return objects.reduce((a, b) => a.area > b.area ? a : b);
  }

  /// Gets the most confident object
  SpatialRegion? getMostConfidentObject() {
    if (objects.isEmpty) return null;

    return objects.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  /// Finds objects near a specific point
  List<SpatialRegion> getObjectsNearPoint(
    SpatialPoint point, {
    double radius = 0.1,
  }) {
    return objects.where((obj) {
      final distance = obj.centerPoint.distanceTo(point);
      return distance <= radius;
    }).toList();
  }

  /// Groups objects by their spatial relationships
  Map<String, List<SpatialRegion>> groupObjectsByRelationship() {
    final groups = <String, List<SpatialRegion>>{};

    for (final relationship in relationships.values) {
      groups[relationship] = [];
    }

    // This is a simplified grouping - in practice, you'd need more complex logic
    // to map relationships back to specific objects

    return groups;
  }

  /// Calculates spatial density (objects per unit area)
  double calculateSpatialDensity() {
    if (objects.isEmpty) return 0.0;

    // Calculate the area covered by all objects
    double totalArea = 0.0;
    for (final obj in objects) {
      totalArea += obj.area;
    }

    return objects.length / (totalArea > 0 ? totalArea : 1.0);
  }

  /// Validates the analysis result
  bool isValid() {
    return objects.isNotEmpty && summary.isNotEmpty;
  }

  /// Creates a copy with modified properties
  SpatialAnalysisResult copyWith({
    List<SpatialRegion>? objects,
    Map<String, String>? relationships,
    String? summary,
    DateTime? timestamp,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return SpatialAnalysisResult(
      objects: objects ?? this.objects,
      relationships: relationships ?? this.relationships,
      summary: summary ?? this.summary,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SpatialAnalysisResult(objects: ${objects.length}, relationships: ${relationships.length}, summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpatialAnalysisResult &&
        _listEquals(other.objects, objects) &&
        _mapEquals(other.relationships, relationships) &&
        other.summary == summary &&
        other.timestamp == timestamp &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return Object.hash(
      objects.length,
      relationships.length,
      summary,
      timestamp,
      confidence,
    );
  }

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'objects': objects.map((obj) => obj.toJson()).toList(),
      'relationships': relationships,
      'summary': summary,
      'timestamp': timestamp.toIso8601String(),
      if (confidence != null) 'confidence': confidence,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Creates from JSON representation
  factory SpatialAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SpatialAnalysisResult(
      objects: (json['objects'] as List)
          .map((obj) => SpatialRegion.fromJson(obj as Map<String, dynamic>))
          .toList(),
      relationships: Map<String, String>.from(json['relationships'] as Map),
      summary: json['summary'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
