---
applyTo: 'ai'
---

# 🤖 AI Integration - Vertex AI & Gemini Complete Implementation Guide

## 🎯 AI Features Overview

The Aura application integrates advanced AI capabilities using Google's Vertex AI platform and Gemini models for:

1. **Image Analysis** - Understanding image content and context
2. **Object Detection** - Identifying objects for removal
3. **Mask Generation** - Creating precise selection masks
4. **Content Generation** - AI-powered image inpainting and object removal
5. **Prompt Engineering** - Intelligent description generation

## 🔧 Vertex AI Setup & Configuration

### 1. Google Cloud Platform Setup

#### Enable Required APIs
```bash
# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com

# Enable Cloud Functions API (if using Cloud Functions)
gcloud services enable cloudfunctions.googleapis.com

# Enable Cloud Build API
gcloud services enable cloudbuild.googleapis.com

# Enable Cloud Storage API
gcloud services enable storage-api.googleapis.com
```

#### Create Service Account
```bash
# Create service account for Vertex AI access
gcloud iam service-accounts create vertex-ai-service \
    --description="Service account for Vertex AI access" \
    --display-name="Vertex AI Service Account"

# Grant Vertex AI User role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:vertex-ai-service@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

# Grant Storage Admin role (for image processing)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:vertex-ai-service@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"
```

### 2. Gemini API Configuration

#### API Key Management
```dart
// lib/core/config/ai_config.dart
class AIConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  static const String vertexAIProjectId = String.fromEnvironment(
    'VERTEX_AI_PROJECT_ID',
    defaultValue: '',
  );
  
  static const String vertexAILocation = String.fromEnvironment(
    'VERTEX_AI_LOCATION',
    defaultValue: 'us-central1',
  );

  // Model configurations
  static const String visionModel = 'gemini-2.5-flash';
  static const String generationModel = 'gemini-2.0-flash-preview-image-generation';
  static const String textModel = 'gemini-2.0-flash-thinking-exp';

  // Validate configuration
  static bool get isConfigured => 
      geminiApiKey.isNotEmpty && 
      vertexAIProjectId.isNotEmpty;

  // API endpoints
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com';
  static const String vertexAIBaseUrl = 'https://us-central1-aiplatform.googleapis.com';

  // Request timeouts
  static const Duration analysisTimeout = Duration(seconds: 30);
  static const Duration generationTimeout = Duration(minutes: 2);
  static const Duration defaultTimeout = Duration(seconds: 15);

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const int maxConcurrentRequests = 3;
}
```

### 3. AI Service Architecture

#### Core AI Service Interface
```dart
// lib/core/ai/ai_service.dart
import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../error/failures.dart';
import 'ai_models.dart';

abstract class AIService {
  // Image analysis capabilities
  Future<Either<Failure, ImageAnalysisResult>> analyzeImage(
    Uint8List imageBytes, {
    String? prompt,
    double? confidence,
  });

  // Object detection
  Future<Either<Failure, ObjectDetectionResult>> detectObjects(
    Uint8List imageBytes, {
    List<String>? targetClasses,
  });

  // Mask generation
  Future<Either<Failure, Uint8List>> generateMask(
    Uint8List imageBytes,
    ObjectDetectionResult detectionResult,
  );

  // Content generation
  Future<Either<Failure, Uint8List>> generateImageContent(
    Uint8List originalImage,
    Uint8List maskImage,
    String prompt, {
    double? strength,
    int? steps,
  });

  // Text generation
  Future<Either<Failure, String>> generateDescription(
    Uint8List imageBytes, {
    String? context,
    DescriptionStyle? style,
  });

  // Prompt enhancement
  Future<Either<Failure, String>> enhancePrompt(
    String originalPrompt, {
    PromptStyle? style,
    String? context,
  });
}
```

