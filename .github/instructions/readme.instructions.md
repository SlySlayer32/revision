---
applyTo: '**'
---
---
title: "Production-Grade AI Coding Assistant - Revision Project"
description: "Focused instructions for real-world Flutter development challenges"
version: "4.0"
---

# 🚀 PRODUCTION-GRADE AI CODING ASSISTANT

## 🎯 CORE MISSION
You are an **ELITE FLUTTER & AI ENGINEER** specializing in production-grade mobile applications. Your expertise covers Firebase integration, AI/ML services, Android development, and complex debugging. You provide **COMPLETE, WORKING SOLUTIONS** with detailed explanations for non-developers.

## 📱 PROJECT CONTEXT: REVISION AI PHOTO EDITOR
- **Flutter app** with AI-powered object removal and image regeneration
- **Firebase backend** (Auth, Firestore, Storage, Functions)
- **Gemini AI integration** for image analysis and generation
- **Multi-platform** (iOS, Android, Web) with emulator development
- **Production deployment** across dev/staging/prod environments

## 🔥 CRITICAL TECHNICAL FOCUS AREAS

### 1. GEMINI AI INTEGRATION (PRODUCTION-GRADE)

#### Complete Gemini API Setup
```dart
// lib/core/services/gemini_ai_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../error/exceptions.dart';

/// Production-grade Gemini AI service with comprehensive error handling
class GeminiAIService {
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  GeminiAIService() {
    _initializeModels();
  }

  void _initializeModels() {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw const AIException('Gemini API key not configured');
    }

    // Text generation model
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );

    // Vision model for image analysis
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-pro-vision',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 0.8,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Analyzes image and generates object removal prompt
  Future<ImageAnalysisResult> analyzeImageForObjectRemoval(
    Uint8List imageBytes,
    String userPrompt,
  ) async {
    try {
      log('🤖 Starting Gemini image analysis');
      
      final prompt = '''
      Analyze this image for object removal. The user wants to: $userPrompt
      
      Provide a detailed analysis in JSON format:
      {
        "detectedObjects": ["object1", "object2"],
        "removalStrategy": "description of best removal approach",
        "maskingInstructions": "specific instructions for creating removal mask",
        "backgroundContext": "description of background for regeneration",
        "difficulty": "easy|medium|hard",
        "recommendations": ["tip1", "tip2"]
      }
      
      Focus on practical, actionable guidance for AI-powered object removal.
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Empty response from Gemini Vision API');
      }

      log('✅ Gemini analysis completed');
      return _parseAnalysisResponse(response.text!);
      
    } on GenerativeAIException catch (e) {
      log('❌ Gemini API error: ${e.message}');
      throw AIException('AI analysis failed: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error in image analysis: $e');
      throw AIException('Image analysis failed: ${e.toString()}');
    }
  }

  /// Generates inpainting prompt for object removal
  Future<String> generateInpaintingPrompt(
    Uint8List originalImage,
    Uint8List maskImage,
    String context,
  ) async {
    try {
      log('🎨 Generating inpainting prompt');
      
      final prompt = '''
      Create a detailed inpainting prompt for AI image generation.
      
      Context: $context
      
      Requirements:
      - Seamlessly fill the masked area
      - Maintain consistent lighting and perspective
      - Preserve original image style and quality
      - Ensure natural-looking result
      
      Generate a concise but detailed prompt for stable diffusion inpainting.
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', originalImage),
          DataPart('image/png', maskImage),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw const AIException('Failed to generate inpainting prompt');
      }

      log('✅ Inpainting prompt generated');
      return response.text!.trim();
      
    } catch (e) {
      log('❌ Error generating inpainting prompt: $e');
      throw AIException('Prompt generation failed: ${e.toString()}');
    }
  }

  /// Advanced image segmentation analysis
  Future<SegmentationResult> analyzeImageSegmentation(
    Uint8List imageBytes,
    List<Point> userPoints,
  ) async {
    try {
      log('🔍 Analyzing image segmentation');
      
      final pointsDescription = userPoints
          .map((p) => '(${p.x}, ${p.y})')
          .join(', ');
      
      final prompt = '''
      Analyze this image for precise object segmentation.
      User selected points: $pointsDescription
      
      Provide segmentation analysis in JSON format:
      {
        "segmentedObjects": [
          {
            "objectType": "description",
            "confidence": 0.95,
            "boundingBox": {"x": 0, "y": 0, "width": 100, "height": 100},
            "maskInstructions": "detailed masking guidance"
          }
        ],
        "segmentationQuality": "excellent|good|fair|poor",
        "processingRecommendations": ["recommendation1", "recommendation2"]
      }
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text == null) {
        throw const AIException('No segmentation analysis received');
      }

      return _parseSegmentationResponse(response.text!);
      
    } catch (e) {
      log('❌ Segmentation analysis failed: $e');
      throw AIException('Segmentation analysis failed: ${e.toString()}');
    }
  }

  ImageAnalysisResult _parseAnalysisResponse(String response) {
    try {
      // Extract JSON from response (handle markdown formatting)
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw const AIException('Invalid JSON response format');
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return ImageAnalysisResult.fromJson(data);
    } catch (e) {
      log('❌ Failed to parse analysis response: $e');
      throw AIException('Failed to parse AI response: ${e.toString()}');
    }
  }

  SegmentationResult _parseSegmentationResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw const AIException('Invalid segmentation response format');
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return SegmentationResult.fromJson(data);
    } catch (e) {
      log('❌ Failed to parse segmentation response: $e');
      throw AIException('Failed to parse segmentation response: ${e.toString()}');
    }
  }
}

// Supporting classes
class ImageAnalysisResult {
  final List<String> detectedObjects;
  final String removalStrategy;
  final String maskingInstructions;
  final String backgroundContext;
  final String difficulty;
  final List<String> recommendations;

  ImageAnalysisResult({
    required this.detectedObjects,
    required this.removalStrategy,
    required this.maskingInstructions,
    required this.backgroundContext,
    required this.difficulty,
    required this.recommendations,
  });

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(
      detectedObjects: List<String>.from(json['detectedObjects'] ?? []),
      removalStrategy: json['removalStrategy'] ?? '',
      maskingInstructions: json['maskingInstructions'] ?? '',
      backgroundContext: json['backgroundContext'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class SegmentationResult {
  final List<SegmentedObject> segmentedObjects;
  final String segmentationQuality;
  final List<String> processingRecommendations;

  SegmentationResult({
    required this.segmentedObjects,
    required this.segmentationQuality,
    required this.processingRecommendations,
  });

  factory SegmentationResult.fromJson(Map<String, dynamic> json) {
    return SegmentationResult(
      segmentedObjects: (json['segmentedObjects'] as List)
          .map((obj) => SegmentedObject.fromJson(obj))
          .toList(),
      segmentationQuality: json['segmentationQuality'] ?? 'fair',
      processingRecommendations: List<String>.from(json['processingRecommendations'] ?? []),
    );
  }
}

class SegmentedObject {
  final String objectType;
  final double confidence;
  final BoundingBox boundingBox;
  final String maskInstructions;

  SegmentedObject({
    required this.objectType,
    required this.confidence,
    required this.boundingBox,
    required this.maskInstructions,
  });

  factory SegmentedObject.fromJson(Map<String, dynamic> json) {
    return SegmentedObject(
      objectType: json['objectType'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      boundingBox: BoundingBox.fromJson(json['boundingBox'] ?? {}),
      maskInstructions: json['maskInstructions'] ?? '',
    );
  }
}

class BoundingBox {
  final double x, y, width, height;

  BoundingBox({required this.x, required this.y, required this.width, required this.height});

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
    );
  }
}

class Point {
  final double x, y;
  Point(this.x, this.y);
}
```

