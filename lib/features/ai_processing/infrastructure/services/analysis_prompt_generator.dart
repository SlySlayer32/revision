import 'dart:math';

import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';

/// Service responsible for generating AI analysis prompts
/// 
/// Separates prompt generation logic from analysis service following
/// Single Responsibility Principle.
class AnalysisPromptGenerator {
  /// Generates a custom system prompt for Vertex AI based on user annotations
  /// 
  /// Creates detailed, technical prompts optimized for AI image editing models.
  /// Analyzes annotation data to provide context-specific instructions.
  static String generateSystemPrompt(List<AnnotationStroke> strokes) {
    final strokeCount = strokes.length;
    final totalPoints = strokes.fold<int>(0, (sum, stroke) => sum + stroke.points.length);
    final avgPointsPerStroke = (totalPoints / strokeCount).round();
    
    return '''
You are an expert AI image editing prompt generator. Analyze this image with user annotations and create a detailed prompt for an AI image editing model.

CONTEXT:
- User has marked $strokeCount distinct areas/objects for removal
- Total annotation points: $totalPoints (avg: $avgPointsPerStroke per stroke)
- User wants these marked objects completely removed from the image

ANNOTATION ANALYSIS:
${_generateAnnotationAnalysis(strokes)}

TASK:
Generate a precise, technical prompt for an AI image editing model that will:
1. Remove the marked objects cleanly using advanced inpainting techniques
2. Fill in the background realistically with content-aware reconstruction
3. Maintain consistent lighting and shadow blending
4. Preserve image quality, resolution, and visual coherence
5. Ensure seamless integration without visible artifacts

REQUIREMENTS FOR YOUR RESPONSE:
- Be specific about removal techniques (content-aware fill, edge-preserving smoothing)
- Include background reconstruction instructions based on surrounding context
- Specify lighting and shadow adjustment requirements
- Mention color harmony and contrast preservation
- Keep prompt focused and under 200 words
- Use technical language suitable for AI image processing

Format your response as a direct prompt ready for an AI image editing model.
''';
  }
  
  /// Analyzes annotation strokes to provide context for prompt generation
  static String _generateAnnotationAnalysis(List<AnnotationStroke> strokes) {
    final analysis = StringBuffer();
    
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final density = _calculateStrokeDensity(stroke);
      final coverage = _estimateCoverageArea(stroke);
      
      analysis.writeln('- Stroke ${i + 1}: ${stroke.points.length} points, '
          '${density.toStringAsFixed(1)} density, '
          '${coverage.toStringAsFixed(0)}px² estimated coverage');
    }
    
    return analysis.toString().trim();
  }
  
  /// Calculates stroke density for quality assessment
  static double _calculateStrokeDensity(AnnotationStroke stroke) {
    if (stroke.points.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];
      final dx = curr.dx - prev.dx;
      final dy = curr.dy - prev.dy;
      totalDistance += sqrt(dx * dx + dy * dy);
    }
    
    return stroke.points.length / (totalDistance + 1); // +1 to avoid division by zero
  }
  
  /// Estimates coverage area for prioritization
  static double _estimateCoverageArea(AnnotationStroke stroke) {
    if (stroke.points.isEmpty) return 0.0;
    
    double minX = stroke.points.first.dx;
    double maxX = minX;
    double minY = stroke.points.first.dy;
    double maxY = minY;
    
    for (final point in stroke.points) {
      minX = minX < point.dx ? minX : point.dx;
      maxX = maxX > point.dx ? maxX : point.dx;
      minY = minY < point.dy ? minY : point.dy;
      maxY = maxY > point.dy ? maxY : point.dy;
    }
    
    return (maxX - minX) * (maxY - minY);
  }
  
  /// Generates fallback prompt when detailed analysis is not available
  static String generateFallbackPrompt(int strokeCount) {
    return '''
Remove $strokeCount marked objects from this image using advanced content-aware fill and inpainting techniques. 
Reconstruct the background naturally where objects are removed, maintaining consistent lighting and color harmony. 
Apply edge-preserving smoothing to ensure seamless integration and preserve the original image quality and resolution. 
Use surrounding context to intelligently fill removed areas with appropriate textures and patterns.
'''.trim();
  }
}