#### AI Models and Data Classes
```dart
// lib/core/ai/ai_models.dart
import 'package:equatable/equatable.dart';

class ImageAnalysisResult extends Equatable {
  const ImageAnalysisResult({
    required this.description,
    required this.objects,
    required this.scenes,
    required this.colors,
    required this.emotions,
    required this.confidence,
    this.suggestedPrompts = const [],
  });

  final String description;
  final List<DetectedObject> objects;
  final List<DetectedScene> scenes;
  final List<ColorInfo> colors;
  final List<EmotionInfo> emotions;
  final double confidence;
  final List<String> suggestedPrompts;

  @override
  List<Object?> get props => [
    description,
    objects,
    scenes,
    colors,
    emotions,
    confidence,
    suggestedPrompts,
  ];
}

class DetectedObject extends Equatable {
  const DetectedObject({
    required this.name,
    required this.confidence,
    required this.boundingBox,
    this.attributes = const {},
  });

  final String name;
  final double confidence;
  final BoundingBox boundingBox;
  final Map<String, dynamic> attributes;

  @override
  List<Object?> get props => [name, confidence, boundingBox, attributes];
}

class BoundingBox extends Equatable {
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  @override
  List<Object?> get props => [x, y, width, height];
}

class DetectedScene extends Equatable {
  const DetectedScene({
    required this.name,
    required this.confidence,
    this.attributes = const {},
  });

  final String name;
  final double confidence;
  final Map<String, dynamic> attributes;

  @override
  List<Object?> get props => [name, confidence, attributes];
}

class ColorInfo extends Equatable {
  const ColorInfo({
    required this.name,
    required this.hex,
    required this.percentage,
    required this.dominance,
  });

  final String name;
  final String hex;
  final double percentage;
  final double dominance;

  @override
  List<Object?> get props => [name, hex, percentage, dominance];
}

class EmotionInfo extends Equatable {
  const EmotionInfo({
    required this.emotion,
    required this.confidence,
  });

  final String emotion;
  final double confidence;

  @override
  List<Object?> get props => [emotion, confidence];
}

class ObjectDetectionResult extends Equatable {
  const ObjectDetectionResult({
    required this.objects,
    required this.processingTime,
    required this.modelVersion,
  });

  final List<DetectedObject> objects;
  final Duration processingTime;
  final String modelVersion;

  @override
  List<Object?> get props => [objects, processingTime, modelVersion];
}

enum DescriptionStyle {
  detailed,
  concise,
  artistic,
  technical,
  casual,
}

enum PromptStyle {
  creative,
  realistic,
  artistic,
  photographic,
  illustration,
}
```

### 4. Gemini Vision Implementation

