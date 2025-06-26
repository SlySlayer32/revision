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

### 3. Gemini AI Pipeline (No mocks, full logic, VGV, Firebase, Vertex AI best practices)

#### 3.1. Architecture & Layering (VGV Standard)
- **Data Layer:** Handles all API calls to Gemini and Firebase, isolates external dependencies.
- **Domain Layer:** Contains business logic for image analysis and generation, transforms data for the app.
- **Business Logic Layer:** Manages state using `flutter_bloc`, orchestrates the pipeline.
- **Presentation Layer:** UI, responds to state changes, never calls APIs directly.
- **Follow VGV's [layered architecture](https://verygood.ventures/blog/very-good-flutter-architecture) for maintainability and scalability.**

#### 3.2. Gemini Pipeline Implementation
- **Step 1: Image Analysis**
  - Use Gemini 2.5 Flash (`gemini-2.5-flash`) for analyzing the selected image.
  - Send the image as input, request a detailed prompt describing the image (see [Gemini API docs](https://ai.google.dev/gemini-api/docs/models#gemini-2.5-flash)).
  - Use the returned prompt as the input for the next step.
  - [Gemini 2.5 Flash](https://ai.google.dev/gemini-api/docs/models#gemini-2.5-flash) is optimized for price-performance and low latency, ideal for scalable, cost-effective analysis.

- **Step 2: Image Generation**
  - Use Gemini 2.0 Flash Preview Image Generation (`gemini-2.0-flash-preview-image-generation`) to generate a new image from the prompt and original image.
  - Send both the prompt and the original image as input (see [Gemini API docs](https://ai.google.dev/gemini-api/docs/models#gemini-2.0-flash-preview-image-generation)).
  - Receive the generated image and display it to the user.
  - [Gemini 2.0 Flash Preview Image Generation](https://ai.google.dev/gemini-api/docs/models#gemini-2.0-flash-preview-image-generation) is designed for conversational image generation and editing.

- **API Integration**
  - Use the [official Gemini API libraries](https://ai.google.dev/gemini-api/docs/libraries) for Dart/Flutter if available, or call the REST API directly.
  - Store API keys securely using environment variables or Firebase Remote Config (never hardcode keys).
  - Set timeouts (30s for analysis, 60s for generation) and handle errors gracefully.
  - Implement retry logic (max 2 retries) for transient failures.
  - Monitor [rate limits](https://ai.google.dev/gemini-api/docs/rate-limits) and [pricing](https://ai.google.dev/gemini-api/docs/pricing) to control costs.

- **Firebase Integration**
  - Use Firebase Auth for user management and security.
  - Use Firebase Storage to optionally store original and generated images for audit, sharing, or rollback.
  - Use Firestore for logging user actions and AI pipeline results if needed for analytics or debugging.
  - Follow [Firebase best practices](https://firebase.google.com/docs/guides) for scalability and security.

- **Vertex AI Integration**
  - Use Vertex AI endpoints for Gemini models (see [Vertex AI docs](https://cloud.google.com/vertex-ai/docs)).
  - Ensure your Google Cloud project is set up with correct permissions and billing.
  - Use [Vertex AI Pipelines](https://cloud.google.com/vertex-ai/docs/pipelines/introduction) for orchestrating more complex workflows if needed.
  - Monitor usage and optimize for cost and performance.

- **Prompt Engineering**
  - For analysis: "Analyze this image and generate a detailed, creative prompt describing its content, style, and unique features."
  - For generation: "Using the following prompt, recreate and enhance the provided image, preserving its core composition and style."
  - See [prompting strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies) for best results.

- **Performance & Cost**
  - Use Gemini 2.5 Flash for analysis (low cost, high throughput).
  - Use Gemini 2.0 Flash Preview Image Generation for image creation (higher cost, use only when needed).
  - Batch requests where possible, avoid unnecessary calls.
  - Monitor [Vertex AI pricing](https://cloud.google.com/vertex-ai/pricing) and [Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing).

- **Scalability**
  - Use stateless, layered architecture (VGV standard) for easy scaling.
  - Store only necessary data in Firebase/Firestore to minimize costs.
  - Use async/await and isolate heavy processing from UI.
  - Use [Firebase Functions](https://firebase.google.com/docs/functions) for server-side orchestration if needed.

- **Security**
  - Never expose API keys in the client app.
  - Use Firebase Auth and Firestore security rules.
  - Follow [Google Cloud security best practices](https://cloud.google.com/vertex-ai/docs/security-best-practices).

- **Testing**
  - MVP must use real Gemini and Firebase endpoints (no mocks, no simulations).
  - Test on real devices for performance and error handling.

#### 3.3. Example Pipeline Flow
1. User selects image (max 10MB, validated in domain layer).
2. App sends image to Gemini 2.5 Flash for analysis, receives prompt.
3. App sends prompt + image to Gemini 2.0 Flash Preview Image Generation, receives new image.
4. App displays both images and prompt to user.
5. User can save result to device and/or Firebase Storage.
6. All errors are handled gracefully, with retry and user-friendly messages.

#### 3.4. References & Further Reading
- [Gemini API Docs](https://ai.google.dev/gemini-api/docs)
- [Gemini Model Variants](https://ai.google.dev/gemini-api/docs/models)
- [Prompting Strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Vertex AI Docs](https://cloud.google.com/vertex-ai/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [VGV Architecture Guide](https://verygood.ventures/blog/very-good-flutter-architecture)
- [Example: I/O Photo Booth](https://github.com/flutter/photobooth)

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