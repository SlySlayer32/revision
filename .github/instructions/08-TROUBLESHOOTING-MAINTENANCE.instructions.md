```instructions
---
applyTo: 'troubleshooting'
---

# 🔧 Troubleshooting & Maintenance - Complete Problem Resolution Guide

## 🚨 Critical Issue Resolution

### Firebase Connection Issues

#### Problem: Firebase not connecting
```bash
# Check configuration
flutter doctor -v
firebase projects:list

# Verify credentials
firebase login --reauth
flutterfire configure
```

#### Problem: Authentication failures
```dart
// Debug authentication state
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  print('Auth state changed: ${user?.uid ?? 'null'}');
});

// Check Firebase Console > Authentication > Users
// Verify user exists and is enabled
```

#### Problem: Firestore permission denied
```javascript
// Check Firestore security rules
// Navigate to Firebase Console > Firestore > Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access on all documents to any user signed in to the application
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Build & Deployment Issues

#### Problem: Build failures on Android
```bash
# Clear build cache
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get

# Check Android SDK
flutter doctor --android-licenses

# Update Gradle (if needed)
cd android
./gradlew wrapper --gradle-version 8.0
```

#### Problem: iOS build failures
```bash
# Clean iOS build
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter pub get

# Check iOS setup
flutter doctor --verbose
xcode-select --install
```

#### Problem: Web build issues
```bash
# Enable web (if not enabled)
flutter config --enable-web
flutter create . --platform web

# Clear web cache
flutter clean
flutter pub get
flutter build web --release
```

### AI Integration Issues

#### Problem: Vertex AI API failures
```dart
// Check API key configuration
void debugVertexAI() {
  final apiKey = const String.fromEnvironment('VERTEX_AI_API_KEY');
  print('API Key configured: ${apiKey.isNotEmpty}');
  
  // Test connection
  // Implementation depends on your AI service setup
}
```

#### Problem: Image processing failures
```dart
// Debug image processing pipeline
Future<void> debugImageProcessing(File imageFile) async {
  try {
    // Check file exists and is readable
    final exists = await imageFile.exists();
    final size = await imageFile.length();
    print('Image exists: $exists, Size: $size bytes');
    
    // Check image format
    final bytes = await imageFile.readAsBytes();
    print('Image header: ${bytes.take(10).toList()}');
    
  } catch (e) {
    print('Image processing error: $e');
  }
}
```

## 🔍 Performance Monitoring & Optimization

### Memory Management

#### Detect Memory Leaks
```bash
# Run with memory profiling
flutter run --profile --dart-define=FLUTTER_WEB_USE_SKIA=true

# Use DevTools for memory analysis
flutter pub global activate devtools
flutter pub global run devtools
```

#### Image Memory Optimization
```dart
// Optimize image loading
class OptimizedImageWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  
  const OptimizedImageWidget({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }
}
```

### Performance Profiling

#### CPU Profiling
```bash
# Profile app performance
flutter run --profile
# Open DevTools and navigate to Performance tab
```

#### Network Performance
```dart
// Monitor network requests
class NetworkMonitor {
  static final List<NetworkRequest> _requests = [];
  
  static void logRequest(String url, Duration duration, int statusCode) {
    _requests.add(NetworkRequest(
      url: url,
      duration: duration,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    ));
    
    // Alert on slow requests
    if (duration.inMilliseconds > 5000) {
      print('SLOW REQUEST: $url took ${duration.inMilliseconds}ms');
    }
  }
  
  static List<NetworkRequest> getSlowRequests() {
    return _requests.where((req) => req.duration.inMilliseconds > 3000).toList();
  }
}

class NetworkRequest {
  final String url;
  final Duration duration;
  final int statusCode;
  final DateTime timestamp;
  
  NetworkRequest({
    required this.url,
    required this.duration,
    required this.statusCode,
    required this.timestamp,
  });
}
```

## 🛠️ Maintenance Tasks

### Regular Maintenance Checklist

#### Weekly Tasks
```bash
# Update dependencies
flutter pub outdated
flutter pub upgrade

# Run security audit
flutter analyze
dart analyze

# Update Firebase SDK
firebase use --clear
firebase use revision-464202
firebase deploy --only functions
```

#### Monthly Tasks
```bash
# Update Flutter SDK
flutter upgrade
flutter doctor

# Review and update API keys
# Check Firebase usage and billing
# Review crash reports in Firebase Crashlytics
# Update security rules if needed
```

#### Quarterly Tasks
```bash
# Review app performance metrics
# Update CI/CD pipelines
# Security penetration testing
# Code review and refactoring
# Documentation updates
```

### Database Maintenance

#### Firestore Cleanup
```dart
// Automated cleanup service
class FirestoreCleanupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<void> cleanupOldData() async {
    // Delete old temporary files
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    final oldFiles = await _db
        .collection('temp_files')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();
    
    final batch = _db.batch();
    for (final doc in oldFiles.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print('Cleaned up ${oldFiles.docs.length} old temporary files');
  }
  
  Future<void> optimizeIndices() async {
    // Review and optimize database indices
    // This should be done through Firebase Console
    print('Review composite indices in Firebase Console');
  }
}
```