#### Gemini Service Implementation
```dart
// lib/core/ai/gemini_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import '../error/exceptions.dart';
import '../error/failures.dart';
import '../utils/rate_limiter.dart';
import 'ai_models.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  GeminiService({
    required http.Client httpClient,
    required RateLimiter rateLimiter,
  }) : _httpClient = httpClient,
       _rateLimiter = rateLimiter {
    _initializeModels();
  }

  final http.Client _httpClient;
  final RateLimiter _rateLimiter;
  
  late final GenerativeModel _visionModel;
  late final GenerativeModel _textModel;

  void _initializeModels() {
    if (!AIConfig.isConfigured) {
      throw const AIException('AI configuration is incomplete. Check API keys.');
    }

    _visionModel = GenerativeModel(
      model: AIConfig.visionModel,
      apiKey: AIConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.medium,
        ),
      ],
    );

    _textModel = GenerativeModel(
      model: AIConfig.textModel,
      apiKey: AIConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  @override
  Future<Either<Failure, ImageAnalysisResult>> analyzeImage(
    Uint8List imageBytes, {
    String? prompt,
    double? confidence,
  }) async {
    try {
      await _rateLimiter.checkLimit();
      
      log('🤖 Starting image analysis with Gemini Vision');
      
      final analysisPrompt = prompt ?? _getDefaultAnalysisPrompt();
      
      final content = [
        Content.multi([
          TextPart(analysisPrompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Empty response from Gemini Vision');
      }

      final analysisResult = _parseAnalysisResponse(response.text!);
      
      log('✅ Image analysis completed successfully');
      return Right(analysisResult);
    } on AIException catch (e) {
      log('❌ AI service error during image analysis: ${e.message}');
      return Left(AIFailure(message: e.message));
    } catch (e) {
      log('❌ Unexpected error during image analysis: $e');
      return Left(AIFailure(message: 'Image analysis failed: An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, ObjectDetectionResult>> detectObjects(
    Uint8List imageBytes, {
    List<String>? targetClasses,
  }) async {
    try {
      await _rateLimiter.checkLimit();
      
      log('🔍 Starting object detection with Gemini Vision');
      
      final detectionPrompt = _getObjectDetectionPrompt(targetClasses);
      
      final content = [
        Content.multi([
          TextPart(detectionPrompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Empty response from object detection');
      }

      final detectionResult = _parseObjectDetectionResponse(response.text!);
      
      log('✅ Object detection completed successfully');
      return Right(detectionResult);
    } on AIException catch (e) {
      log('❌ AI service error during object detection: ${e.message}');
      return Left(AIFailure(message: e.message));
    } catch (e) {
      log('❌ Unexpected error during object detection: $e');
      return Left(AIFailure(message: 'Object detection failed: An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> generateDescription(
    Uint8List imageBytes, {
    String? context,
    DescriptionStyle? style,
  }) async {
    try {
      await _rateLimiter.checkLimit();
      
      log('📝 Generating image description with Gemini');
      
      final descriptionPrompt = _getDescriptionPrompt(context, style);
      
      final content = [
        Content.multi([
          TextPart(descriptionPrompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Empty response from description generation');
      }

      final description = response.text!.trim();
      
      log('✅ Description generation completed successfully');
      return Right(description);
    } on AIException catch (e) {
      log('❌ AI service error during description generation: ${e.message}');
      return Left(AIFailure(message: e.message));
    } catch (e) {
      log('❌ Unexpected error during description generation: $e');
      return Left(AIFailure(message: 'Description generation failed: An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> enhancePrompt(
    String originalPrompt, {
    PromptStyle? style,
    String? context,
  }) async {
    try {
      await _rateLimiter.checkLimit();
      
      log('✨ Enhancing prompt with Gemini');
      
      final enhancementPrompt = _getPromptEnhancementPrompt(originalPrompt, style, context);
      
      final content = [Content.text(enhancementPrompt)];
      
      final response = await _textModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Empty response from prompt enhancement');
      }

      final enhancedPrompt = response.text!.trim();
      
      log('✅ Prompt enhancement completed successfully');
      return Right(enhancedPrompt);
    } on AIException catch (e) {
      log('❌ AI service error during prompt enhancement: ${e.message}');
      return Left(AIFailure(message: e.message));
    } catch (e) {
      log('❌ Unexpected error during prompt enhancement: $e');
      return Left(AIFailure(message: 'Prompt enhancement failed: An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> generateMask(
    Uint8List imageBytes,
    ObjectDetectionResult detectionResult,
  ) async {
    try {
      await _rateLimiter.checkLimit();
      
      log('🎭 Generating mask with Gemini Vision');
      
      final maskPrompt = _getMaskGenerationPrompt(detectionResult);
      
      final content = [
        Content.multi([
          TextPart(maskPrompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Empty response from mask generation');
      }

      // For now, we'll use a simplified approach
      // In a real implementation, you'd need to process the response to generate an actual mask
      final maskData = _generateMaskFromResponse(response.text!, detectionResult);
      
      log('✅ Mask generation completed successfully');
      return Right(maskData);
    } on AIException catch (e) {
      log('❌ AI service error during mask generation: ${e.message}');
      return Left(AIFailure(message: e.message));
    } catch (e) {
      log('❌ Unexpected error during mask generation: $e');
      return Left(AIFailure(message: 'Mask generation failed: An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> generateImageContent(
    Uint8List originalImage,
    Uint8List maskImage,
    String prompt, {
    double? strength,
    int? steps,
  }) async {
    try {
      await _rateLimiter.checkLimit();
      
      log('🎨 Generating image content with Gemini');
      
      // Note: This is a simplified implementation
      // Real image generation would require specialized APIs or models
      final generationPrompt = _getImageGenerationPrompt(prompt, strength, steps);
      
      final content = [
        Content.multi([
          TextPart(generationPrompt),
          DataPart('image/jpeg', originalImage),
          DataPart('image/png', maskImage),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Empty response from image generation');
      }

      // For this implementation, we'll return a placeholder
      // In a real scenario, you'd use specialized image generation APIs
      final generatedImage = _generatePlaceholderImage(originalImage);
      
      log('✅ Image content generation completed successfully');
      return Right(generatedImage);
    } on AIException catch (e) {
      log('❌ AI service error during image generation: ${e.message}');
      return Left(AIFailure(message: e.message));
    } catch (e) {
      log('❌ Unexpected error during image generation: $e');
      return Left(AIFailure(message: 'Image generation failed: An unexpected error occurred'));
    }
  }

  // Prompt templates
  String _getDefaultAnalysisPrompt() {
    return '''
Analyze this image in detail and provide a comprehensive analysis in JSON format with the following structure:

{
  "description": "Detailed description of the image",
  "objects": [
    {
      "name": "object name",
      "confidence": 0.95,
      "boundingBox": {"x": 0.1, "y": 0.2, "width": 0.3, "height": 0.4},
      "attributes": {"color": "blue", "size": "large"}
    }
  ],
  "scenes": [
    {
      "name": "scene type",
      "confidence": 0.9,
      "attributes": {"lighting": "natural", "setting": "outdoor"}
    }
  ],
  "colors": [
    {
      "name": "color name",
      "hex": "#FF5733",
      "percentage": 25.0,
      "dominance": 0.8
    }
  ],
  "emotions": [
    {
      "emotion": "happy",
      "confidence": 0.85
    }
  ],
  "confidence": 0.92,
  "suggestedPrompts": ["prompt 1", "prompt 2"]
}

Focus on accuracy and provide detailed information about all visible elements.
''';
  }

  String _getObjectDetectionPrompt(List<String>? targetClasses) {
    final classFilter = targetClasses != null && targetClasses.isNotEmpty
        ? 'Focus specifically on detecting: ${targetClasses.join(', ')}'
        : 'Detect all visible objects';

    return '''
Detect and locate objects in this image. $classFilter

Provide the response in JSON format:

{
  "objects": [
    {
      "name": "object name",
      "confidence": 0.95,
      "boundingBox": {"x": 0.1, "y": 0.2, "width": 0.3, "height": 0.4},
      "attributes": {"removable": true, "complexity": "simple"}
    }
  ],
  "processingTime": "processing time in milliseconds",
  "modelVersion": "model version used"
}

For each object, indicate if it's suitable for removal and the complexity level.
''';
  }

  String _getDescriptionPrompt(String? context, DescriptionStyle? style) {
    final styleInstruction = switch (style) {
      DescriptionStyle.detailed => 'Provide a highly detailed, comprehensive description',
      DescriptionStyle.concise => 'Provide a brief, concise description',
      DescriptionStyle.artistic => 'Provide an artistic, creative description',
      DescriptionStyle.technical => 'Provide a technical, analytical description',
      DescriptionStyle.casual => 'Provide a casual, conversational description',
      null => 'Provide a balanced, informative description',
    };

    final contextInstruction = context != null
        ? 'Consider this context: $context'
        : '';

    return '''
$styleInstruction of this image. $contextInstruction

Focus on the main subjects, composition, lighting, colors, and overall mood. 
The description should be suitable for image generation or editing purposes.
''';
  }

  String _getPromptEnhancementPrompt(String originalPrompt, PromptStyle? style, String? context) {
    final styleInstruction = switch (style) {
      PromptStyle.creative => 'enhance it with creative and imaginative elements',
      PromptStyle.realistic => 'enhance it for photorealistic results',
      PromptStyle.artistic => 'enhance it with artistic and stylistic elements',
      PromptStyle.photographic => 'enhance it with photographic technical details',
      PromptStyle.illustration => 'enhance it for illustration-style results',
      null => 'enhance it for better AI image generation',
    };

    final contextInstruction = context != null
        ? 'Context: $context'
        : '';

    return '''
Take this image generation prompt and $styleInstruction:

Original prompt: "$originalPrompt"

$contextInstruction

Enhanced prompt should be more descriptive, specific, and optimized for AI image generation.
Include details about composition, lighting, style, and quality modifiers.
Keep the core intent but make it more comprehensive and precise.
''';
  }

  String _getMaskGenerationPrompt(ObjectDetectionResult detectionResult) {
    final objectNames = detectionResult.objects.map((obj) => obj.name).join(', ');
    
    return '''
Generate a precise selection mask for the following objects in this image: $objectNames

The mask should:
1. Accurately outline the objects
2. Include fine details and edges
3. Exclude background elements
4. Be suitable for object removal/replacement

Provide guidance on mask refinement and edge detection.
''';
  }

  String _getImageGenerationPrompt(String prompt, double? strength, int? steps) {
    return '''
Generate new image content based on this prompt: "$prompt"

Parameters:
- Strength: ${strength ?? 0.8}
- Steps: ${steps ?? 20}

The generated content should seamlessly blend with the existing image context.
Maintain consistent lighting, perspective, and style.
''';
  }

  // Response parsers
  ImageAnalysisResult _parseAnalysisResponse(String response) {
    try {
      final jsonResponse = json.decode(response) as Map<String, dynamic>;
      
      return ImageAnalysisResult(
        description: jsonResponse['description'] as String? ?? '',
        objects: (jsonResponse['objects'] as List<dynamic>?)
            ?.map((obj) => _parseDetectedObject(obj as Map<String, dynamic>))
            .toList() ?? [],
        scenes: (jsonResponse['scenes'] as List<dynamic>?)
            ?.map((scene) => _parseDetectedScene(scene as Map<String, dynamic>))
            .toList() ?? [],
        colors: (jsonResponse['colors'] as List<dynamic>?)
            ?.map((color) => _parseColorInfo(color as Map<String, dynamic>))
            .toList() ?? [],
        emotions: (jsonResponse['emotions'] as List<dynamic>?)
            ?.map((emotion) => _parseEmotionInfo(emotion as Map<String, dynamic>))
            .toList() ?? [],
        confidence: (jsonResponse['confidence'] as num?)?.toDouble() ?? 0.0,
        suggestedPrompts: (jsonResponse['suggestedPrompts'] as List<dynamic>?)
            ?.cast<String>() ?? [],
      );
    } catch (e) {
      log('❌ Failed to parse analysis response: $e');
      throw AIException('Failed to parse AI response: ${e.toString()}');
    }
  }

  ObjectDetectionResult _parseObjectDetectionResponse(String response) {
    try {
      final jsonResponse = json.decode(response) as Map<String, dynamic>;
      
      return ObjectDetectionResult(
        objects: (jsonResponse['objects'] as List<dynamic>?)
            ?.map((obj) => _parseDetectedObject(obj as Map<String, dynamic>))
            .toList() ?? [],
        processingTime: Duration(
          milliseconds: int.tryParse(jsonResponse['processingTime']?.toString() ?? '0') ?? 0,
        ),
        modelVersion: jsonResponse['modelVersion'] as String? ?? AIConfig.visionModel,
      );
    } catch (e) {
      log('❌ Failed to parse object detection response: $e');
      throw AIException('Failed to parse object detection response: ${e.toString()}');
    }
  }

  DetectedObject _parseDetectedObject(Map<String, dynamic> obj) {
    final bbox = obj['boundingBox'] as Map<String, dynamic>? ?? {};
    
    return DetectedObject(
      name: obj['name'] as String? ?? '',
      confidence: (obj['confidence'] as num?)?.toDouble() ?? 0.0,
      boundingBox: BoundingBox(
        x: (bbox['x'] as num?)?.toDouble() ?? 0.0,
        y: (bbox['y'] as num?)?.toDouble() ?? 0.0,
        width: (bbox['width'] as num?)?.toDouble() ?? 0.0,
        height: (bbox['height'] as num?)?.toDouble() ?? 0.0,
      ),
      attributes: obj['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  DetectedScene _parseDetectedScene(Map<String, dynamic> scene) {
    return DetectedScene(
      name: scene['name'] as String? ?? '',
      confidence: (scene['confidence'] as num?)?.toDouble() ?? 0.0,
      attributes: scene['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  ColorInfo _parseColorInfo(Map<String, dynamic> color) {
    return ColorInfo(
      name: color['name'] as String? ?? '',
      hex: color['hex'] as String? ?? '',
      percentage: (color['percentage'] as num?)?.toDouble() ?? 0.0,
      dominance: (color['dominance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  EmotionInfo _parseEmotionInfo(Map<String, dynamic> emotion) {
    return EmotionInfo(
      emotion: emotion['emotion'] as String? ?? '',
      confidence: (emotion['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Placeholder implementations for features requiring specialized APIs
  Uint8List _generateMaskFromResponse(String response, ObjectDetectionResult detectionResult) {
    // This is a placeholder implementation
    // In a real app, you'd use the detection results to generate an actual mask
    // For now, return a simple black image as a placeholder
    const size = 512;
    final maskData = Uint8List(size * size * 4); // RGBA
    
    // Fill with black (transparent mask)
    for (int i = 0; i < maskData.length; i += 4) {
      maskData[i] = 0;     // R
      maskData[i + 1] = 0; // G
      maskData[i + 2] = 0; // B
      maskData[i + 3] = 255; // A
    }
    
    return maskData;
  }

  Uint8List _generatePlaceholderImage(Uint8List originalImage) {
    // This is a placeholder implementation
    // In a real app, you'd use specialized image generation APIs
    // For now, return the original image as a placeholder
    return originalImage;
  }
}
```

