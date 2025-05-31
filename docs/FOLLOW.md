<think>The user wants a build tutorial that provides step-by-step instructions for implementing their Flutter AI photo editor app from start to finish. This should be structured as prompts they can submit to Copilot, since Copilot will be the main code writer.

Based on their requirements:
- iOS & Android Flutter app
- VGV Boilerplate
- Image picker → Image editor → Vertex AI pipeline
- PROMPTER (Gemini 2.5) → EDITOR (Google Imagen)
- Test-first development
- 3-layer architecture

I need to create a comprehensive tutorial with specific prompts they can give to Copilot in the right order, covering:

1. Project setup with VGV
2. Firebase/Vertex AI setup
3. Authentication
4. Image picker functionality
5. Image editor with marking
6. AI integration (PROMPTER + EDITOR)
7. Results display
8. Testing throughout

Each step should be a clear prompt they can copy-paste to Copilot with specific requirements.</think>
# Flutter AI Photo Editor - Build Tutorial

## Complete Step-by-Step Implementation Guide

This tutorial provides exact prompts to submit to Copilot for building your Flutter AI photo editor app from start to finish.

---

## Phase 1: Project Foundation & Setup

### Step 1: Initialize VGV Project

**Prompt for Copilot:**
```
Create a new Flutter project using Very Good Ventures (VGV) boilerplate with the following requirements:

1. Project name: "ai_photo_editor"
2. Include VGV bootstrap.dart pattern
3. Set up environment files (main_development.dart, main_production.dart)
4. Configure get_it dependency injection
5. Add Firebase integration for Vertex AI
6. Include these essential dependencies in pubspec.yaml:
   - flutter_bloc
   - equatable
   - get_it
   - firebase_core
   - firebase_auth
   - firebase_vertexai
   - image_picker
   - path_provider
   - share_plus

Follow VGV 100% compliant project structure with features/ directory for clean architecture.
```

### Step 2: Firebase & Vertex AI Configuration

**Prompt for Copilot:**
```
Set up Firebase and Vertex AI integration for the Flutter app:

1. Create Firebase configuration files (google-services.json, GoogleService-Info.plist)
2. Initialize Firebase in bootstrap.dart following VGV pattern
3. Configure Vertex AI with Gemini 2.5 Pro and Imagen models
4. Set up authentication for Vertex AI services
5. Create environment-specific configurations for development/production
6. Ensure proper security rules and API key management

Include proper error handling and initialization checks following VGV standards.
```

---

## Phase 2: Authentication Feature (Test-First)

### Step 3: Authentication Domain Layer

**Prompt for Copilot:**
```
Create the authentication feature using test-first development and VGV clean architecture:

DOMAIN LAYER (write tests first):
1. Create User entity with Equatable
2. Create AuthRepository interface
3. Create SignInUseCase and SignUpUseCase with proper error handling
4. Create custom AuthException classes
5. Use Result pattern (Success/Failure) for error handling

Write comprehensive unit tests for all domain logic before implementation.
Follow VGV patterns exactly - use sealed classes, proper file structure, and naming conventions.
```

### Step 4: Authentication Data Layer

**Prompt for Copilot:**
```
Implement authentication data layer with test-first approach:

DATA LAYER (write tests first):
1. Create FirebaseAuthDataSource with email/password and Google sign-in
2. Create AuthRepositoryImpl implementing domain interface
3. Create User model that maps to/from Firebase User
4. Handle all Firebase exceptions and convert to domain exceptions
5. Add proper logging and error reporting

Write unit tests with mocked Firebase dependencies before implementation.
Use mocktail for mocking, follow VGV repository implementation patterns.
```

### Step 5: Authentication Presentation Layer

**Prompt for Copilot:**
```
Create authentication UI with BLoC pattern and test-first development:

PRESENTATION LAYER (write tests first):
1. Create AuthBloc with events (SignInRequested, SignUpRequested, SignOutRequested)
2. Create AuthState with sealed classes (Initial, Loading, Authenticated, Unauthenticated, Error)
3. Create LoginPage with VGV Page/View pattern
4. Create LoginView with email/password form validation
5. Create SignUpPage and SignUpView
6. Add proper loading states and error handling in UI

Write widget tests and BLoC tests first. Use VGV UI patterns with proper separation of Page/View/Widgets.
```

---

## Phase 3: Image Selection Feature (Test-First)

### Step 6: Image Picker Domain Layer

**Prompt for Copilot:**
```
Create image picker feature with test-first development:

DOMAIN LAYER (write tests first):
1. Create ImageSource enum (gallery, camera)
2. Create PickImageUseCase with ImageSource parameter
3. Create ImageRepository interface with pickFromGallery() and pickFromCamera()
4. Create ImagePickerException for error handling
5. Use Result pattern for success/failure handling

Write comprehensive unit tests for image picking logic.
Follow VGV domain layer patterns with proper entities and use cases.
```

