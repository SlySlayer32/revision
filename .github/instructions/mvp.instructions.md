---
applyTo: '**'
---

# 🚀 Pre-Production Implementation Plan: Full Working System

## ZERO TOLERANCE for:
- Mock implementations or placeholder functions
- Simulated endpoints or fake data sources
- Simplified "demo" versions that don't use real services
- Workarounds that bypass proper implementation
- Hardcoded credentials or insecure configurations

## MANDATORY REQUIREMENTS:
- Real Firebase services with proper initialization
- Actual Vertex AI Gemini models (no test endpoints)
- Production-grade security and error handling
- Complete end-to-end functionality
- Full VGV architecture implementation
- Comprehensive validation at each checkpoint

## 🚀 Step-by-Step MVP Implementation

### 0. Firebase Setup & Initialization (MANDATORY FIRST STEP - 30 minutes)
**Firebase MUST be configured before any other implementation:**

#### Firebase CLI & Project Setup:
```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter project
flutterfire configure
```

#### Required Dependencies:
```yaml
dependencies:
  firebase_core: ^3.7.1
  firebase_auth: ^5.3.3
  firebase_storage: ^12.3.7
  cloud_firestore: ^5.5.1
  firebase_analytics: ^11.3.7
  image_picker: ^1.1.2
  flutter_bloc: ^8.1.6
  http: ^1.2.2
```

#### Firebase Initialization (lib/main.dart):
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // MANDATORY: Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

#### Firebase Console Configuration:
1. Enable Authentication (Email/Password + Google Sign-in)
2. Setup Cloud Firestore with security rules
3. Configure Firebase Storage with appropriate rules
4. Enable Analytics for usage tracking

**Validation checkpoint:** App launches without Firebase errors, can authenticate users

### 1. Image Selection Feature (2-3 hours)

#### Step 1: Domain Layer Implementation
**Create complete domain entities with VGV architecture:**

`lib/features/image_processing/domain/entities/image_entity.dart`:
```dart
import 'dart:typed_data';

class ProcessedImage {
  final String id;
  final String originalPath;
  final Uint8List imageBytes;
  final String fileName;
  final int fileSizeBytes;
  final DateTime createdAt;
  final String? generatedPrompt;
  final String? aiGeneratedImagePath;
  
  const ProcessedImage({
    required this.id,
    required this.originalPath,
    required this.imageBytes,
    required this.fileName,
    required this.fileSizeBytes,
    required this.createdAt,
    this.generatedPrompt,
    this.aiGeneratedImagePath,
  });
}
```

`lib/features/image_processing/domain/repositories/image_repository.dart`:
```dart
import 'dart:typed_data';
import '../entities/image_entity.dart';

abstract class ImageRepository {
  Future<ProcessedImage> pickImageFromGallery();
  Future<ProcessedImage> pickImageFromCamera();
  Future<bool> saveImageToGallery(Uint8List imageBytes, String fileName);
  Future<String> uploadImageToFirebase(ProcessedImage image);
}
```

#### Step 2: Data Layer Implementation with Real Image Picker
`lib/features/image_processing/data/repositories/image_repository_impl.dart`:
```dart
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageRepositoryImpl implements ImageRepository {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  @override
  Future<ProcessedImage> pickImageFromGallery() async {
    // Request permissions
    final status = await Permission.photos.request();
    if (status.isDenied) {
      throw Exception('Gallery permission denied');
    }
    
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    
    if (pickedFile == null) {
      throw Exception('No image selected');
    }
    
    final imageBytes = await pickedFile.readAsBytes();
    
    // Validate file size (max 10MB)
    if (imageBytes.length > 10 * 1024 * 1024) {
      throw Exception('Image too large. Maximum size is 10MB');
    }
    
    return ProcessedImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalPath: pickedFile.path,
      imageBytes: imageBytes,
      fileName: pickedFile.name,
      fileSizeBytes: imageBytes.length,
      createdAt: DateTime.now(),
    );
  }
  
  @override
  Future<String> uploadImageToFirebase(ProcessedImage image) async {
    try {
      final storageRef = _storage
          .ref()
          .child('user_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putData(
        image.imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
```

**Validation checkpoint:** Can successfully pick images from camera/gallery, handle permissions

#### Step 3: Build the presentation layer
- Using the `flutter_bloc` package
- Implement the UI for image selection
- Add basic loading states and error messages
- **Validation checkpoint:** UI responds to user interactions

