import 'dart:convert';
import 'dart:typed_data';

import 'package:revision/core/constants/gemini_constants.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

/// Builds requests for Gemini API
class GeminiRequestBuilder {
  const GeminiRequestBuilder(this._remoteConfig);

  final FirebaseAIRemoteConfigService _remoteConfig;

  /// Builds a text-only request
  Map<String, dynamic> buildTextOnlyRequest({
    required String prompt,
    String? model,
  }) {
    return {
      GeminiConstants.contentsKey: [
        {
          GeminiConstants.partsKey: [
            {GeminiConstants.textKey: prompt},
          ],
        },
      ],
      GeminiConstants.generationConfigKey: _buildGenerationConfig(),
    };
  }

  /// Builds a multimodal request with text and image
  Map<String, dynamic> buildMultimodalRequest({
    required String prompt,
    required Uint8List imageBytes,
    String? model,
  }) {
    final base64Image = base64Encode(imageBytes);

    return {
      GeminiConstants.contentsKey: [
        {
          GeminiConstants.partsKey: [
            {GeminiConstants.textKey: prompt},
            {
              GeminiConstants.inlineDataKey: {
                GeminiConstants.mimeTypeKey: GeminiConstants.defaultImageMimeType,
                GeminiConstants.dataKey: base64Image,
              },
            },
          ],
        },
      ],
      GeminiConstants.generationConfigKey: _buildGenerationConfig(),
    };
  }

  /// Builds an image generation request
  Map<String, dynamic> buildImageGenerationRequest({
    required String prompt,
    Uint8List? inputImage,
  }) {
    final parts = <Map<String, dynamic>>[
      {GeminiConstants.textKey: prompt},
    ];

    if (inputImage != null) {
      final base64Image = base64Encode(inputImage);
      parts.add({
        GeminiConstants.inlineDataKey: {
          GeminiConstants.mimeTypeKey: GeminiConstants.defaultImageMimeType,
          GeminiConstants.dataKey: base64Image,
        },
      });
    }

    return {
      GeminiConstants.contentsKey: [
        {
          GeminiConstants.partsKey: parts,
        },
      ],
      GeminiConstants.generationConfigKey: _buildImageGenerationConfig(),
    };
  }

  /// Builds a segmentation request with optimized configuration
  Map<String, dynamic> buildSegmentationRequest({
    required String prompt,
    required Uint8List imageBytes,
  }) {
    final base64Image = base64Encode(imageBytes);

    return {
      GeminiConstants.contentsKey: [
        {
          GeminiConstants.partsKey: [
            {GeminiConstants.textKey: prompt},
            {
              GeminiConstants.inlineDataKey: {
                GeminiConstants.mimeTypeKey: GeminiConstants.defaultImageMimeType,
                GeminiConstants.dataKey: base64Image,
              },
            },
          ],
        },
      ],
      GeminiConstants.generationConfigKey: _buildSegmentationConfig(),
      GeminiConstants.systemInstructionKey: {
        GeminiConstants.partsKey: [
          {
            GeminiConstants.textKey: 'You are an expert in computer vision and object segmentation. '
                'Provide accurate segmentation masks for the requested objects.',
          },
        ],
      },
      GeminiConstants.thinkingConfigKey: {
        GeminiConstants.thinkingBudgetKey: 0, // Disable thinking for better results
      },
    };
  }

  /// Builds an object detection request
  Map<String, dynamic> buildObjectDetectionRequest({
    required String prompt,
    required Uint8List imageBytes,
  }) {
    final base64Image = base64Encode(imageBytes);

    return {
      GeminiConstants.contentsKey: [
        {
          GeminiConstants.partsKey: [
            {GeminiConstants.textKey: prompt},
            {
              GeminiConstants.inlineDataKey: {
                GeminiConstants.mimeTypeKey: GeminiConstants.defaultImageMimeType,
                GeminiConstants.dataKey: base64Image,
              },
            },
          ],
        },
      ],
      GeminiConstants.generationConfigKey: _buildObjectDetectionConfig(),
    };
  }

  /// Builds standard generation configuration
  Map<String, dynamic> _buildGenerationConfig() {
    return {
      GeminiConstants.temperatureKey: _remoteConfig.temperature,
      GeminiConstants.maxOutputTokensKey: _remoteConfig.maxOutputTokens,
      GeminiConstants.topKKey: _remoteConfig.topK,
      GeminiConstants.topPKey: _remoteConfig.topP,
    };
  }

  /// Builds generation configuration for image generation
  Map<String, dynamic> _buildImageGenerationConfig() {
    return {
      GeminiConstants.temperatureKey: _remoteConfig.temperature * GeminiConstants.imageTemperatureMultiplier,
      GeminiConstants.maxOutputTokensKey: _remoteConfig.maxOutputTokens * 2,
      GeminiConstants.topKKey: GeminiConstants.defaultTopK,
      GeminiConstants.topPKey: GeminiConstants.defaultTopP,
    };
  }