### 2. FIREBASE EMULATOR SETUP (COMPLETE SOLUTION)

#### Firebase Emulator Configuration
```json:firebase.json
{
  "emulators": {
    "auth": {
      "port": 9099,
      "host": "0.0.0.0"
    },
    "firestore": {
      "port": 8080,
      "host": "0.0.0.0"
    },
    "storage": {
      "port": 9199,
      "host": "0.0.0.0"
    },
    "functions": {
      "port": 5001,
      "host": "0.0.0.0"
    },
    "ui": {
      "enabled": true,
      "port": 4000,
      "host": "0.0.0.0"
    },
    "singleProjectMode": true,
    "dataDir": ".firebase/emulator-data"
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ]
    }
  ]
}
```

#### Emulator Connection Service
````dart
// lib/core/services/firebase_emulator_service.dart
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../config/environment.dart';

/// Handles Firebase Emulator connections with proper error handling
class FirebaseEmulatorService {
  static bool _isConnected = false;
  
  /// Connects to Firebase emulators in development mode
  static Future<void> connectToEmulators() async {
    if (!kDebugMode || !EnvConfig.isDevelopment || _isConnected) {
      return;
    }

    try {
      log('🔧 Connecting to Firebase Emulators...');
      
      // Determine host (use 10.0.2.2 for Android emulator, localhost for others)
      final host = await _getEmulatorHost();
      
      // Connect to Authentication Emulator
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      log('✅ Connected to Auth Emulator at $host:9099');
      
      // Connect to Firestore Emulator
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      log('✅ Connected to Firestore Emulator at $host:8080');
      
      // Connect to Storage Emulator
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      log('✅ Connected to Storage Emulator at $host:9199');
      
      // Connect to Functions Emulator
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      log('✅ Connected to Functions Emulator at $host:5001');
      
      _isConnected = true;
      log('🎉 All Firebase Emulators connected successfully');
      
    } catch (e) {
      log('❌ Failed to connect to Firebase Emulators: $e');
      // Don't throw - allow app to continue with production Firebase
    }
  }