#### Step 4: Integrate the image selection feature into your app
- Ensure users can select images from their device
- Implement basic image size validation (max 10MB to prevent memory issues)
- **Validation checkpoint:** End-to-end image selection works

#### Step 5: Test the image selection feature
- Ensure basic functionality works as expected
- Test permission scenarios (granted/denied)
- **Validation checkpoint:** Feature works on device, handles basic errors

### 2. Minimal Image Display (Next 1 hour)
Once users can pick images, immediately show them on screen:
- Simple image display widget with loading indicator
- Basic image preview functionality with memory management
- Use the selected image from the previous step
- Add image compression for large files to prevent memory issues
- **Validation checkpoint:** Images display without crashes or memory warnings

### 3. Gemini AI Pipeline (Production Implementation with Vertex AI)

#### 3.1. Architecture & Layering (VGV Standard)
- **Data Layer:** Handles all API calls to Gemini and Firebase, isolates external dependencies.
- **Domain Layer:** Contains business logic for image analysis and generation, transforms data for the app.
- **Business Logic Layer:** Manages state using `flutter_bloc`, orchestrates the pipeline.
- **Presentation Layer:** UI, responds to state changes, never calls APIs directly.
- **Follow VGV's [layered architecture](https://verygood.ventures/blog/very-good-flutter-architecture) for maintainability and scalability.**

#### 3.2. Vertex AI Gemini Implementation (Production Models)

**IMPORTANT:** Based on current Google documentation, here are the correct models to use:

- **Image Analysis:** Use `gemini-2.5-flash` for analyzing images and generating descriptive prompts
- **Image Generation:** Use `gemini-2.0-flash-preview-image-generation` for generating new images

#### Required Dependencies:
```yaml
dependencies:
  # Add to existing dependencies
  google_generative_ai: ^0.4.6
```

#### Gemini API Service Implementation:
`lib/features/ai_processing/data/services/gemini_service.dart`:
```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final String _apiKey;
  late final GenerativeModel _analysisModel;
  late final GenerativeModel _generationModel;

  GeminiService({required String apiKey}) : _apiKey = apiKey {
    // Initialize models for different tasks
    _analysisModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );

    _generationModel = GenerativeModel(
      model: 'gemini-2.0-flash-preview-image-generation',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  /// Analyze image and generate descriptive prompt
  Future<String> analyzeImage(Uint8List imageBytes) async {
    try {
      final prompt = '''
Analyze this image and generate a detailed, creative prompt describing its content, style, and unique features. 
Focus on:
- Main subjects and their characteristics
- Visual style and artistic elements
- Colors, lighting, and composition
- Mood and atmosphere
- Any unique or interesting details

Provide a comprehensive description that could be used to recreate a similar image.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _analysisModel.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Failed to analyze image: Empty response');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Image analysis failed: $e');
    }
  }

  /// Generate new image from prompt and original image
  Future<Uint8List> generateImage({
    required String prompt,
    required Uint8List originalImageBytes,
  }) async {
    try {
      final enhancedPrompt = '''
Using the following prompt, recreate and enhance the provided image, preserving its core composition and style while adding creative improvements:

$prompt

Generate a high-quality image that maintains the essence of the original while enhancing its visual appeal.
''';

      final content = [
        Content.multi([
          TextPart(enhancedPrompt),
          DataPart('image/jpeg', originalImageBytes),
        ])
      ];

      final response = await _generationModel.generateContent(content);
      
      // Note: Image generation response handling may vary
      // This is a simplified implementation - actual response parsing depends on API
      if (response.candidates.isEmpty) {
        throw Exception('No image generated');
      }

      // Extract image data from response
      // This would need to be adapted based on actual API response format
      final candidate = response.candidates.first;
      if (candidate.content.parts.isEmpty) {
        throw Exception('No image data in response');
      }

      // Handle the actual image data extraction based on API response format
      // This is a placeholder - actual implementation depends on API structure
      throw UnimplementedError('Image extraction logic needs API-specific implementation');

    } catch (e) {
      throw Exception('Image generation failed: $e');
    }
  }
}
```

#### AI Processing Repository:
`lib/features/ai_processing/domain/repositories/ai_repository.dart`:
```dart
import 'dart:typed_data';

abstract class AIRepository {
  Future<String> analyzeImage(Uint8List imageBytes);
  Future<Uint8List> generateEnhancedImage({
    required String prompt,
    required Uint8List originalImageBytes,
  });
}
```

