import 'dart:async';
import 'dart:math';

import 'package:revision/core/utils/result.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Mock AI service for MVP demonstration.
///
/// This service simulates AI processing of images with realistic delays
/// and mock enhancement results for testing purposes.
class MockAiService {
  const MockAiService();

  /// Simulates AI-powered image enhancement.
  ///
  /// Returns enhanced image metadata after a realistic processing delay.
  Future<Result<EnhancedImage>> enhanceImage(SelectedImage image) async {
    // Simulate processing time
    await Future<void>.delayed(const Duration(seconds: 2));

    // Simulate occasional failures for testing
    if (Random().nextBool() && Random().nextDouble() < 0.1) {
      return Failure(
        Exception('AI service temporarily unavailable'),
      );
    }

    // Mock enhancement results
    final enhancedImage = EnhancedImage(
      originalImage: image,
      enhancementType: _getRandomEnhancement(),
      processingTime: Duration(seconds: 1 + Random().nextInt(3)),
      qualityScore: 0.7 + (Random().nextDouble() * 0.3), // 70-100%
      enhancements: _generateMockEnhancements(),
    );

    return Success(enhancedImage);
  }

  /// Simulates AI-powered image analysis.
  ///
  /// Returns analysis results with detected features and suggestions.
  Future<Result<ImageAnalysis>> analyzeImage(SelectedImage image) async {
    // Simulate analysis time
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final analysis = ImageAnalysis(
      image: image,
      detectedObjects: _generateMockObjects(),
      colorPalette: _generateMockColors(),
      qualityMetrics: _generateQualityMetrics(),
      suggestions: _generateSuggestions(),
    );

    return Success(analysis);
  }

  EnhancementType _getRandomEnhancement() {
    const enhancements = EnhancementType.values;
    return enhancements[Random().nextInt(enhancements.length)];
  }

  List<String> _generateMockEnhancements() {
    final possible = [
      'Brightness adjustment (+15%)',
      'Contrast enhancement (+20%)',
      'Color saturation boost',
      'Noise reduction applied',
      'Sharpness improvement',
      'Shadow detail recovery',
      'Highlight protection',
    ];

    final count = 2 + Random().nextInt(4); // 2-5 enhancements
    possible.shuffle();
    return possible.take(count).toList();
  }

  List<String> _generateMockObjects() {
    final objects = [
      'Person',
      'Face',
      'Car',
      'Building',
      'Tree',
      'Sky',
      'Water',
      'Food',
      'Animal',
      'Flower',
      'Text',
      'Logo',
    ];

    final count = 1 + Random().nextInt(4); // 1-4 objects
    objects.shuffle();
    return objects.take(count).toList();
  }

  List<String> _generateMockColors() {
    return ['#FF5733', '#33FF57', '#3357FF', '#FF33F1', '#F1FF33', '#33FFF1'];
  }

  QualityMetrics _generateQualityMetrics() {
    return QualityMetrics(
      sharpness: 0.6 + (Random().nextDouble() * 0.4),
      exposure: 0.5 + (Random().nextDouble() * 0.5),
      colorBalance: 0.7 + (Random().nextDouble() * 0.3),
      noise: Random().nextDouble() * 0.3, // Lower is better
    );
  }

  List<String> _generateSuggestions() {
    final suggestions = [
      'Consider brightening the image for better visibility',
      'The composition could benefit from rule of thirds',
      'Try increasing contrast for more dramatic effect',
      'Colors appear well-balanced in this image',
      'Good exposure levels detected',
      'Consider cropping to focus on the main subject',
    ];

    suggestions.shuffle();
    return suggestions.take(2 + Random().nextInt(3)).toList();
  }
}

/// Represents an AI-enhanced image with processing metadata.
class EnhancedImage {
  const EnhancedImage({
    required this.originalImage,
    required this.enhancementType,
    required this.processingTime,
    required this.qualityScore,
    required this.enhancements,
  });

  final SelectedImage originalImage;
  final EnhancementType enhancementType;
  final Duration processingTime;
  final double qualityScore;
  final List<String> enhancements;
}

/// Types of AI enhancements available.
enum EnhancementType {
  auto('Auto Enhance'),
  portrait('Portrait Mode'),
  landscape('Landscape'),
  lowLight('Low Light'),
  vibrant('Vibrant Colors'),
  vintage('Vintage Style');

  const EnhancementType(this.displayName);
  final String displayName;
}

/// AI analysis results for an image.
class ImageAnalysis {
  const ImageAnalysis({
    required this.image,
    required this.detectedObjects,
    required this.colorPalette,
    required this.qualityMetrics,
    required this.suggestions,
  });

  final SelectedImage image;
  final List<String> detectedObjects;
  final List<String> colorPalette;
  final QualityMetrics qualityMetrics;
  final List<String> suggestions;
}

/// Quality metrics for image analysis.
class QualityMetrics {
  const QualityMetrics({
    required this.sharpness,
    required this.exposure,
    required this.colorBalance,
    required this.noise,
  });

  final double sharpness; // 0.0 - 1.0
  final double exposure; // 0.0 - 1.0
  final double colorBalance; // 0.0 - 1.0
  final double noise; // 0.0 - 1.0 (lower is better)
}
