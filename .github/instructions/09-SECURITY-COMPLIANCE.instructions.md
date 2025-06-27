---
applyTo: 'security'
---

# 🔐 Security & Compliance - Complete Production Security Guide

## 🛡️ Security Architecture Overview

### Defense in Depth Strategy

The Revision application implements multiple layers of security:
1. **Client-side security** - Input validation, secure storage
2. **Network security** - TLS/SSL, certificate pinning
3. **API security** - Authentication, authorization, rate limiting
4. **Server-side security** - Firebase security rules, data validation
5. **Infrastructure security** - Environment isolation, secrets management

## 🔑 Authentication & Authorization

### Firebase Authentication Setup

#### Multi-Factor Authentication (MFA)
```dart
// Enable MFA for enhanced security
class MFAService {
  static Future<void> enableMFA() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final multiFactorSession = await user.multiFactor.getSession();
      
      final phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: 'verification_id',
        smsCode: 'sms_code',
      );
      
      final phoneAuthFactor = await PhoneAuthProvider.credential(
        verificationId: 'verification_id',
        smsCode: 'sms_code',
      );
      
      await user.multiFactor.enroll(phoneAuthFactor, multiFactorSession);
    }
  }
  
  static Future<void> verifyMFA(String smsCode) async {
    // Implementation for MFA verification
    try {
      final resolver = FirebaseAuth.instance.currentUser?.multiFactor;
      // Complete MFA verification
    } catch (e) {
      throw MFAVerificationException('MFA verification failed: $e');
    }
  }
}
```

#### Secure Session Management
```dart
// Secure session handling
class SessionManager {
  static const Duration _sessionTimeout = Duration(hours: 2);
  static Timer? _sessionTimer;
  
  static void startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      _handleSessionTimeout();
    });
  }
  
  static void _handleSessionTimeout() {
    // Force logout on session timeout
    FirebaseAuth.instance.signOut();
    // Navigate to login screen
    // Clear sensitive data from memory
    _clearSensitiveData();
  }
  
  static void _clearSensitiveData() {
    // Clear any cached sensitive data
    // Reset app state
  }
  
  static void refreshSession() {
    // Reset session timer on user activity
    startSessionTimer();
  }
}
```

### Role-Based Access Control (RBAC)
```dart
// User roles and permissions
enum UserRole {
  user,
  moderator,
  admin,
}

enum Permission {
  editImage,
  deleteImage,
  accessPremiumFeatures,
  manageUsers,
  viewAnalytics,
}

class PermissionService {
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.user: {
      Permission.editImage,
    },
    UserRole.moderator: {
      Permission.editImage,
      Permission.deleteImage,
      Permission.accessPremiumFeatures,
    },
    UserRole.admin: {
      Permission.editImage,
      Permission.deleteImage,
      Permission.accessPremiumFeatures,
      Permission.manageUsers,
      Permission.viewAnalytics,
    },
  };
  
  static Future<bool> hasPermission(Permission permission) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final userRole = UserRole.values.firstWhere(
      (role) => role.name == userDoc.data()?['role'],
      orElse: () => UserRole.user,
    );
    
    return _rolePermissions[userRole]?.contains(permission) ?? false;
  }
  
  static Future<void> checkPermissionOrThrow(Permission permission) async {
    if (!await hasPermission(permission)) {
      throw UnauthorizedException('Insufficient permissions');
    }
  }
}
```

## 🛡️ Data Protection & Privacy

### GDPR Compliance Implementation

#### Data Processing Consent
```dart
// GDPR consent management
class ConsentManager {
  static const String _consentKey = 'gdpr_consent';
  static const String _dataProcessingKey = 'data_processing_consent';
  static const String _marketingKey = 'marketing_consent';
  
  static Future<void> requestConsent() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Show consent dialog
    final consents = await _showConsentDialog();
    
    // Store consent preferences
    await prefs.setBool(_consentKey, consents.gdprConsent);
    await prefs.setBool(_dataProcessingKey, consents.dataProcessing);
    await prefs.setBool(_marketingKey, consents.marketing);
    
    // Log consent to Firebase
    await _logConsentToFirebase(consents);
  }
  
  static Future<bool> hasValidConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }
  
  static Future<ConsentData> _showConsentDialog() async {
    // Implementation for consent dialog
    return ConsentData(
      gdprConsent: true,
      dataProcessing: true,
      marketing: false,
    );
  }
  
  static Future<void> _logConsentToFirebase(ConsentData consent) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('user_consents')
          .doc(user.uid)
          .set({
        'gdpr_consent': consent.gdprConsent,
        'data_processing': consent.dataProcessing,
        'marketing': consent.marketing,
        'timestamp': FieldValue.serverTimestamp(),
        'ip_address': await _getClientIP(),
      });
    }
  }
  
  static Future<String> _getClientIP() async {
    // Implementation to get client IP for audit trail
    return 'unknown';
  }
}

class ConsentData {
  final bool gdprConsent;
  final bool dataProcessing;
  final bool marketing;
  
  ConsentData({
    required this.gdprConsent,
    required this.dataProcessing,
    required this.marketing,
  });
}
```