#### Storage Cleanup
```dart
// Clean up Firebase Storage
class StorageCleanupService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Future<void> cleanupUnusedFiles() async {
    try {
      // List all files in storage
      final result = await _storage.ref().listAll();
      
      for (final ref in result.items) {
        // Check if file is referenced in Firestore
        final isReferenced = await _isFileReferenced(ref.name);
        
        if (!isReferenced) {
          await ref.delete();
          print('Deleted unused file: ${ref.name}');
        }
      }
    } catch (e) {
      print('Storage cleanup error: $e');
    }
  }
  
  Future<bool> _isFileReferenced(String fileName) async {
    // Check if file is referenced in any Firestore document
    final query = await FirebaseFirestore.instance
        .collectionGroup('images')
        .where('fileName', isEqualTo: fileName)
        .get();
    
    return query.docs.isNotEmpty;
  }
}
```

## 🔐 Security Monitoring

### Security Audit Checklist

#### API Security
```dart
// API key rotation service
class SecurityService {
  static Future<void> auditApiKeys() async {
    // Check for exposed API keys
    final apiKeys = [
      const String.fromEnvironment('VERTEX_AI_API_KEY'),
      const String.fromEnvironment('FIREBASE_API_KEY'),
    ];
    
    for (final key in apiKeys) {
      if (key.isEmpty) {
        print('WARNING: Missing API key');
      } else if (key.length < 32) {
        print('WARNING: API key may be invalid');
      }
    }
  }
  
  static Future<void> checkSecurityRules() async {
    // Automated security rule validation
    // This should connect to Firebase Management API
    print('Run security rules validation');
  }
}
```

#### User Data Protection
```dart
// GDPR compliance helpers
class DataProtectionService {
  static Future<void> exportUserData(String userId) async {
    // Export all user data for GDPR compliance
    final userData = await _collectUserData(userId);
    
    // Create downloadable export
    final export = jsonEncode(userData);
    // Provide secure download link
  }
  
  static Future<void> deleteUserData(String userId) async {
    // Complete user data deletion
    final batch = FirebaseFirestore.instance.batch();
    
    // Delete from all collections
    final collections = ['users', 'images', 'edits', 'subscriptions'];
    
    for (final collection in collections) {
      final docs = await FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
    }
    
    await batch.commit();
    print('Deleted all data for user: $userId');
  }
  
  static Future<Map<String, dynamic>> _collectUserData(String userId) async {
    // Implementation depends on your data structure
    return {};
  }
}
```

## 📊 Monitoring & Alerting

### Performance Monitoring Setup

#### Custom Metrics
```dart
// Custom performance metrics
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }
  
  static void endTimer(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      // Log to Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'performance_metric',
        parameters: {
          'operation': operation,
          'duration_ms': duration,
        },
      );
      
      // Alert on slow operations
      if (duration > 5000) {
        _alertSlowOperation(operation, duration);
      }
      
      _timers.remove(operation);
    }
  }
  
  static void _alertSlowOperation(String operation, int duration) {
    // Send alert to monitoring service
    print('ALERT: Slow operation $operation took ${duration}ms');
  }
}
```

#### Error Tracking
```dart
// Comprehensive error tracking
class ErrorTracker {
  static void reportError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) {
    // Log to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      context: context,
    );
    
    // Log to local debugging
    if (kDebugMode) {
      print('ERROR: $error');
      if (stackTrace != null) {
        print('STACK TRACE: $stackTrace');
      }
      if (context != null) {
        print('CONTEXT: $context');
      }
    }
    
    // Send to custom monitoring service
    _sendToMonitoringService(error, stackTrace, context);
  }
  
  static void _sendToMonitoringService(
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  ) {
    // Implementation for custom monitoring service
    // e.g., Sentry, Bugsnag, etc.
  }
}
```

## 🔄 Backup & Recovery

### Data Backup Strategy

#### Automated Backups
```dart
// Automated backup service
class BackupService {
  static Future<void> createDatabaseBackup() async {
    try {
      // Export Firestore data
      // This typically requires server-side implementation
      print('Creating database backup...');
      
      // Backup to Cloud Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = 'backups/firestore_backup_$timestamp.json';
      
      // Implementation depends on your backup strategy
      print('Backup saved to: $backupPath');
      
    } catch (e) {
      ErrorTracker.reportError(e, StackTrace.current);
    }
  }
  
  static Future<void> createStorageBackup() async {
    try {
      // Backup Firebase Storage files
      // Implementation depends on your storage structure
      print('Creating storage backup...');
      
    } catch (e) {
      ErrorTracker.reportError(e, StackTrace.current);
    }
  }
}
```

#### Disaster Recovery Plan
1. **Database Recovery**: Use Firebase export/import tools
2. **Storage Recovery**: Use Cloud Storage backup
3. **Code Recovery**: Git repository with proper branching
4. **Configuration Recovery**: Environment variables backup
5. **API Keys Recovery**: Secure key management system

## 📈 Analytics & Insights

### User Behavior Analytics
```dart
// Enhanced analytics tracking
class AnalyticsService {
  static Future<void> trackUserJourney(String action, {
    Map<String, dynamic>? parameters,
  }) async {
    await FirebaseAnalytics.instance.logEvent(
      name: action,
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        ...?parameters,
      },
    );
  }
  
  static Future<void> trackPerformance(String feature, Duration duration) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'performance_timing',
      parameters: {
        'feature': feature,
        'duration_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> trackError(String errorType, String errorMessage) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

This comprehensive troubleshooting and maintenance guide provides production-ready solutions for monitoring, debugging, and maintaining the Revision application. Regular use of these procedures ensures optimal app performance and user experience.
```