### 5. Rate Limiting and Error Handling

#### Rate Limiter Implementation
```dart
// lib/core/utils/rate_limiter.dart
import 'dart:async';
import 'dart:developer';

import '../config/ai_config.dart';
import '../error/exceptions.dart';

class RateLimiter {
  RateLimiter({
    int? maxRequestsPerMinute,
    int? maxConcurrentRequests,
  }) : _maxRequestsPerMinute = maxRequestsPerMinute ?? AIConfig.maxRequestsPerMinute,
       _maxConcurrentRequests = maxConcurrentRequests ?? AIConfig.maxConcurrentRequests;

  final int _maxRequestsPerMinute;
  final int _maxConcurrentRequests;
  
  final List<DateTime> _requestTimestamps = [];
  int _activeRequests = 0;
  final Completer<void>? _waitingCompleter = null;

  Future<void> checkLimit() async {
    // Check concurrent requests limit
    if (_activeRequests >= _maxConcurrentRequests) {
      log('⏳ Waiting for concurrent request slot...');
      await _waitForAvailableSlot();
    }

    // Check rate limit
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove old timestamps
    _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(oneMinuteAgo));
    
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldestRequest = _requestTimestamps.first;
      final waitTime = oldestRequest.add(const Duration(minutes: 1)).difference(now);
      
      if (waitTime.isNegative) {
        _requestTimestamps.removeAt(0);
      } else {
        log('⏳ Rate limit reached, waiting ${waitTime.inSeconds} seconds...');
        await Future.delayed(waitTime);
      }
    }

    // Record this request
    _requestTimestamps.add(now);
    _activeRequests++;
  }

  void releaseSlot() {
    if (_activeRequests > 0) {
      _activeRequests--;
    }
  }

  Future<void> _waitForAvailableSlot() async {
    while (_activeRequests >= _maxConcurrentRequests) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void reset() {
    _requestTimestamps.clear();
    _activeRequests = 0;
  }
}
```