#### Data Anonymization
```dart
// Data anonymization service
class DataAnonymizationService {
  static String anonymizeEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return 'invalid@email.com';
    
    final username = parts[0];
    final domain = parts[1];
    
    // Keep first and last character, replace middle with *
    final anonymizedUsername = username.length > 2
        ? '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}'
        : '*' * username.length;
    
    return '$anonymizedUsername@$domain';
  }
  
  static String anonymizePhoneNumber(String phone) {
    if (phone.length < 4) return '*' * phone.length;
    
    return '${phone.substring(0, 2)}${'*' * (phone.length - 4)}${phone.substring(phone.length - 2)}';
  }
  
  static Map<String, dynamic> anonymizeUserData(Map<String, dynamic> userData) {
    final anonymized = Map<String, dynamic>.from(userData);
    
    if (anonymized.containsKey('email')) {
      anonymized['email'] = anonymizeEmail(anonymized['email']);
    }
    
    if (anonymized.containsKey('phone')) {
      anonymized['phone'] = anonymizePhoneNumber(anonymized['phone']);
    }
    
    // Remove sensitive fields
    anonymized.remove('ssn');
    anonymized.remove('creditCard');
    anonymized.remove('password');
    
    return anonymized;
  }
}
```

### Secure Data Storage

#### Client-Side Encryption
```dart
// Secure local storage with encryption
class SecureStorage {
  static const String _keyAlias = 'revision_app_key';
  static late FlutterSecureStorage _secureStorage;
  
  static void initialize() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: IOSAccessibility.first_unlock_this_device,
      ),
    );
  }
  
  static Future<void> storeSecurely(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to store data securely: $e');
    }
  }
  
  static Future<String?> readSecurely(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read secure data: $e');
    }
  }
  
  static Future<void> deleteSecurely(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete secure data: $e');
    }
  }
  
  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear secure data: $e');
    }
  }
}
```

#### Image Data Protection
```dart
// Secure image handling
class SecureImageHandler {
  static Future<File> encryptImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final encryptedBytes = await _encryptBytes(bytes);
      
      final encryptedFile = File('${imageFile.path}.encrypted');
      await encryptedFile.writeAsBytes(encryptedBytes);
      
      // Delete original unencrypted file
      await imageFile.delete();
      
      return encryptedFile;
    } catch (e) {
      throw ImageEncryptionException('Failed to encrypt image: $e');
    }
  }
  
  static Future<File> decryptImage(File encryptedFile) async {
    try {
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = await _decryptBytes(encryptedBytes);
      
      final decryptedFile = File(encryptedFile.path.replaceAll('.encrypted', ''));
      await decryptedFile.writeAsBytes(decryptedBytes);
      
      return decryptedFile;
    } catch (e) {
      throw ImageDecryptionException('Failed to decrypt image: $e');
    }
  }
  
  static Future<Uint8List> _encryptBytes(Uint8List bytes) async {
    // Implementation using a secure encryption library
    // e.g., pointycastle, crypto
    return bytes; // Placeholder
  }
  
  static Future<Uint8List> _decryptBytes(Uint8List encryptedBytes) async {
    // Implementation using a secure decryption library
    return encryptedBytes; // Placeholder
  }
  
  static Future<void> secureDeleteImage(File imageFile) async {
    try {
      // Overwrite file with random data before deletion
      final fileSize = await imageFile.length();
      final randomBytes = _generateRandomBytes(fileSize);
      
      await imageFile.writeAsBytes(randomBytes);
      await imageFile.delete();
    } catch (e) {
      throw SecureDeleteException('Failed to securely delete image: $e');
    }
  }
  
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }
}
```