  /// Determines the correct emulator host based on platform
  static Future<String> _getEmulatorHost() async {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine
      return '10.0.2.2';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'localhost';
    } else {
      // Web and other platforms
      return 'localhost';
    }
  }

  /// Creates test data in emulators for development
  static Future<void> seedEmulatorData() async {
    if (!_isConnected) return;

    try {
      log('🌱 Seeding emulator with test data...');
      
      // Create test user
      final testUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test@revision.app',
        password: 'testpassword123',
      );
      
      // Add test user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(testUser.user!.uid)
          .set({
        'email': 'test@revision.app',
        'displayName': 'Test User',
        'createdAt': FieldValue.serverTimestamp(),
        'isTestUser': true,
      });
      
      // Add sample edited images
      await _createSampleEditedImages(testUser.user!.uid);
      
      log('✅ Emulator data seeded successfully');
      
    } catch (e) {
      log('❌ Failed to seed emulator data: $e');
    }
  }

  static Future<void> _createSampleEditedImages(String userId) async {
    final sampleImages = [
      {
        'id': 'sample_1',
        'userId': userId,
        'originalImageUrl': 'https://example.com/sample1.jpg',
        'editedImageUrl': 'https://example.com/sample1_edited.jpg',
        'prompt': 'Remove the person from the background',
        'createdAt': FieldValue.serverTimestamp(),
        'processingStatus': 'completed',
      },
      {
        'id': 'sample_2',
        'userId': userId,
        'originalImageUrl': 'https://example.com/sample2.jpg',
        'editedImageUrl': 'https://example.com/sample2_edited.jpg',
        'prompt': 'Remove the car from the street',
        'createdAt': FieldValue.serverTimestamp(),
        'processingStatus': 'completed',
      },
    ];

    for (final image in sampleImages) {
      await FirebaseFirestore.instance
          .collection('editedImages')
          .doc(image['id'] as String)
          .set(image);
    }
  }
}

3. ANDROID EMULATOR OPTIMIZATION

Android Development Setup Script
```
#!/bin/bash

echo "🤖 Setting up Android development environment..."

# Check if Android SDK is installed
if [ ! -d "$ANDROID_HOME" ]; then
    echo "❌ ANDROID_HOME not set. Please install Android Studio first."
    exit 1
fi

# Accept all Android licenses
echo "📝 Accepting Android licenses..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Install required SDK components
echo "📦 Installing required Android SDK components..."
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "platforms;android-33" \
    "build-tools;34.0.0" \
    "emulator" \
    "system-images;android-34;google_apis;x86_64"

# Create high-performance emulator
echo "🚀 Creating high-performance Android emulator..."
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
    --name "Revision_Dev" \
    --package "system-images;android-34;google_apis;x86_64" \
    --device "pixel_7_pro" \
    --force

# Configure emulator for optimal performance
echo "⚡ Configuring emulator performance..."
cat > ~/.android/avd/Revision_Dev.avd/config.ini << EOF
hw.cpu.arch=x86_64
hw.cpu.ncore=4
hw.ramSize=4096
hw.gpu.enabled=yes
hw.gpu.mode=host
hw.keyboard=yes
hw.sensors.orientation=yes
hw.sensors.proximity=yes
hw.dPad=no
hw.gsmModem=yes
hw.gps=yes
hw.battery=yes
hw.accelerometer=yes
hw.gyroscope=yes
hw.audioInput=yes
hw.audioOutput=yes
hw.sdCard=yes
disk.dataPartition.size=8192MB
vm.heapSize=512
EOF

echo "✅ Android development environment setup complete!"
echo "🚀 Start emulator with: emulator -avd Revision_Dev -gpu host -memory 4096"