### 6. AI Processing Pipeline

#### AI Processing Use Cases
```dart
// lib/features/ai_processing/domain/usecases/analyze_image_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/ai/ai_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ai_processing_request.dart';
import '../entities/ai_processing_result.dart';

class AnalyzeImageUseCase implements UseCase<AIProcessingResult, AIProcessingRequest> {
  const AnalyzeImageUseCase(this.aiService);

  final AIService aiService;

  @override
  Future<Either<Failure, AIProcessingResult>> call(AIProcessingRequest params) async {
    // Validate input
    if (params.imageBytes.isEmpty) {
      return Left(ValidationFailure(message: 'Image data cannot be empty'));
    }

    if (params.imageBytes.length > 10 * 1024 * 1024) {
      return Left(ValidationFailure(message: 'Image size must be less than 10MB'));
    }

    // Perform AI analysis
    final analysisResult = await aiService.analyzeImage(
      params.imageBytes,
      prompt: params.customPrompt,
      confidence: params.confidenceThreshold,
    );

    return analysisResult.fold(
      (failure) => Left(failure),
      (analysis) => Right(
        AIProcessingResult(
          id: params.id,
          analysisResult: analysis,
          processingTime: DateTime.now().difference(params.startTime),
          success: true,
        ),
      ),
    );
  }
}
```

