# Phase 1: Firebase & Vertex AI Configuration

## Context & Requirements
Configure Firebase and Vertex AI for production-ready Flutter app with enterprise-grade security, comprehensive error handling, and scalable architecture. This setup must support Gemini 2.5 Pro (PROMPTER) and Google Imagen (EDITOR) pipeline with high-volume processing.

**Critical Technical Requirements:**
- Firebase SDK: Latest stable (12.0+)
- Vertex AI: Firebase Vertex AI plugin (0.2.2+)
- Security: Environment-based configuration with secrets management
- Error handling: Circuit breaker pattern for AI services
- Scalability: Request queuing and rate limiting
- Monitoring: Comprehensive logging and analytics

## Exact Implementation Specifications

### 1. Firebase Project Setup (Security-First)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Create production-grade project structure
firebase login
firebase projects:create ai-photo-editor-prod --display-name "AI Photo Editor (Production)"
firebase projects:create ai-photo-editor-dev --display-name "AI Photo Editor (Development)"

# Enable required services
firebase use ai-photo-editor-prod
firebase services:enable vertexai.googleapis.com
firebase services:enable firestore.googleapis.com
firebase services:enable storage.googleapis.com
firebase services:enable cloudlogging.googleapis.com
```

### 2. Environment-Specific Configuration
```dart
// lib/core/constants/app_constants.dart
class FirebaseConfig {
  static Map<String, dynamic> get config {
    switch (AppConstants.environment) {
      case Environment.development:
        return _developmentConfig;
      case Environment.staging:
        return _stagingConfig;
      case Environment.production:
        return _productionConfig;
    }
  }

  static const Map<String, dynamic> _productionConfig = {
    'apiKey': String.fromEnvironment('FIREBASE_API_KEY_PROD'),
    'appId': String.fromEnvironment('FIREBASE_APP_ID_PROD'),
    'messagingSenderId': String.fromEnvironment('FIREBASE_SENDER_ID_PROD'),
    'projectId': 'ai-photo-editor-prod',
    'storageBucket': 'ai-photo-editor-prod.appspot.com',
    'vertexLocation': 'us-central1',
    'maxConcurrentRequests': 3,
    'timeoutSeconds': 120,
  };

  static const Map<String, dynamic> _developmentConfig = {
    'apiKey': String.fromEnvironment('FIREBASE_API_KEY_DEV'),
    'appId': String.fromEnvironment('FIREBASE_APP_ID_DEV'),
    'messagingSenderId': String.fromEnvironment('FIREBASE_SENDER_ID_DEV'),
    'projectId': 'ai-photo-editor-dev',
    'storageBucket': 'ai-photo-editor-dev.appspot.com',
    'vertexLocation': 'us-central1',
    'maxConcurrentRequests': 1,
    'timeoutSeconds': 60,
  };
}
```

### 3. Robust Firebase Initialization
```dart
// lib/core/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static FirebaseApp? _app;
  static GenerativeModel? _geminiModel;
  static GenerativeModel? _imagenModel;
  
  static Future<void> initialize() async {
    try {
      _app = await Firebase.initializeApp(
        name: 'ai-photo-editor',
        options: FirebaseOptions.fromMap(FirebaseConfig.config),
      );
      
      await _initializeVertexAI();
      await _setupCrashReporting();
      await _configureAnalytics();
      
      log('Firebase initialized successfully');
    } catch (e, stackTrace) {
      await CrashReportingService.recordError(
        'Firebase initialization failed',
        e,
        stackTrace,
        fatal: true,
      );
      rethrow;
    }
  }

  static Future<void> _initializeVertexAI() async {
    final vertexAI = FirebaseVertexAI.instanceFor(
      app: _app!,
      location: FirebaseConfig.config['vertexLocation'],
    );

    // Initialize Gemini 2.5 Pro for prompt generation
    _geminiModel = vertexAI.generativeModel(
      model: 'gemini-2.5-pro',
      generationConfig: GenerationConfig(
        temperature: 0.1, // Low for consistent prompts
        topK: 1,
        topP: 0.1,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.blockLowAndAbove,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.blockLowAndAbove,
        ),
      ],
    );

    // Initialize Imagen for image editing
    _imagenModel = vertexAI.generativeModel(
      model: 'imagen-3.0-fast-generate',
      generationConfig: GenerationConfig(
        temperature: 0.2,
        topK: 32,
        topP: 0.8,
      ),
    );
  }
}
```

### 4. Circuit Breaker Pattern for AI Services
```dart
// lib/core/services/circuit_breaker_service.dart
enum CircuitBreakerState { closed, open, halfOpen }