`lib/features/ai_processing/data/repositories/ai_repository_impl.dart`:
```dart
import 'dart:typed_data';
import '../services/gemini_service.dart';
import '../../domain/repositories/ai_repository.dart';

class AIRepositoryImpl implements AIRepository {
  final GeminiService _geminiService;

  AIRepositoryImpl({required GeminiService geminiService})
      : _geminiService = geminiService;

  @override
  Future<String> analyzeImage(Uint8List imageBytes) async {
    try {
      return await _geminiService.analyzeImage(imageBytes);
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  @override
  Future<Uint8List> generateEnhancedImage({
    required String prompt,
    required Uint8List originalImageBytes,
  }) async {
    try {
      return await _geminiService.generateImage(
        prompt: prompt,
        originalImageBytes: originalImageBytes,
      );
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }
}
```

#### Environment Configuration:
**CRITICAL:** Never hardcode API keys. Use environment variables or Firebase Remote Config.

`lib/core/config/env_config.dart`:
```dart
class EnvConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => geminiApiKey.isNotEmpty;
}
```

Add to your `--dart-define` when running:
```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

#### 3.3. Complete Pipeline Flow Implementation:
1. User selects image (max 10MB, validated in domain layer)
2. App sends image to Gemini 2.5 Flash for analysis, receives descriptive prompt
3. App sends prompt + original image to Gemini 2.0 Flash Preview Image Generation
4. App displays both original and generated images with the analysis prompt
5. User can save results to device and/or Firebase Storage
6. All errors are handled gracefully with retry logic and user-friendly messages

#### 3.4. Production Best Practices:
- **API Timeouts:** 30s for analysis, 60s for generation
- **Retry Logic:** Maximum 2 retries for transient failures
- **Rate Limiting:** Monitor usage to stay within API limits
- **Error Handling:** Comprehensive error messages for users
- **Security:** API keys stored securely, never in client code
- **Monitoring:** Track usage and costs in Google Cloud Console

**Validation checkpoint:** AI pipeline completes successfully with real Vertex AI endpoints

### 4. Save Results (Next 1 hour)
Basic save functionality:
- Save to device gallery with proper permissions
- Implement basic file naming (timestamp-based)
- Simple success/error feedback with specific messages
- Add basic duplicate handling
- **Validation checkpoint:** Images save successfully to gallery

## 🔥 Key MVP Focus Points
- Use your existing authentication - users can log in
- Build image selection first - users can pick photos
- Add Gemini AI pipeline (no mocks, real endpoints)
- Save results - users keep their edits
- Deploy and test - real users try it

## 📋 What NOT to implement yet:
- Complex image editing tools
- Multiple AI features
- Advanced galleries
- Sophisticated error handling (beyond basic scenarios)
- Performance optimizations (beyond memory management)
- Complex testing (keep it basic)

## 🛡️ Essential Safety Measures (Non-negotiable)
- Basic permission handling (camera, storage)
- Image size limits (prevent memory crashes)
- API timeout handling (prevent hanging)
- Secure credential storage
- Basic error messages (prevent user confusion)

## 🚨 Rollback Strategy
If any step takes longer than planned or hits blockers:
1. **Step 1-2 issues:** Use mock images, continue with AI pipeline
2. **Step 3 issues:** Implement simple image filters instead of AI
3. **Step 4 issues:** Show success message without actual saving
4. **Overall blocker:** Pivot to simpler image gallery with basic filters

## 🎯 Your 8-Hour MVP Goal:
User opens app → Logs in → Picks image → Applies Gemini AI pipeline → Saves result → Success!

## ✅ Final Validation Checklist:
- [ ] App launches without crashes
- [ ] User can select images
- [ ] Images display properly
- [ ] Gemini AI pipeline completes (or shows appropriate errors)
- [ ] Results can be saved
- [ ] Basic error scenarios don't crash the app
- [ ] App works on physical device (not just simulator)

## 🔄 Validation Points Summary:
After each major step, ensure the previous functionality still works. If something breaks, fix it immediately before proceeding. This prevents building on unstable foundations and makes debugging much easier during rapid development.
## 🚀 Final Steps
1. Conduct thorough testing on physical devices.
2. Gather user feedback for improvements.
3. Plan for future enhancements beyond MVP.