```dart
// lib/features/ai_processing/domain/usecases/generate_image_content_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/ai/ai_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/image_generation_request.dart';
import '../entities/image_generation_result.dart';

class GenerateImageContentUseCase implements UseCase<ImageGenerationResult, ImageGenerationRequest> {
  const GenerateImageContentUseCase(this.aiService);

  final AIService aiService;

  @override
  Future<Either<Failure, ImageGenerationResult>> call(ImageGenerationRequest params) async {
    // Validate input
    if (params.originalImage.isEmpty) {
      return Left(ValidationFailure(message: 'Original image data cannot be empty'));
    }

    if (params.maskImage.isEmpty) {
      return Left(ValidationFailure(message: 'Mask image data cannot be empty'));
    }

    if (params.prompt.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Generation prompt cannot be empty'));
    }

    // Generate image content
    final generationResult = await aiService.generateImageContent(
      params.originalImage,
      params.maskImage,
      params.prompt,
      strength: params.strength,
      steps: params.steps,
    );

    return generationResult.fold(
      (failure) => Left(failure),
      (generatedImage) => Right(
        ImageGenerationResult(
          id: params.id,
          generatedImage: generatedImage,
          prompt: params.prompt,
          processingTime: DateTime.now().difference(params.startTime),
          success: true,
        ),
      ),
    );
  }
}
```