class CircuitBreakerService {
  static final Map<String, CircuitBreaker> _breakers = {};
  
  static CircuitBreaker get vertexAI => _breakers.putIfAbsent(
    'vertex_ai',
    () => CircuitBreaker(
      failureThreshold: 5,
      recoveryTimeout: const Duration(minutes: 2),
      onStateChange: (state) => _logStateChange('vertex_ai', state),
    ),
  );

  static Future<T> executeWithBreaker<T>(
    String service,
    Future<T> Function() operation,
  ) async {
    final breaker = _breakers[service];
    if (breaker == null) {
      throw Exception('Circuit breaker not found for service: $service');
    }

    return breaker.execute(operation);
  }
}

class CircuitBreaker {
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  
  final int failureThreshold;
  final Duration recoveryTimeout;
  final void Function(CircuitBreakerState)? onStateChange;

  CircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
    this.onStateChange,
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
        onStateChange?.call(_state);
      } else {
        throw CircuitBreakerOpenException();
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    onStateChange?.call(_state);
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      onStateChange?.call(_state);
    }
  }

  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
           DateTime.now().difference(_lastFailureTime!) > recoveryTimeout;
  }
}
```

### 5. Request Queue Management
```dart
// lib/core/services/ai_request_queue_service.dart
class AIRequestQueueService {
  static final Queue<AIRequest> _requestQueue = Queue<AIRequest>();
  static final Set<String> _processingRequests = <String>{};
  static Timer? _processTimer;
  
  static int get maxConcurrentRequests => 
      FirebaseConfig.config['maxConcurrentRequests'] as int;
  
  static Future<void> initialize() async {
    _processTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _processQueue(),
    );
  }

  static Future<String> queueRequest(AIRequest request) async {
    request.id = const Uuid().v4();
    request.queuedAt = DateTime.now();
    
    _requestQueue.add(request);
    
    // Start processing if under limit
    if (_processingRequests.length < maxConcurrentRequests) {
      unawaited(_processQueue());
    }
    
    return request.id!;
  }

  static Future<void> _processQueue() async {
    while (_requestQueue.isNotEmpty && 
           _processingRequests.length < maxConcurrentRequests) {
      
      final request = _requestQueue.removeFirst();
      _processingRequests.add(request.id!);
      
      unawaited(_processRequest(request));
    }
  }

  static Future<void> _processRequest(AIRequest request) async {
    try {
      request.startedAt = DateTime.now();
      
      final result = await CircuitBreakerService.executeWithBreaker(
        'vertex_ai',
        () => _executeAIRequest(request),
      );
      
      request.completedAt = DateTime.now();
      request.result = result;
      request.status = AIRequestStatus.completed;
      
    } catch (e, stackTrace) {
      request.completedAt = DateTime.now();
      request.error = e.toString();
      request.status = AIRequestStatus.failed;
      
      await CrashReportingService.recordError(
        'AI request failed',
        e,
        stackTrace,
        additionalData: {'requestId': request.id},
      );
    } finally {
      _processingRequests.remove(request.id!);
      
      // Notify request completion
      RequestNotificationService.notifyCompletion(request);
    }
  }
}
```

### 6. Comprehensive Error Handling
```dart
// lib/core/error/ai_error_handler.dart
class AIErrorHandler {
  static const Map<String, AIErrorType> _errorPatterns = {
    'quota exceeded': AIErrorType.quotaExceeded,
    'rate limit': AIErrorType.rateLimited,
    'timeout': AIErrorType.timeout,
    'invalid request': AIErrorType.invalidRequest,
    'model overloaded': AIErrorType.serviceOverloaded,
    'authentication failed': AIErrorType.authenticationFailed,
  };

