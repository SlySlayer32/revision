import 'package:flutter/foundation.dart';
import 'package:revision/features/ai_processing/domain/entities/spatial_analysis_result.dart';
import 'package:revision/features/ai_processing/domain/entities/spatial_point.dart';
import 'package:revision/features/ai_processing/domain/entities/spatial_region.dart';

/// Spatial Understanding service based on Gemini's spatial capabilities
///
/// Implements the spatial understanding techniques from:
/// https://colab.research.google.com/github/google-gemini/cookbook/blob/main/quickstarts/Spatial_understanding.ipynb
class GeminiSpatialService {
  static const String _model = 'gemini-2.0-flash-exp';

  /// Analyzes spatial relationships in an image using Gemini's spatial understanding
  Future<SpatialAnalysisResult?> analyzeSpatialRelationships({
    required Uint8List imageBytes,
    required String query,
    List<SpatialPoint>? referencePoints,
  }) async {
    try {
      // Prepare the spatial analysis prompt
      final spatialPrompt = _buildSpatialPrompt(query, referencePoints);

      if (kDebugMode) {
        debugPrint('🔍 Spatial Analysis: Analyzing image with query: $query');
      }

      // Call Gemini API with spatial understanding capabilities
      final response = await _callGeminiSpatialAPI(
        imageBytes: imageBytes,
        prompt: spatialPrompt,
      );

      if (response != null) {
        return _parseSpatialResponse(response);
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Spatial Analysis error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Identifies objects and their spatial locations
  Future<List<SpatialRegion>?> identifyObjectLocations({
    required Uint8List imageBytes,
    required List<String> objectTypes,
  }) async {
    try {
      final prompt = _buildObjectLocationPrompt(objectTypes);

      if (kDebugMode) {
        debugPrint(
          '🔍 Object Location: Searching for ${objectTypes.join(', ')}',
        );
      }

      final response = await _callGeminiSpatialAPI(
        imageBytes: imageBytes,
        prompt: prompt,
      );

      if (response != null) {
        return _parseObjectLocations(response);
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Object Location error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Analyzes spatial relationships between objects
  Future<Map<String, String>?> analyzeSpatialRelationshipsBetweenObjects({
    required Uint8List imageBytes,
    required List<String> objects,
  }) async {
    try {
      final prompt = _buildRelationshipPrompt(objects);

      if (kDebugMode) {
        debugPrint(
          '🔍 Relationship Analysis: Analyzing relationships between ${objects.join(', ')}',
        );
      }

      final response = await _callGeminiSpatialAPI(
        imageBytes: imageBytes,
        prompt: prompt,
      );

      if (response != null) {
        return _parseRelationships(response);
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Relationship Analysis error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Builds spatial analysis prompt based on Gemini cookbook patterns
  String _buildSpatialPrompt(
    String query,
    List<SpatialPoint>? referencePoints,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('Analyze the spatial relationships in this image.');
    buffer.writeln('Focus on: $query');
    buffer.writeln();
    buffer.writeln('Please provide:');
    buffer.writeln(
      '1. Object locations using coordinates (x, y as percentages of image dimensions)',
    );
    buffer.writeln(
      '2. Spatial relationships (above, below, left, right, inside, outside)',
    );
    buffer.writeln('3. Relative distances and positioning');
    buffer.writeln('4. Any spatial context relevant to the query');

    if (referencePoints != null && referencePoints.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Reference points provided:');
      for (int i = 0; i < referencePoints.length; i++) {
        final point = referencePoints[i];
        buffer.writeln(
          'Point ${i + 1}: (${point.x}, ${point.y}) - ${point.label ?? 'Unknown'}',
        );
      }
    }

    buffer.writeln();
    buffer.writeln(
      'Format your response as JSON with the following structure:',
    );
    buffer.writeln('''{
  "objects": [
    {
      "name": "object_name",
      "location": {"x": 0.5, "y": 0.3},
      "bounds": {"left": 0.4, "top": 0.2, "right": 0.6, "bottom": 0.4},
      "confidence": 0.95
    }
  ],
  "relationships": [
    {
      "object1": "object_name_1",
      "object2": "object_name_2", 
      "relationship": "above/below/left/right/inside/outside",
      "distance": "close/medium/far"
    }
  ],
  "summary": "Overall spatial description"
}''');

    return buffer.toString();
  }

  /// Builds object location prompt
  String _buildObjectLocationPrompt(List<String> objectTypes) {
    final buffer = StringBuffer();

    buffer.writeln('Identify and locate the following objects in this image:');
    for (final objectType in objectTypes) {
      buffer.writeln('- $objectType');
    }

    buffer.writeln();
    buffer.writeln('For each object found, provide:');
    buffer.writeln('1. Exact location coordinates (x, y as percentages)');
    buffer.writeln('2. Bounding box coordinates');
    buffer.writeln('3. Confidence level');
    buffer.writeln('4. Brief description');

    buffer.writeln();
    buffer.writeln('Respond in JSON format with an array of found objects.');

    return buffer.toString();
  }

  /// Builds relationship analysis prompt
  String _buildRelationshipPrompt(List<String> objects) {
    final buffer = StringBuffer();

    buffer.writeln(
      'Analyze the spatial relationships between these objects in the image:',
    );
    for (final object in objects) {
      buffer.writeln('- $object');
    }

    buffer.writeln();
    buffer.writeln('Describe how each object relates spatially to the others.');
    buffer.writeln(
      'Include relative positions, distances, and any containment relationships.',
    );

    return buffer.toString();
  }

  /// Calls Gemini API with spatial understanding configuration
  Future<Map<String, dynamic>?> _callGeminiSpatialAPI({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    try {
      // This would integrate with your existing Gemini service
      // The spatial understanding cookbook shows how to:
      // 1. Encode image properly for spatial analysis
      // 2. Use specific model configurations for spatial tasks
      // 3. Parse spatial coordinates and relationships

      // Placeholder for actual API integration
      // TODO: Integrate with your existing GeminiAIService

      if (kDebugMode) {
        debugPrint('🔗 Calling Gemini API for spatial analysis');
        debugPrint('🔗 Model: $_model');
        debugPrint('🔗 Image size: ${imageBytes.length} bytes');
      }

      // Mock response for development
      if (kDebugMode) {
        return {
          'objects': [
            {
              'name': 'sample_object',
              'location': {'x': 0.5, 'y': 0.3},
              'bounds': {'left': 0.4, 'top': 0.2, 'right': 0.6, 'bottom': 0.4},
              'confidence': 0.95,
            },
          ],
          'relationships': [
            {
              'object1': 'object_a',
              'object2': 'object_b',
              'relationship': 'above',
              'distance': 'close',
            },
          ],
          'summary': 'Spatial analysis completed successfully',
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Gemini API call failed: $e');
      }
      return null;
    }
  }

  /// Parses spatial analysis response
  SpatialAnalysisResult _parseSpatialResponse(Map<String, dynamic> response) {
    final objects = <SpatialRegion>[];
    final relationships = <String, String>{};

    // Parse objects
    if (response['objects'] is List) {
      final objectList = response['objects'] as List;
      for (final obj in objectList) {
        if (obj is Map<String, dynamic>) {
          final region = _parseObjectToRegion(obj);
          if (region != null) {
            objects.add(region);
          }
        }
      }
    }

    // Parse relationships
    if (response['relationships'] is List) {
      final relationshipList = response['relationships'] as List;
      for (final rel in relationshipList) {
        if (rel is Map<String, dynamic>) {
          final key = '${rel['object1']}_${rel['object2']}';
          final value = '${rel['relationship']} (${rel['distance']})';
          relationships[key] = value;
        }
      }
    }

    final summary =
        response['summary'] as String? ?? 'Spatial analysis completed';

    return SpatialAnalysisResult(
      objects: objects,
      relationships: relationships,
      summary: summary,
      timestamp: DateTime.now(),
    );
  }

  /// Parses object locations from response
  List<SpatialRegion> _parseObjectLocations(Map<String, dynamic> response) {
    final regions = <SpatialRegion>[];

    if (response['objects'] is List) {
      final objectList = response['objects'] as List;
      for (final obj in objectList) {
        if (obj is Map<String, dynamic>) {
          final region = _parseObjectToRegion(obj);
          if (region != null) {
            regions.add(region);
          }
        }
      }
    }

    return regions;
  }

  /// Parses relationships from response
  Map<String, String> _parseRelationships(Map<String, dynamic> response) {
    final relationships = <String, String>{};

    if (response['relationships'] is List) {
      final relationshipList = response['relationships'] as List;
      for (final rel in relationshipList) {
        if (rel is Map<String, dynamic>) {
          final key = '${rel['object1']}_${rel['object2']}';
          final value = rel['relationship'] as String? ?? 'unknown';
          relationships[key] = value;
        }
      }
    }

    return relationships;
  }

  /// Converts object data to SpatialRegion
  SpatialRegion? _parseObjectToRegion(Map<String, dynamic> obj) {
    try {
      final name = obj['name'] as String?;
      final location = obj['location'] as Map<String, dynamic>?;
      final bounds = obj['bounds'] as Map<String, dynamic>?;
      final confidence = (obj['confidence'] as num?)?.toDouble();

      if (name == null || location == null) {
        return null;
      }

      final centerX = (location['x'] as num?)?.toDouble() ?? 0.0;
      final centerY = (location['y'] as num?)?.toDouble() ?? 0.0;

      double left = centerX - 0.05;
      double top = centerY - 0.05;
      double right = centerX + 0.05;
      double bottom = centerY + 0.05;

      if (bounds != null) {
        left = (bounds['left'] as num?)?.toDouble() ?? left;
        top = (bounds['top'] as num?)?.toDouble() ?? top;
        right = (bounds['right'] as num?)?.toDouble() ?? right;
        bottom = (bounds['bottom'] as num?)?.toDouble() ?? bottom;
      }

      return SpatialRegion(
        id: name.hashCode.toString(),
        name: name,
        centerPoint: SpatialPoint(x: centerX, y: centerY, label: name),
        boundingBox: SpatialBoundingBox(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        confidence: confidence ?? 0.0,
        description: obj['description'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing object to region: $e');
      }
      return null;
    }
  }
}