### Step 7: Image Picker Data & Presentation

**Prompt for Copilot:**
```
Implement image picker data layer and UI with test-first approach:

DATA LAYER (write tests first):
1. Create ImagePickerDataSource using image_picker package
2. Create ImageRepositoryImpl with proper error handling
3. Handle permissions and platform-specific logic
4. Add image validation (format, size checks)

PRESENTATION LAYER (write tests first):
1. Create ImagePickerBloc with events and states
2. Create ImageSelectionPage with VGV Page/View pattern
3. Create UI with Gallery and Camera selection buttons
4. Add proper loading states and permission handling
5. Navigate to image editor after successful selection

Write all tests first, then implement. Use VGV patterns throughout.
```

---

## Phase 4: Image Editor with Marking Interface (Test-First)

### Step 8: Image Editor Domain Layer

**Prompt for Copilot:**
```
Create image editor feature with object marking capability:

DOMAIN LAYER (write tests first):
1. Create ImageMarker entity with position (Offset) and unique ID
2. Create ProcessedImage entity with originalPath, editedPath, markers list
3. Create AddMarkerUseCase and RemoveMarkerUseCase
4. Create ImageEditorRepository interface
5. Use proper error handling with custom exceptions

Write comprehensive unit tests for all marker management logic.
Follow VGV domain patterns with immutable entities and Equatable.
```

### Step 9: Image Editor UI Implementation

**Prompt for Copilot:**
```
Create interactive image editor UI with test-first development:

PRESENTATION LAYER (write tests first):
1. Create ImageEditorBloc with events (ImageSelected, MarkerAdded, MarkerRemoved, AIProcessingRequested)
2. Create ImageEditorState with sealed classes (Initial, ImageSelected, Processing, ProcessingComplete, Error)
3. Create ImageMarkerPainter using CustomPainter for drawing markers
4. Create InteractiveImageEditor widget with:
   - InteractiveViewer for zoom/pan functionality
   - GestureDetector for tap-to-mark
   - Visual markers (circles with crosshairs)
   - Marker removal capability
5. Create ImageEditorPage and ImageEditorView following VGV patterns

Write widget tests and golden tests for UI components first.
Ensure markers are clearly visible and interactive.
```

---

## Phase 5: Vertex AI Integration - PROMPTER + EDITOR (Test-First)

### Step 10: AI Processing Domain Layer

**Prompt for Copilot:**
```
Create AI processing feature with PROMPTER and EDITOR pipeline:

DOMAIN LAYER (write tests first):
1. Create AIPrompt entity and AIProcessedImage entity
2. Create GeneratePromptUseCase (for Gemini 2.5 Pro analysis)
3. Create ProcessImageWithAIUseCase (for Google Imagen editing)
4. Create AIRepository interface with generatePrompt() and editImage() methods
5. Create AIProcessingException with specific error types
6. Use Result pattern for all AI operations

Write unit tests that mock AI responses and test the complete pipeline.
Follow VGV domain patterns with proper separation of concerns.
```

### Step 11: Vertex AI Data Source Implementation

**Prompt for Copilot:**
```
Implement Vertex AI integration with test-first approach:

DATA LAYER (write tests first):
1. Create VertexAIDataSource with Firebase Vertex AI integration
2. Implement generateEditingPrompt() using Gemini 2.5 Pro with these instructions:
   - Analyze image and marked object locations
   - Generate detailed editing prompt for seamless object removal
   - Consider lighting, shadows, background patterns
   - Output precise instructions for the EDITOR AI
3. Implement editImage() using Google Imagen model
4. Handle base64 image encoding/decoding
5. Create AIRepositoryImpl with proper error handling and timeouts
6. Add retry logic for transient failures

Write tests with mocked Vertex AI responses first.
Include proper prompt engineering and response parsing.
```

### Step 12: AI Processing UI Integration

**Prompt for Copilot:**
```
Integrate AI processing into the image editor UI:

PRESENTATION LAYER (write tests first):
1. Extend ImageEditorBloc to handle AI processing workflow:
   - AIProcessingRequested event triggers PROMPTER → EDITOR pipeline
   - Show detailed progress states (Analyzing, Generating Prompt, Editing Image)
   - Handle AI processing errors gracefully
2. Update ImageEditorView to show:
   - Process button when markers are present
   - Progress indicators during AI processing
   - Error messages for AI failures
3. Create navigation to results page after successful processing
4. Add cancellation capability for long-running AI operations

Write BLoC tests and widget tests first.
Ensure proper user feedback during AI processing (can take 30+ seconds).
```