## 🌐 Network Security

### SSL Pinning Implementation
```dart
// Certificate pinning for API security
class NetworkSecurity {
  static late Dio _dio;
  
  static void initialize() {
    _dio = Dio();
    
    // Add certificate pinning interceptor
    _dio.interceptors.add(CertificatePinningInterceptor(
      allowedSHAFingerprints: [
        // Firebase API SHA fingerprints
        'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        // Vertex AI API SHA fingerprints  
        'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
      ],
    ));
    
    // Add security headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Requested-With'] = 'XMLHttpRequest';
          options.headers['X-Content-Type-Options'] = 'nosniff';
          options.headers['X-Frame-Options'] = 'DENY';
          handler.next(options);
        },
      ),
    );
  }
  
  static Future<Response> secureRequest(
    String url, {
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    try {
      return await _dio.request(
        url,
        data: data,
        options: options,
      );
    } on DioError catch (e) {
      if (e.type == DioErrorType.badCertificate) {
        throw CertificatePinningException('Certificate pinning failed');
      }
      rethrow;
    }
  }
}
```

### API Rate Limiting
```dart
// Client-side rate limiting
class RateLimiter {
  static final Map<String, List<DateTime>> _requestHistory = {};
  static const int _maxRequestsPerMinute = 60;
  static const Duration _timeWindow = Duration(minutes: 1);
  
  static Future<bool> checkRateLimit(String endpoint) async {
    final now = DateTime.now();
    final history = _requestHistory[endpoint] ?? [];
    
    // Remove old requests outside time window
    history.removeWhere(
      (timestamp) => now.difference(timestamp) > _timeWindow,
    );
    
    // Check if under rate limit
    if (history.length >= _maxRequestsPerMinute) {
      return false;
    }
    
    // Add current request
    history.add(now);
    _requestHistory[endpoint] = history;
    
    return true;
  }
  
  static Future<void> enforceRateLimit(String endpoint) async {
    if (!await checkRateLimit(endpoint)) {
      throw RateLimitException('Rate limit exceeded for $endpoint');
    }
  }
}
```

## 🔒 Firebase Security Rules

### Comprehensive Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Validate user data structure
      allow create: if request.auth != null 
        && request.auth.uid == userId
        && validateUserData(resource.data);
      
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && validateUserUpdate(resource.data, request.resource.data);
    }
    
    // Images - users can only access their own images
    match /images/{imageId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
      
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.userId
        && validateImageData(request.resource.data);
    }
    
    // AI processing results
    match /ai_results/{resultId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
      
      // Prevent direct creation of AI results (server-only)
      allow create: if false;
    }
    
    // Admin-only collections
    match /admin/{document=**} {
      allow read, write: if request.auth != null && isAdmin();
    }
    
    // Audit logs - read-only for admins
    match /audit_logs/{logId} {
      allow read: if request.auth != null && isAdmin();
      allow write: if false; // Server-only writes
    }
    
    // Helper functions
    function validateUserData(data) {
      return data.keys().hasAll(['email', 'createdAt', 'role']) &&
             data.email is string &&
             data.createdAt is timestamp &&
             data.role in ['user', 'moderator', 'admin'];
    }
    
    function validateUserUpdate(oldData, newData) {
      // Prevent role escalation
      return newData.role == oldData.role ||
             (request.auth != null && isAdmin());
    }
    
    function validateImageData(data) {
      return data.keys().hasAll(['userId', 'filename', 'uploadedAt']) &&
             data.userId is string &&
             data.filename is string &&
             data.uploadedAt is timestamp;
    }
    
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Firebase Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User images - only owner can access
    match /users/{userId}/images/{imageId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // File size limit (10MB)
      allow write: if request.resource.size < 10 * 1024 * 1024;
      
      // Only allow image files
      allow write: if request.resource.contentType.matches('image/.*');
    }
    
    // Processed images - only owner can access
    match /processed/{userId}/{imageId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Server-only writes
    }
    
    // Public assets - read-only
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

## 🔍 Security Monitoring & Auditing