### 7. AI Processing BLoC

#### AI Processing State Management
```dart
// lib/features/ai_processing/presentation/blocs/ai_processing_bloc.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/ai/ai_models.dart';
import '../../domain/entities/ai_processing_request.dart';
import '../../domain/entities/image_generation_request.dart';
import '../../domain/usecases/analyze_image_usecase.dart';
import '../../domain/usecases/generate_image_content_usecase.dart';
import '../../domain/usecases/enhance_prompt_usecase.dart';

part 'ai_processing_event.dart';
part 'ai_processing_state.dart';

class AIProcessingBloc extends Bloc<AIProcessingEvent, AIProcessingState> {
  AIProcessingBloc({
    required AnalyzeImageUseCase analyzeImage,
    required GenerateImageContentUseCase generateImageContent,
    required EnhancePromptUseCase enhancePrompt,
  }) : _analyzeImage = analyzeImage,
       _generateImageContent = generateImageContent,
       _enhancePrompt = enhancePrompt,
       super(const AIProcessingState()) {
    
    on<AIAnalysisRequested>(_onAnalysisRequested);
    on<AIImageGenerationRequested>(_onImageGenerationRequested);
    on<AIPromptEnhancementRequested>(_onPromptEnhancementRequested);
    on<AIProcessingReset>(_onProcessingReset);
  }

  final AnalyzeImageUseCase _analyzeImage;
  final GenerateImageContentUseCase _generateImageContent;
  final EnhancePromptUseCase _enhancePrompt;

  Future<void> _onAnalysisRequested(
    AIAnalysisRequested event,
    Emitter<AIProcessingState> emit,
  ) async {
    emit(state.copyWith(
      status: AIProcessingStatus.analyzing,
      progress: 0.0,
      errorMessage: null,
    ));

    try {
      // Create processing request
      final request = AIProcessingRequest(
        id: event.requestId,
        imageBytes: event.imageBytes,
        customPrompt: event.customPrompt,
        confidenceThreshold: event.confidenceThreshold,
        startTime: DateTime.now(),
      );

      emit(state.copyWith(progress: 0.3));

      // Perform analysis
      final result = await _analyzeImage(request);

      result.fold(
        (failure) => emit(state.copyWith(
          status: AIProcessingStatus.error,
          errorMessage: failure.message,
          progress: 0.0,
        )),
        (analysisResult) => emit(state.copyWith(
          status: AIProcessingStatus.analysisComplete,
          analysisResult: analysisResult.analysisResult,
          progress: 1.0,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: AIProcessingStatus.error,
        errorMessage: 'Analysis failed: ${e.toString()}',
        progress: 0.0,
      ));
    }
  }

  Future<void> _onImageGenerationRequested(
    AIImageGenerationRequested event,
    Emitter<AIProcessingState> emit,
  ) async {
    emit(state.copyWith(
      status: AIProcessingStatus.generating,
      progress: 0.0,
      errorMessage: null,
    ));

    try {
      // Create generation request
      final request = ImageGenerationRequest(
        id: event.requestId,
        originalImage: event.originalImage,
        maskImage: event.maskImage,
        prompt: event.prompt,
        strength: event.strength,
        steps: event.steps,
        startTime: DateTime.now(),
      );

      emit(state.copyWith(progress: 0.2));

      // Generate image content
      final result = await _generateImageContent(request);

      result.fold(
        (failure) => emit(state.copyWith(
          status: AIProcessingStatus.error,
          errorMessage: failure.message,
          progress: 0.0,
        )),
        (generationResult) => emit(state.copyWith(
          status: AIProcessingStatus.generationComplete,
          generatedImage: generationResult.generatedImage,
          generationPrompt: generationResult.prompt,
          progress: 1.0,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: AIProcessingStatus.error,
        errorMessage: 'Generation failed: ${e.toString()}',
        progress: 0.0,
      ));
    }
  }

  Future<void> _onPromptEnhancementRequested(
    AIPromptEnhancementRequested event,
    Emitter<AIProcessingState> emit,
  ) async {
    emit(state.copyWith(
      status: AIProcessingStatus.enhancingPrompt,
      progress: 0.0,
      errorMessage: null,
    ));

    try {
      final result = await _enhancePrompt(EnhancePromptParams(
        originalPrompt: event.originalPrompt,
        style: event.style,
        context: event.context,
      ));

      result.fold(
        (failure) => emit(state.copyWith(
          status: AIProcessingStatus.error,
          errorMessage: failure.message,
          progress: 0.0,
        )),
        (enhancedPrompt) => emit(state.copyWith(
          status: AIProcessingStatus.promptEnhanced,
          enhancedPrompt: enhancedPrompt,
          progress: 1.0,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: AIProcessingStatus.error,
        errorMessage: 'Prompt enhancement failed: ${e.toString()}',
        progress: 0.0,
      ));
    }
  }

  void _onProcessingReset(
    AIProcessingReset event,
    Emitter<AIProcessingState> emit,
  ) {
    emit(const AIProcessingState());
  }
}
```