  static AIException handleError(dynamic error, StackTrace stackTrace) {
    final errorMessage = error.toString().toLowerCase();
    
    // Identify error type
    AIErrorType errorType = AIErrorType.unknown;
    for (final pattern in _errorPatterns.keys) {
      if (errorMessage.contains(pattern)) {
        errorType = _errorPatterns[pattern]!;
        break;
      }
    }

    // Create appropriate exception with retry strategy
    final aiException = AIException(
      type: errorType,
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
      retryStrategy: _getRetryStrategy(errorType),
    );

    // Log error with context
    _logError(aiException);
    
    return aiException;
  }

  static RetryStrategy _getRetryStrategy(AIErrorType errorType) {
    switch (errorType) {
      case AIErrorType.rateLimited:
        return RetryStrategy(
          maxRetries: 3,
          backoffMultiplier: 2.0,
          baseDelay: const Duration(seconds: 30),
        );
      case AIErrorType.timeout:
        return RetryStrategy(
          maxRetries: 2,
          backoffMultiplier: 1.5,
          baseDelay: const Duration(seconds: 10),
        );
      case AIErrorType.serviceOverloaded:
        return RetryStrategy(
          maxRetries: 5,
          backoffMultiplier: 3.0,
          baseDelay: const Duration(minutes: 1),
        );
      case AIErrorType.quotaExceeded:
        return RetryStrategy(
          maxRetries: 0, // Don't retry quota issues
          baseDelay: Duration.zero,
        );
      default:
        return RetryStrategy(
          maxRetries: 1,
          baseDelay: const Duration(seconds: 5),
        );
    }
  }
}
```

### 7. Monitoring and Analytics
```dart
// lib/core/services/analytics_service.dart
class AnalyticsService {
  static late FirebaseAnalytics _analytics;
  
  static Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  static Future<void> trackAIProcessingStart({
    required String requestId,
    required AIProcessingType type,
    required int imageSize,
    required int markerCount,
  }) async {
    await _analytics.logEvent(
      name: 'ai_processing_start',
      parameters: {
        'request_id': requestId,
        'processing_type': type.toString(),
        'image_size_mb': imageSize / (1024 * 1024),
        'marker_count': markerCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackAIProcessingComplete({
    required String requestId,
    required Duration processingTime,
    required bool success,
    String? errorType,
  }) async {
    await _analytics.logEvent(
      name: 'ai_processing_complete',
      parameters: {
        'request_id': requestId,
        'processing_time_seconds': processingTime.inSeconds,
        'success': success,
        'error_type': errorType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

### 8. Security Configuration
```dart
// lib/core/security/firebase_security.dart
class FirebaseSecurity {
  static Future<void> configureSecurityRules() async {
    // Firestore security rules
    const firestoreRules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Processing requests are user-specific
    match /processing_requests/{userId}/{requestId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Rate limiting: max 10 requests per minute per user
    match /rate_limits/{userId} {
      allow read, write: if request.auth != null && 
                          request.auth.uid == userId &&
                          resource.data.requests_per_minute < 10;
    }
  }
}
''';

    // Storage security rules  
    const storageRules = '''
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only access their own images
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Limit file size to 50MB
    match /{allPaths=**} {
      allow write: if request.resource.size < 50 * 1024 * 1024;
    }
  }
}
''';
  }
}
```

## Acceptance Criteria (Must All Pass)
1. ✅ Firebase initializes successfully across all environments
2. ✅ Vertex AI models load and respond within timeout limits
3. ✅ Circuit breaker prevents cascade failures
4. ✅ Request queue manages concurrent AI operations
5. ✅ Error handling covers all Vertex AI failure modes
6. ✅ Security rules prevent unauthorized access
7. ✅ Analytics track all critical metrics
8. ✅ Environment switching works correctly
9. ✅ Performance monitoring shows < 200ms overhead
10. ✅ Memory usage stays under 50MB for Firebase layer

**Implementation Priority:** Foundation for all AI features - must be bulletproof

**Quality Gate:** Zero Firebase errors in production, 99.9% AI service availability

**Performance Target:** < 5 second AI service initialization on cold start

---

**Next Step:** After completion, proceed to Authentication Domain Layer (Phase 2, Step 3)
