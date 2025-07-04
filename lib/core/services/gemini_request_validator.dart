import 'dart:typed_data';

import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/constants/gemini_constants.dart';

/// Validation result for API requests
class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  /// Creates a successful validation result
  const ValidationResult.success() : this._(isValid: true);

  /// Creates a failed validation result with error message
  const ValidationResult.failure(String errorMessage)
      : this._(isValid: false, errorMessage: errorMessage);

  /// Whether the validation passed
  final bool isValid;

  /// Error message if validation failed
  final String? errorMessage;
}

/// Validator for Gemini API requests
class GeminiRequestValidator {
  /// Validates a text prompt
  ValidationResult validatePrompt(String prompt) {
    final trimmedPrompt = prompt.trim();
    
    if (trimmedPrompt.isEmpty) {
      return const ValidationResult.failure(GeminiConstants.promptEmptyError);
    }
    
    if (trimmedPrompt.length > GeminiConstants.maxPromptLength) {
      return const ValidationResult.failure(GeminiConstants.promptTooLongError);
    }
    
    return const ValidationResult.success();
  }

  /// Validates image bytes
  ValidationResult validateImageBytes(Uint8List? imageBytes) {
    if (imageBytes == null) {
      return const ValidationResult.success(); // Optional image is valid
    }
    
    if (imageBytes.isEmpty) {
      return const ValidationResult.failure(GeminiConstants.imageEmptyError);
    }
    
    if (imageBytes.length > GeminiConstants.maxImageSizeBytes) {
      return const ValidationResult.failure(GeminiConstants.imageTooLargeError);
    }
    
    return const ValidationResult.success();
  }

  /// Validates API key
  ValidationResult validateApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) {
      return const ValidationResult.failure(GeminiConstants.apiKeyNotConfiguredError);
    }
    
    if (apiKey.length < GeminiConstants.minApiKeyLength) {
      return const ValidationResult.failure(GeminiConstants.invalidApiKeyFormatError);
    }
    
    return const ValidationResult.success();
  }

  /// Validates a complete API request
  ValidationResult validateApiRequest({
    required String prompt,
    Uint8List? imageBytes,
    String? model,
  }) {
    // Validate prompt
    final promptResult = validatePrompt(prompt);
    if (!promptResult.isValid) {
      return promptResult;
    }
    
    // Validate image bytes if provided
    final imageResult = validateImageBytes(imageBytes);
    if (!imageResult.isValid) {
      return imageResult;
    }
    
    // Validate API key
    final apiKey = EnvConfig.geminiApiKey;
    final apiKeyResult = validateApiKey(apiKey);
    if (!apiKeyResult.isValid) {
      return apiKeyResult;
    }
    
    return const ValidationResult.success();
  }

  /// Validates markers for editing prompts
  static ValidationResult validateMarkers(List<Map<String, dynamic>> markers) {
    if (markers.isEmpty) {
      return const ValidationResult.failure('At least one marker is required');
    }
    
    for (final marker in markers) {
      if (!marker.containsKey('x') || !marker.containsKey('y')) {
        return const ValidationResult.failure('Markers must contain x and y coordinates');
      }
      
      final x = marker['x'];
      final y = marker['y'];
      
      if (x is! num || y is! num) {
        return const ValidationResult.failure('Marker coordinates must be numbers');
      }
      
      if (x < 0 || y < 0) {
        return const ValidationResult.failure('Marker coordinates must be positive');
      }
    }
    
    return const ValidationResult.success();
  }

  /// Validates model name
  static ValidationResult validateModel(String? model) {
    if (model != null && model.trim().isEmpty) {
      return const ValidationResult.failure('Model name cannot be empty');
    }
    
    return const ValidationResult.success();
  }

  /// Validates confidence threshold for segmentation
  static ValidationResult validateConfidenceThreshold(double confidenceThreshold) {
    if (confidenceThreshold < 0.0 || confidenceThreshold > 1.0) {
      return const ValidationResult.failure('Confidence threshold must be between 0.0 and 1.0');
    }
    
    return const ValidationResult.success();
  }

  /// Validates a text-only request
  static ValidationResult validateTextRequest({
    required String prompt,
    String? model,
  }) {
    return validateApiRequest(
      prompt: prompt,
      imageBytes: null,
      model: model,
    );
  }

  /// Validates a multimodal request
  static ValidationResult validateMultimodalRequest({
    required String prompt,
    required Uint8List imageBytes,
    String? model,
  }) {
    return validateApiRequest(
      prompt: prompt,
      imageBytes: imageBytes,
      model: model,
    );
  }
}