  /// Builds generation configuration for segmentation
  Map<String, dynamic> _buildSegmentationConfig() {
    return {
      GeminiConstants.temperatureKey: GeminiConstants.lowTemperature, // Low for consistent results
      GeminiConstants.maxOutputTokensKey: _remoteConfig.maxOutputTokens,
      GeminiConstants.topKKey: GeminiConstants.defaultTopK,
      GeminiConstants.topPKey: GeminiConstants.defaultTopP,
      GeminiConstants.responseMimeTypeKey: GeminiConstants.applicationJsonMimeType,
    };
  }

  /// Builds generation configuration for object detection
  Map<String, dynamic> _buildObjectDetectionConfig() {
    return {
      GeminiConstants.temperatureKey: GeminiConstants.lowTemperature,
      GeminiConstants.maxOutputTokensKey: _remoteConfig.maxOutputTokens,
      GeminiConstants.topKKey: GeminiConstants.defaultTopK,
      GeminiConstants.topPKey: GeminiConstants.defaultTopP,
      GeminiConstants.responseMimeTypeKey: GeminiConstants.applicationJsonMimeType,
    };
  }

  /// Builds common prompt templates
  static String buildImageAnalysisPrompt(String userPrompt) {
    return '''
Analyze this image and provide editing instructions based on: $userPrompt

Focus on:
1. Object identification and removal suggestions
2. Background reconstruction techniques
3. Lighting and shadow adjustments
4. Color harmony maintenance

Provide clear, actionable editing steps.
''';
  }

  static String buildImageDescriptionPrompt() {
    return '''
Describe this image in detail for photo editing purposes.

Include:
1. Main subjects and objects
2. Lighting conditions
3. Colors and composition
4. Background elements
5. Overall mood and style

Keep the description clear and technical.
''';
  }

  static String buildEditingSuggestionsPrompt() {
    return '''
Analyze this image and provide 5 specific editing suggestions to improve it.

Focus on:
1. Object removal opportunities
2. Lighting improvements
3. Composition enhancements
4. Color corrections
5. Background improvements

Provide each suggestion as a clear, actionable sentence.
''';
  }

  static String buildContentSafetyPrompt() {
    return '''
Analyze this image for content safety. Is this image appropriate for a photo editing application?

Consider:
1. Does it contain inappropriate content?
2. Is it suitable for general audiences?
3. Does it violate content policies?

Respond with "SAFE" if appropriate, "UNSAFE" if not appropriate, followed by a brief reason.
''';
  }

  static String buildEditingPromptTemplate(String markerDescriptions) {
    return '''
Generate a detailed editing prompt for this image based on the user's markers:

$markerDescriptions

Create a comprehensive editing instruction that includes:
1. What objects/areas to modify
2. How to handle the background
3. Lighting and shadow considerations
4. Color matching requirements
5. Specific techniques to use

Provide a clear, actionable editing prompt.
''';
  }

  static String buildSegmentationPrompt({String? targetObjects}) {
    if (targetObjects != null && targetObjects.isNotEmpty) {
      return '''
Give the segmentation masks for the $targetObjects.
Output a JSON list of segmentation masks where each entry contains the 2D
bounding box in the key "box_2d", the segmentation mask in key "mask", and
the text label in the key "label". Use descriptive labels.
''';
    } else {
      return '''
Give the segmentation masks for all prominent objects in this image.
Output a JSON list of segmentation masks where each entry contains the 2D
bounding box in the key "box_2d", the segmentation mask in key "mask", and
the text label in the key "label". Use descriptive labels.
''';
    }
  }

  static String buildObjectDetectionPrompt({String? targetObjects}) {
    if (targetObjects != null && targetObjects.isNotEmpty) {
      return '''
Detect and provide bounding boxes for $targetObjects in this image.
Output a JSON list where each entry contains:
- "label": descriptive text label
- "bbox": normalized bounding box coordinates [x_min, y_min, x_max, y_max] (0-1 range)
- "confidence": detection confidence score (0-1 range)
''';
    } else {
      return '''
Detect all prominent objects in this image and provide their bounding boxes.
Output a JSON list where each entry contains:
- "label": descriptive text label  
- "bbox": normalized bounding box coordinates [x_min, y_min, x_max, y_max] (0-1 range)
- "confidence": detection confidence score (0-1 range)
''';
    }
  }

  static String buildImageGenerationPrompt(String editingPrompt) {
    return '''
Generate a new image based on this editing request: $editingPrompt

Create a high-quality image that represents the desired result after the editing operation.
Focus on creating a clean, professional result that matches the editing intent.
''';
  }
}