---

## Phase 6: Results Display & Actions (Test-First)

### Step 13: Results Feature Implementation

**Prompt for Copilot:**
```
Create results display feature with save/share functionality:

COMPLETE FEATURE (write tests first):
1. Create ResultPage and ResultView following VGV Page/View pattern
2. Create before/after image comparison UI:
   - Side-by-side or swipeable comparison
   - Clear labeling (Before/After)
   - Zoom functionality for detailed comparison
3. Create ResultBloc with save and share functionality
4. Implement save to device gallery using appropriate plugins
5. Implement share functionality with social media integration
6. Add "Edit Again" option to return to image editor
7. Create proper success/error handling for save/share operations

Write comprehensive tests for all result handling operations.
Include integration tests for the complete image→AI→result workflow.
```

---

## Phase 7: Integration & Polish (Test-First)

### Step 14: App-Level Integration

**Prompt for Copilot:**
```
Integrate all features into the main app with proper navigation:

APP INTEGRATION (write tests first):
1. Create main App widget following VGV pattern
2. Set up app-level BLoC providers for authentication state
3. Create proper routing between:
   - Authentication → Image Selection → Image Editor → Results
4. Implement authentication guards (redirect to login if not authenticated)
5. Add app-level error handling and crash reporting
6. Create proper app theming and branding
7. Add loading states during app initialization

Write integration tests for complete user workflows.
Ensure proper state management across the entire app.
```

### Step 15: Performance Optimization & Error Handling

**Prompt for Copilot:**
```
Optimize the app for production with comprehensive error handling:

OPTIMIZATION & ERROR HANDLING:
1. Optimize image handling:
   - Compress images before AI processing
   - Implement proper memory management
   - Add image caching where appropriate
2. Add comprehensive error handling:
   - Network connectivity issues
   - AI service outages
   - Permission denials
   - Storage full scenarios
3. Implement proper loading states and progress indicators
4. Add user-friendly error messages with recovery suggestions
5. Optimize AI processing:
   - Queue management for multiple requests
   - Timeout handling
   - Retry logic with exponential backoff
6. Add analytics and crash reporting
7. Implement proper logging for debugging

Include performance tests and error scenario tests.
```

---

## Phase 8: Testing & Deployment

### Step 16: Comprehensive Testing Suite

**Prompt for Copilot:**
```
Create comprehensive testing suite following VGV testing standards:

TESTING IMPLEMENTATION:
1. Ensure 100% test coverage for domain layer
2. Ensure 95%+ test coverage for data layer
3. Ensure 90%+ test coverage for presentation layer
4. Create integration tests for complete user workflows:
   - Login → Pick Image → Mark Objects → AI Process → Save Result
5. Create golden tests for critical UI components
6. Add performance tests for image processing and AI operations
7. Create tests for error scenarios and edge cases
8. Set up CI/CD pipeline with automated testing
9. Add test helpers and utilities following VGV patterns

Write tests that ensure app stability and reliability in production.
```

### Step 17: Production Deployment Setup

**Prompt for Copilot:**
```
Prepare the app for production deployment:

DEPLOYMENT PREPARATION:
1. Configure production Firebase project with Vertex AI
2. Set up proper API key management and security
3. Configure app signing for iOS and Android
4. Set up app store metadata and screenshots
5. Create production build configurations
6. Implement proper logging and monitoring
7. Set up crash reporting and analytics
8. Create user documentation and help content
9. Configure app permissions and privacy policies
10. Test on physical devices with production Firebase

Ensure the app meets all platform requirements for iOS App Store and Google Play Store.
```

---

## Implementation Order Summary

1. **Foundation**: VGV project setup + Firebase configuration
2. **Authentication**: Complete auth feature (domain → data → presentation)
3. **Image Selection**: Image picker functionality
4. **Image Editor**: Interactive marking interface
5. **AI Integration**: PROMPTER + EDITOR pipeline
6. **Results**: Display and sharing functionality
7. **Integration**: Connect all features with navigation
8. **Testing**: Comprehensive test suite
9. **Deployment**: Production preparation

## Key Reminders for Each Prompt

- **Always write tests FIRST** before implementation
- **Follow VGV patterns exactly** - no deviations
- **Use 3-layer architecture** consistently
- **Implement proper error handling** at every layer
- **Add comprehensive logging** for debugging
- **Test on real devices** with actual Firebase/Vertex AI

Submit each prompt to Copilot in order, ensuring each phase is complete before moving to the next. This approach ensures a high-quality, maintainable Flutter app that follows VGV standards throughout.