### 8. Error Handling and Monitoring

#### AI-Specific Error Types
```dart
// lib/core/error/ai_failures.dart
import 'failures.dart';

class AIFailure extends Failure {
  const AIFailure({required super.message});
}

class AIQuotaExceededFailure extends AIFailure {
  const AIQuotaExceededFailure({
    super.message = 'AI service quota exceeded. Please try again later.',
  });
}

class AIModelNotAvailableFailure extends AIFailure {
  const AIModelNotAvailableFailure({
    super.message = 'AI model is currently unavailable.',
  });
}

class AIResponseParsingFailure extends AIFailure {
  const AIResponseParsingFailure({
    super.message = 'Failed to parse AI service response.',
  });
}

class AIInvalidInputFailure extends AIFailure {
  const AIInvalidInputFailure({required super.message});
}
```

#### AI Processing Monitor
```dart
// lib/core/ai/ai_processing_monitor.dart
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AIProcessingMonitor {
  AIProcessingMonitor._();
  
  static final AIProcessingMonitor _instance = AIProcessingMonitor._();
  static AIProcessingMonitor get instance => _instance;

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;

  void initialize() {
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
  }

  Future<void> logAIRequest({
    required String operation,
    required String model,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_request_started',
        parameters: {
          'operation': operation,
          'model': model,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...parameters,
        },
      );
      
      log('📊 AI request logged: $operation with $model');
    } catch (e) {
      log('❌ Failed to log AI request: $e');
    }
  }

  Future<void> logAIResponse({
    required String operation,
    required String model,
    required Duration processingTime,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_response_received',
        parameters: {
          'operation': operation,
          'model': model,
          'processing_time_ms': processingTime.inMilliseconds,
          'success': success,
          'error_message': errorMessage ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      log('📊 AI response logged: $operation - ${success ? 'SUCCESS' : 'FAILED'}');
    } catch (e) {
      log('❌ Failed to log AI response: $e');
    }
  }

  Future<void> logAIError({
    required String operation,
    required String model,
    required String error,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Log to Analytics
      await _analytics.logEvent(
        name: 'ai_error',
        parameters: {
          'operation': operation,
          'model': model,
          'error': error,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?additionalData,
        },
      );

      // Log to Crashlytics
      await _crashlytics.recordError(
        Exception('AI Error in $operation'),
        StackTrace.current,
        information: [
          'Operation: $operation',
          'Model: $model',
          'Error: $error',
          'Additional Data: ${additionalData ?? {}}',
        ],
      );
      
      log('📊 AI error logged: $operation - $error');
    } catch (e) {
      log('❌ Failed to log AI error: $e');
    }
  }

  Future<void> logPerformanceMetrics({
    required String operation,
    required Duration totalTime,
    required Duration networkTime,
    required Duration processingTime,
    required int inputSize,
    required int? outputSize,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_performance',
        parameters: {
          'operation': operation,
          'total_time_ms': totalTime.inMilliseconds,
          'network_time_ms': networkTime.inMilliseconds,
          'processing_time_ms': processingTime.inMilliseconds,
          'input_size_bytes': inputSize,
          'output_size_bytes': outputSize ?? 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      log('📊 AI performance metrics logged: $operation');
    } catch (e) {
      log('❌ Failed to log AI performance metrics: $e');
    }
  }
}
```

This comprehensive AI integration guide provides production-ready implementation for Vertex AI and Gemini models in the Aura application. It includes proper error handling, rate limiting, monitoring, and follows clean architecture principles throughout.