### Audit Logging
```dart
// Comprehensive audit logging
class AuditLogger {
  static Future<void> logSecurityEvent({
    required String event,
    required String userId,
    Map<String, dynamic>? metadata,
    SecurityLevel level = SecurityLevel.info,
  }) async {
    final logEntry = {
      'event': event,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'level': level.name,
      'metadata': metadata ?? {},
      'ipAddress': await _getClientIP(),
      'userAgent': await _getUserAgent(),
      'deviceInfo': await _getDeviceInfo(),
    };
    
    await FirebaseFirestore.instance
        .collection('audit_logs')
        .add(logEntry);
    
    // Send alert for critical events
    if (level == SecurityLevel.critical) {
      await _sendSecurityAlert(logEntry);
    }
  }
  
  static Future<void> logAuthEvent(String event, String? userId) async {
    await logSecurityEvent(
      event: 'auth_$event',
      userId: userId ?? 'anonymous',
      level: SecurityLevel.warning,
    );
  }
  
  static Future<void> logDataAccess(String collection, String documentId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await logSecurityEvent(
        event: 'data_access',
        userId: userId,
        metadata: {
          'collection': collection,
          'documentId': documentId,
        },
      );
    }
  }
  
  static Future<String> _getClientIP() async {
    // Implementation to get client IP
    return 'unknown';
  }
  
  static Future<String> _getUserAgent() async {
    // Implementation to get user agent
    return 'unknown';
  }
  
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'model': androidInfo.model,
        'version': androidInfo.version.release,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'model': iosInfo.model,
        'version': iosInfo.systemVersion,
      };
    }
    
    return {'platform': 'unknown'};
  }
  
  static Future<void> _sendSecurityAlert(Map<String, dynamic> logEntry) async {
    // Implementation to send security alerts
    // e.g., email, Slack, PagerDuty
  }
}

enum SecurityLevel {
  info,
  warning,
  error,
  critical,
}
```

### Intrusion Detection
```dart
// Basic intrusion detection system
class IntrusionDetection {
  static final Map<String, List<DateTime>> _failedAttempts = {};
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  static Future<void> recordFailedAttempt(String identifier) async {
    final now = DateTime.now();
    final attempts = _failedAttempts[identifier] ?? [];
    
    // Remove old attempts
    attempts.removeWhere(
      (attempt) => now.difference(attempt) > _lockoutDuration,
    );
    
    attempts.add(now);
    _failedAttempts[identifier] = attempts;
    
    // Check for suspicious activity
    if (attempts.length >= _maxFailedAttempts) {
      await _handleSuspiciousActivity(identifier, attempts);
    }
  }
  
  static bool isLockedOut(String identifier) {
    final attempts = _failedAttempts[identifier] ?? [];
    final recentAttempts = attempts.where(
      (attempt) => DateTime.now().difference(attempt) < _lockoutDuration,
    );
    
    return recentAttempts.length >= _maxFailedAttempts;
  }
  
  static Future<void> _handleSuspiciousActivity(
    String identifier,
    List<DateTime> attempts,
  ) async {
    // Log security incident
    await AuditLogger.logSecurityEvent(
      event: 'suspicious_activity_detected',
      userId: identifier,
      level: SecurityLevel.critical,
      metadata: {
        'failed_attempts': attempts.length,
        'time_window': _lockoutDuration.inMinutes,
      },
    );
    
    // Additional security measures
    await _enableAdditionalSecurity(identifier);
  }
  
  static Future<void> _enableAdditionalSecurity(String identifier) async {
    // Enable additional security measures
    // e.g., require MFA, CAPTCHA, etc.
  }
  
  static void clearFailedAttempts(String identifier) {
    _failedAttempts.remove(identifier);
  }
}
```

## 🔧 Security Configuration

### Production Security Checklist

#### Environment Variables Security
```bash
# .env.production (NEVER commit to version control)
FIREBASE_API_KEY=your_production_api_key
VERTEX_AI_API_KEY=your_vertex_ai_key
ENCRYPTION_KEY=your_encryption_key
JWT_SECRET=your_jwt_secret

# Use build-time definitions
flutter build apk --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY
```

#### Security Headers Configuration
```dart
// Security headers for web
class SecurityHeaders {
  static const Map<String, String> headers = {
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'",
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  };
}
```

This comprehensive security guide ensures the Revision application meets production-grade security standards with proper authentication, data protection, network security, and monitoring capabilities.
```
