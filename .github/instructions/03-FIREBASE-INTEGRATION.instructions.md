---
applyTo: 'firebase'
---

# 🔥 Firebase Integration - Complete Production Setup Guide

## 📋 Firebase Services Overview

Firebase provides a comprehensive Backend-as-a-Service (BaaS) platform that handles authentication, database, storage, hosting, and cloud functions. This guide covers production-grade implementation for all Firebase services.

## 🚀 Initial Firebase Project Setup

### 1. Create Firebase Projects (Multi-Environment)

#### Development Environment
```bash
# Create project in Firebase Console
# Project Name: Revision Development
# Project ID: revision-464202-dev
# Location: us-central1 (or your preferred region)
```

#### Staging Environment
```bash
# Create project in Firebase Console
# Project Name: Revision Staging
# Project ID: revision-464202-staging
# Location: us-central1 (same as development)
```

#### Production Environment
```bash
# Create project in Firebase Console
# Project Name: Revision Production
# Project ID: revision-464202
# Location: us-central1 (same as development)
```

### 2. Configure Flutter for Firebase

#### Install Firebase Tools
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login
```

#### Generate Firebase Configuration Files
```bash
# Navigate to your Flutter project root
cd /path/to/revision

# Configure for development
flutterfire configure \
  --project=revision-464202-dev \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=com.example.revision.dev \
  --android-package-name=com.example.revision.dev \
  --web-app-id=1:123456789:web:abcdef \
  --ios-out=ios/Runner/GoogleService-Info-dev.plist \
  --android-out=android/app/src/dev/google-services.json

# Configure for staging
flutterfire configure \
  --project=revision-464202-staging \
  --out=lib/firebase_options_staging.dart \
  --ios-bundle-id=com.example.revision.staging \
  --android-package-name=com.example.revision.staging \
  --web-app-id=1:123456789:web:ghijkl \
  --ios-out=ios/Runner/GoogleService-Info-staging.plist \
  --android-out=android/app/src/staging/google-services.json

# Configure for production
flutterfire configure \
  --project=revision-464202 \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.example.revision \
  --android-package-name=com.example.revision \
  --web-app-id=1:123456789:web:mnopqr \
  --ios-out=ios/Runner/GoogleService-Info-prod.plist \
  --android-out=android/app/src/production/google-services.json
```

### 3. Firebase Environment Configuration

#### Firebase Options Manager
```dart
// lib/core/firebase/firebase_options_manager.dart
import 'package:firebase_core/firebase_core.dart';

import '../config/environment.dart';
import '../../firebase_options_dev.dart' as dev;
import '../../firebase_options_staging.dart' as staging;
import '../../firebase_options_prod.dart' as prod;

class FirebaseOptionsManager {
  static FirebaseOptions getCurrentOptions() {
    switch (EnvConfig.environment) {
      case Environment.development:
        return dev.DefaultFirebaseOptions.currentPlatform;
      case Environment.staging:
        return staging.DefaultFirebaseOptions.currentPlatform;
      case Environment.production:
        return prod.DefaultFirebaseOptions.currentPlatform;
    }
  }

  static String get projectId {
    switch (EnvConfig.environment) {
      case Environment.development:
        return dev.DefaultFirebaseOptions.currentPlatform.projectId;
      case Environment.staging:
        return staging.DefaultFirebaseOptions.currentPlatform.projectId;
      case Environment.production:
        return prod.DefaultFirebaseOptions.currentPlatform.projectId;
    }
  }

  static String get storageBucket {
    switch (EnvConfig.environment) {
      case Environment.development:
        return dev.DefaultFirebaseOptions.currentPlatform.storageBucket ?? '';
      case Environment.staging:
        return staging.DefaultFirebaseOptions.currentPlatform.storageBucket ?? '';
      case Environment.production:
        return prod.DefaultFirebaseOptions.currentPlatform.storageBucket ?? '';
    }
  }
}
```

#### Firebase Initialization
```dart
// lib/core/firebase/firebase_initializer.dart
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../config/environment.dart';
import 'firebase_options_manager.dart';

class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: FirebaseOptionsManager.getCurrentOptions(),
      );

      // Configure Firebase services
      await _configureFirebaseServices();

      // Setup emulators for development
      if (EnvConfig.isDevelopment && kDebugMode) {
        await _connectToEmulators();
      }

      // Configure App Check for security
      await _configureAppCheck();

      // Configure Crashlytics
      await _configureCrashlytics();

      log('🔥 Firebase initialized successfully for ${EnvConfig.environment.name}');
    } catch (e, stackTrace) {
      log('❌ Firebase initialization failed: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> _configureFirebaseServices() async {
    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Configure Functions region
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }

  static Future<void> _connectToEmulators() async {
    try {
      const host = '127.0.0.1';
      
      // Connect to Authentication Emulator
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      
      // Connect to Firestore Emulator
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      
      // Connect to Storage Emulator
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      
      // Connect to Functions Emulator
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      
      log('🔧 Connected to Firebase Emulators');
    } catch (e) {
      log('⚠️ Failed to connect to emulators: $e');
    }
  }

  static Future<void> _configureAppCheck() async {
    if (!kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        // Use reCAPTCHA for web
        webRecaptchaSiteKey: const String.fromEnvironment('RECAPTCHA_SITE_KEY'),
        // Use DeviceCheck for iOS
        appleProvider: AppleProvider.deviceCheck,
        // Use Play Integrity for Android
        androidProvider: AndroidProvider.playIntegrity,
      );
    } else {
      // For debug mode, use debug provider
      await FirebaseAppCheck.instance.activate(
        webRecaptchaSiteKey: 'debug-key',
        appleProvider: AppleProvider.debug,
        androidProvider: AndroidProvider.debug,
      );
    }
  }

  static Future<void> _configureCrashlytics() async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      // Set custom keys for better debugging
      await FirebaseCrashlytics.instance.setCustomKey('environment', EnvConfig.environment.name);
      await FirebaseCrashlytics.instance.setCustomKey('project_id', FirebaseOptionsManager.projectId);
      
      // Set up automatic crash reporting
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      
      // Handle Dart errors
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }
}
```

## 🔐 Firebase Authentication Implementation

### Authentication Configuration

#### Enable Authentication Methods in Firebase Console
1. **Email/Password Authentication**
   - Go to Authentication → Sign-in method
   - Enable Email/Password provider
   - Configure email templates (verification, password reset)

2. **Google Sign-In**
   - Enable Google provider
   - Configure OAuth consent screen
   - Add authorized domains

3. **Additional Providers (Optional)**
   - Apple Sign-In for iOS
   - Facebook, Twitter, GitHub as needed

#### Authentication Data Source Implementation
```dart
// lib/features/authentication/data/datasources/remote/firebase_auth_data_source.dart
import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/error/exceptions.dart';
import '../../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String? displayName);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<UserModel?> getCurrentUser();
  Future<void> updateProfile(String? displayName, String? photoUrl);
  Future<void> updateEmail(String newEmail);
  Future<void> updatePassword(String newPassword);
  Future<void> deleteAccount();
  Future<void> reloadUser();
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  FirebaseAuthDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        await firebaseUser.reload();
        final updatedUser = _firebaseAuth.currentUser;
        return updatedUser != null ? UserModel.fromFirebaseUser(updatedUser) : null;
      }
      return null;
    });
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      log('🔐 Attempting email sign in for: $email');
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException('Sign in failed: No user returned from Firebase');
      }

      await credential.user!.reload();
      final updatedUser = _firebaseAuth.currentUser!;

      log('✅ Email sign in successful for: ${updatedUser.email}');
      return UserModel.fromFirebaseUser(updatedUser);
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error during email sign in: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error during email sign in: $e');
      throw AuthException('Sign in failed: An unexpected error occurred');
    }
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String? displayName) async {
    try {
      log('📝 Attempting email sign up for: $email');
      
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException('Sign up failed: No user returned from Firebase');
      }

      // Update display name if provided
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(displayName.trim());
      }

      // Send email verification
      await credential.user!.sendEmailVerification();
      
      // Reload to get updated user data
      await credential.user!.reload();
      final updatedUser = _firebaseAuth.currentUser!;

      log('✅ Email sign up successful for: ${updatedUser.email}');
      return UserModel.fromFirebaseUser(updatedUser);
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error during email sign up: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error during email sign up: $e');
      throw AuthException('Sign up failed: An unexpected error occurred');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      log('🔍 Attempting Google sign in');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const AuthException('Google sign in was cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw const AuthException('Failed to get Google authentication tokens');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw const AuthException('Google sign in failed: No user returned from Firebase');
      }

      await userCredential.user!.reload();
      final updatedUser = _firebaseAuth.currentUser!;

      log('✅ Google sign in successful for: ${updatedUser.email}');
      return UserModel.fromFirebaseUser(updatedUser);
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error during Google sign in: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error during Google sign in: $e');
      throw AuthException('Google sign in failed: An unexpected error occurred');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      log('🚪 Signing out user');
      
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      log('✅ Sign out successful');
    } catch (e) {
      log('❌ Error during sign out: $e');
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      log('📧 Sending password reset email to: $email');
      
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
      
      log('✅ Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error sending password reset: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error sending password reset: $e');
      throw AuthException('Password reset failed: An unexpected error occurred');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }

      if (user.emailVerified) {
        throw const AuthException('Email is already verified');
      }

      log('📧 Sending email verification to: ${user.email}');
      
      await user.sendEmailVerification();
      
      log('✅ Email verification sent successfully');
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error sending email verification: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error sending email verification: $e');
      throw AuthException('Email verification failed: An unexpected error occurred');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      await firebaseUser.reload();
      final updatedUser = _firebaseAuth.currentUser;
      
      return updatedUser != null ? UserModel.fromFirebaseUser(updatedUser) : null;
    } catch (e) {
      log('❌ Error getting current user: $e');
      throw AuthException('Get current user failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updateProfile(String? displayName, String? photoUrl) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }

      log('👤 Updating user profile');
      
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
      await user.reload();
      
      log('✅ Profile updated successfully');
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error updating profile: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error updating profile: $e');
      throw AuthException('Profile update failed: An unexpected error occurred');
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }

      log('📧 Updating user email to: $newEmail');
      
      await user.updateEmail(newEmail.trim().toLowerCase());
      await user.sendEmailVerification();
      await user.reload();
      
      log('✅ Email updated successfully');
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error updating email: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error updating email: $e');
      throw AuthException('Email update failed: An unexpected error occurred');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }

      log('🔐 Updating user password');
      
      await user.updatePassword(newPassword);
      
      log('✅ Password updated successfully');
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error updating password: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error updating password: $e');
      throw AuthException('Password update failed: An unexpected error occurred');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }

      log('🗑️ Deleting user account');
      
      await user.delete();
      
      log('✅ Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      log('❌ Firebase Auth error deleting account: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      log('❌ Unexpected error deleting account: $e');
      throw AuthException('Account deletion failed: An unexpected error occurred');
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      log('❌ Error reloading user: $e');
      // Don't throw here as this is often called in background
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been temporarily disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently not available.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password with at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      case 'credential-already-in-use':
        return 'This account is already linked to another user.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'invalid-credential':
        return 'The provided credentials are invalid or have expired.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please try again.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid. Please request a new verification code.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}
```

## 🗄️ Cloud Firestore Implementation

### Firestore Setup & Configuration

#### Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only access their own edited images
    match /editedImages/{imageId} {
      allow read, write: if request.auth != null && 
                            resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
    }
    
    // Users can read public app configuration
    match /appConfig/{configId} {
      allow read: if true;
      allow write: if false; // Only admins via console
    }
    
    // AI processing history (user-specific)
    match /aiProcessing/{processingId} {
      allow read, write: if request.auth != null && 
                            resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
    }
  }
}
```

#### Firestore Indexes
```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "editedImages",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "aiProcessing",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "processedAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

#### Firestore Data Source Implementation
```dart
// lib/features/image_editor/data/datasources/remote/firestore_data_source.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../core/error/exceptions.dart';
import '../../models/edited_image_model.dart';
import '../../models/ai_processing_model.dart';

abstract class FirestoreDataSource {
  Future<void> saveEditedImage(EditedImageModel editedImage);
  Future<List<EditedImageModel>> getUserEditedImages(String userId);
  Future<EditedImageModel?> getEditedImage(String imageId);
  Future<void> deleteEditedImage(String imageId);
  Future<void> saveAIProcessingResult(AIProcessingModel processing);
  Future<List<AIProcessingModel>> getUserAIProcessingHistory(String userId);
  Stream<List<EditedImageModel>> watchUserEditedImages(String userId);
}

class FirestoreDataSourceImpl implements FirestoreDataSource {
  FirestoreDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore,
       _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const String _editedImagesCollection = 'editedImages';
  static const String _aiProcessingCollection = 'aiProcessing';

  @override
  Future<void> saveEditedImage(EditedImageModel editedImage) async {
    try {
      _ensureUserAuthenticated();
      
      log('💾 Saving edited image: ${editedImage.id}');
      
      await _firestore
          .collection(_editedImagesCollection)
          .doc(editedImage.id)
          .set(editedImage.toJson());
      
      log('✅ Edited image saved successfully');
    } on FirebaseException catch (e) {
      log('❌ Firestore error saving edited image: ${e.code} - ${e.message}');
      throw ServerException('Failed to save edited image: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error saving edited image: $e');
      throw ServerException('Failed to save edited image: An unexpected error occurred');
    }
  }

  @override
  Future<List<EditedImageModel>> getUserEditedImages(String userId) async {
    try {
      _ensureUserAuthenticated();
      
      log('📥 Fetching edited images for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_editedImagesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final images = querySnapshot.docs
          .map((doc) => EditedImageModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      log('✅ Fetched ${images.length} edited images');
      return images;
    } on FirebaseException catch (e) {
      log('❌ Firestore error fetching edited images: ${e.code} - ${e.message}');
      throw ServerException('Failed to fetch edited images: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error fetching edited images: $e');
      throw ServerException('Failed to fetch edited images: An unexpected error occurred');
    }
  }

  @override
  Future<EditedImageModel?> getEditedImage(String imageId) async {
    try {
      _ensureUserAuthenticated();
      
      log('📥 Fetching edited image: $imageId');
      
      final docSnapshot = await _firestore
          .collection(_editedImagesCollection)
          .doc(imageId)
          .get();

      if (!docSnapshot.exists) {
        log('⚠️ Edited image not found: $imageId');
        return null;
      }

      final image = EditedImageModel.fromJson({
        'id': docSnapshot.id,
        ...docSnapshot.data()!,
      });
      
      log('✅ Edited image fetched successfully');
      return image;
    } on FirebaseException catch (e) {
      log('❌ Firestore error fetching edited image: ${e.code} - ${e.message}');
      throw ServerException('Failed to fetch edited image: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error fetching edited image: $e');
      throw ServerException('Failed to fetch edited image: An unexpected error occurred');
    }
  }

  @override
  Future<void> deleteEditedImage(String imageId) async {
    try {
      _ensureUserAuthenticated();
      
      log('🗑️ Deleting edited image: $imageId');
      
      await _firestore
          .collection(_editedImagesCollection)
          .doc(imageId)
          .delete();
      
      log('✅ Edited image deleted successfully');
    } on FirebaseException catch (e) {
      log('❌ Firestore error deleting edited image: ${e.code} - ${e.message}');
      throw ServerException('Failed to delete edited image: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error deleting edited image: $e');
      throw ServerException('Failed to delete edited image: An unexpected error occurred');
    }
  }

  @override
  Future<void> saveAIProcessingResult(AIProcessingModel processing) async {
    try {
      _ensureUserAuthenticated();
      
      log('💾 Saving AI processing result: ${processing.id}');
      
      await _firestore
          .collection(_aiProcessingCollection)
          .doc(processing.id)
          .set(processing.toJson());
      
      log('✅ AI processing result saved successfully');
    } on FirebaseException catch (e) {
      log('❌ Firestore error saving AI processing result: ${e.code} - ${e.message}');
      throw ServerException('Failed to save AI processing result: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error saving AI processing result: $e');
      throw ServerException('Failed to save AI processing result: An unexpected error occurred');
    }
  }

  @override
  Future<List<AIProcessingModel>> getUserAIProcessingHistory(String userId) async {
    try {
      _ensureUserAuthenticated();
      
      log('📥 Fetching AI processing history for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_aiProcessingCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('processedAt', descending: true)
          .limit(50) // Limit to last 50 processing records
          .get();

      final history = querySnapshot.docs
          .map((doc) => AIProcessingModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      log('✅ Fetched ${history.length} AI processing records');
      return history;
    } on FirebaseException catch (e) {
      log('❌ Firestore error fetching AI processing history: ${e.code} - ${e.message}');
      throw ServerException('Failed to fetch AI processing history: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error fetching AI processing history: $e');
      throw ServerException('Failed to fetch AI processing history: An unexpected error occurred');
    }
  }

  @override
  Stream<List<EditedImageModel>> watchUserEditedImages(String userId) {
    try {
      _ensureUserAuthenticated();
      
      log('👁️ Watching edited images for user: $userId');
      
      return _firestore
          .collection(_editedImagesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => EditedImageModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();
      });
    } on FirebaseException catch (e) {
      log('❌ Firestore error watching edited images: ${e.code} - ${e.message}');
      throw ServerException('Failed to watch edited images: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error watching edited images: $e');
      throw ServerException('Failed to watch edited images: An unexpected error occurred');
    }
  }

  void _ensureUserAuthenticated() {
    if (_firebaseAuth.currentUser == null) {
      throw const AuthException('User must be authenticated to access Firestore');
    }
  }
}
```

## 🗄️ Firebase Storage Implementation

### Storage Configuration

#### Storage Security Rules
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User uploaded images
    match /user_images/{userId}/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     request.resource.size < 10 * 1024 * 1024 && // 10MB limit
                     request.resource.contentType.matches('image/.*');
    }
    
    // AI generated images
    match /generated_images/{userId}/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     request.resource.size < 20 * 1024 * 1024; // 20MB limit for generated images
    }
    
    // Mask images (for AI processing)
    match /masks/{userId}/{maskId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     request.resource.size < 5 * 1024 * 1024 && // 5MB limit
                     request.resource.contentType.matches('image/.*');
    }
    
    // Temporary processing files
    match /temp/{userId}/{fileId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId &&
                           request.resource.size < 50 * 1024 * 1024; // 50MB limit
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Storage Data Source Implementation
```dart
// lib/features/image_editor/data/datasources/remote/firebase_storage_data_source.dart
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../core/error/exceptions.dart';

abstract class FirebaseStorageDataSource {
  Future<String> uploadUserImage(Uint8List imageBytes, String fileName);
  Future<String> uploadMaskImage(Uint8List maskBytes, String fileName);
  Future<String> uploadGeneratedImage(Uint8List imageBytes, String fileName);
  Future<Uint8List> downloadImage(String path);
  Future<String> getDownloadUrl(String path);
  Future<void> deleteImage(String path);
  Future<List<String>> listUserImages();
  Future<UploadTask> uploadImageWithProgress(Uint8List imageBytes, String path);
}

class FirebaseStorageDataSourceImpl implements FirebaseStorageDataSource {
  FirebaseStorageDataSourceImpl({
    required FirebaseStorage firebaseStorage,
    required FirebaseAuth firebaseAuth,
  }) : _firebaseStorage = firebaseStorage,
       _firebaseAuth = firebaseAuth;

  final FirebaseStorage _firebaseStorage;
  final FirebaseAuth _firebaseAuth;

  static const String _userImagesPath = 'user_images';
  static const String _masksPath = 'masks';
  static const String _generatedImagesPath = 'generated_images';
  static const String _tempPath = 'temp';

  @override
  Future<String> uploadUserImage(Uint8List imageBytes, String fileName) async {
    return _uploadImage(imageBytes, fileName, _userImagesPath, 'image/jpeg');
  }

  @override
  Future<String> uploadMaskImage(Uint8List maskBytes, String fileName) async {
    return _uploadImage(maskBytes, fileName, _masksPath, 'image/png');
  }

  @override
  Future<String> uploadGeneratedImage(Uint8List imageBytes, String fileName) async {
    return _uploadImage(imageBytes, fileName, _generatedImagesPath, 'image/jpeg');
  }

  Future<String> _uploadImage(
    Uint8List imageBytes,
    String fileName,
    String basePath,
    String contentType,
  ) async {
    try {
      final userId = _getCurrentUserId();
      final path = '$basePath/$userId/$fileName';
      
      log('📤 Uploading image to: $path');
      
      final ref = _firebaseStorage.ref().child(path);
      
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(imageBytes, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        log('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final taskSnapshot = await uploadTask;
      
      if (taskSnapshot.state != TaskState.success) {
        throw StorageException('Upload failed with state: ${taskSnapshot.state}');
      }

      log('✅ Image uploaded successfully to: $path');
      return path;
    } on FirebaseException catch (e) {
      log('❌ Firebase Storage error uploading image: ${e.code} - ${e.message}');
      throw StorageException('Failed to upload image: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error uploading image: $e');
      throw StorageException('Failed to upload image: An unexpected error occurred');
    }
  }

  @override
  Future<Uint8List> downloadImage(String path) async {
    try {
      log('📥 Downloading image from: $path');
      
      final ref = _firebaseStorage.ref().child(path);
      final imageBytes = await ref.getData();
      
      if (imageBytes == null) {
        throw StorageException('No data found at path: $path');
      }
      
      log('✅ Image downloaded successfully from: $path');
      return imageBytes;
    } on FirebaseException catch (e) {
      log('❌ Firebase Storage error downloading image: ${e.code} - ${e.message}');
      throw StorageException('Failed to download image: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error downloading image: $e');
      throw StorageException('Failed to download image: An unexpected error occurred');
    }
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    try {
      log('🔗 Getting download URL for: $path');
      
      final ref = _firebaseStorage.ref().child(path);
      final downloadUrl = await ref.getDownloadURL();
      
      log('✅ Download URL obtained successfully');
      return downloadUrl;
    } on FirebaseException catch (e) {
      log('❌ Firebase Storage error getting download URL: ${e.code} - ${e.message}');
      throw StorageException('Failed to get download URL: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error getting download URL: $e');
      throw StorageException('Failed to get download URL: An unexpected error occurred');
    }
  }

  @override
  Future<void> deleteImage(String path) async {
    try {
      log('🗑️ Deleting image at: $path');
      
      final ref = _firebaseStorage.ref().child(path);
      await ref.delete();
      
      log('✅ Image deleted successfully');
    } on FirebaseException catch (e) {
      log('❌ Firebase Storage error deleting image: ${e.code} - ${e.message}');
      throw StorageException('Failed to delete image: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error deleting image: $e');
      throw StorageException('Failed to delete image: An unexpected error occurred');
    }
  }

  @override
  Future<List<String>> listUserImages() async {
    try {
      final userId = _getCurrentUserId();
      final path = '$_userImagesPath/$userId';
      
      log('📋 Listing images in: $path');
      
      final ref = _firebaseStorage.ref().child(path);
      final listResult = await ref.listAll();
      
      final imagePaths = listResult.items.map((item) => item.fullPath).toList();
      
      log('✅ Found ${imagePaths.length} images');
      return imagePaths;
    } on FirebaseException catch (e) {
      log('❌ Firebase Storage error listing images: ${e.code} - ${e.message}');
      throw StorageException('Failed to list images: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error listing images: $e');
      throw StorageException('Failed to list images: An unexpected error occurred');
    }
  }

  @override
  Future<UploadTask> uploadImageWithProgress(Uint8List imageBytes, String path) async {
    try {
      final userId = _getCurrentUserId();
      final fullPath = '$_tempPath/$userId/$path';
      
      log('📤 Starting upload with progress tracking to: $fullPath');
      
      final ref = _firebaseStorage.ref().child(fullPath);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      return ref.putData(imageBytes, metadata);
    } on FirebaseException catch (e) {
      log('❌ Firebase Storage error starting upload: ${e.code} - ${e.message}');
      throw StorageException('Failed to start upload: ${e.message}');
    } catch (e) {
      log('❌ Unexpected error starting upload: $e');
      throw StorageException('Failed to start upload: An unexpected error occurred');
    }
  }

  String _getCurrentUserId() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('User must be authenticated to access Firebase Storage');
    }
    return user.uid;
  }
}
```

## ☁️ Cloud Functions Setup

### Functions Project Structure
```bash
functions/
├── package.json
├── tsconfig.json
├── .gitignore
├── src/
│   ├── index.ts
│   ├── auth/
│   │   └── authTriggers.ts
│   ├── ai/
│   │   ├── imageAnalysis.ts
│   │   └── imageGeneration.ts
│   ├── storage/
│   │   └── imageProcessing.ts
│   └── utils/
│       ├── validation.ts
│       └── response.ts
└── .env.example
```

### Initialize Cloud Functions
```bash
# Navigate to project root
cd /path/to/revision

# Initialize Cloud Functions
firebase init functions

# Select TypeScript
# Install dependencies
# Create index file
```

### Package.json Configuration
```json
{
  "name": "functions",
  "scripts": {
    "lint": "eslint --ext .js,.ts .",
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "lib/index.js",
  "dependencies": {
    "@google-cloud/firestore": "^7.1.0",
    "@google-cloud/storage": "^7.7.0",
    "@google-cloud/vertexai": "^1.4.0",
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.8.1",
    "sharp": "^0.33.2",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^5.12.0",
    "@typescript-eslint/parser": "^5.12.0",
    "eslint": "^8.9.0",
    "eslint-config-google": "^0.14.0",
    "eslint-plugin-import": "^2.25.4",
    "firebase-functions-test": "^3.1.0",
    "typescript": "^4.9.0"
  },
  "private": true
}
```

### Cloud Functions Implementation
```typescript
// functions/src/index.ts
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onObjectFinalized } from 'firebase-functions/v2/storage';

// Initialize Firebase Admin
admin.initializeApp();

// Import function modules
import { analyzeImageWithAI, generateImageWithAI } from './ai/imageProcessing';
import { optimizeUploadedImage } from './storage/imageProcessing';
import { onUserCreated, onUserDeleted } from './auth/authTriggers';

// AI Image Analysis Function
export const analyzeImage = onCall(
  {
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 300,
    enforceAppCheck: true,
  },
  analyzeImageWithAI
);

// AI Image Generation Function
export const generateImage = onCall(
  {
    region: 'us-central1',
    memory: '2GiB',
    timeoutSeconds: 600,
    enforceAppCheck: true,
  },
  generateImageWithAI
);

// Image Optimization Trigger
export const optimizeImage = onObjectFinalized(
  {
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 120,
    bucket: 'your-project-id.appspot.com',
  },
  optimizeUploadedImage
);

// User Management Triggers
export const createUserProfile = onDocumentCreated(
  'users/{userId}',
  onUserCreated
);

export const cleanupUserData = onDocumentCreated(
  'deletedUsers/{userId}',
  onUserDeleted
);

// Health Check Function
export const healthCheck = onCall(
  { region: 'us-central1' },
  async (request) => {
    try {
      // Verify Firebase Admin is working
      await admin.firestore().collection('_health').limit(1).get();
      
      return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
      };
    } catch (error) {
      throw new HttpsError('internal', 'Health check failed');
    }
  }
);
```

## 📊 Firebase Analytics Implementation

### Analytics Configuration
```dart
// lib/core/analytics/firebase_analytics_service.dart
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../config/environment.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();
  
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._();
  static FirebaseAnalyticsService get instance => _instance;

  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver _observer;

  FirebaseAnalyticsObserver get observer => _observer;

  void initialize() {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
    
    // Configure analytics
    _configureAnalytics();
  }

  Future<void> _configureAnalytics() async {
    try {
      // Set analytics collection enabled (disable in debug mode)
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      
      // Set user properties
      await _analytics.setUserProperty(
        name: 'environment',
        value: EnvConfig.environment.name,
      );
      
      // Set session timeout
      await _analytics.setSessionTimeoutDuration(const Duration(minutes: 30));
      
      log('📊 Firebase Analytics configured successfully');
    } catch (e) {
      log('❌ Failed to configure Firebase Analytics: $e');
    }
  }

  // User Events
  Future<void> logSignIn(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      log('📊 Logged sign in event: $method');
    } catch (e) {
      log('❌ Failed to log sign in event: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      log('📊 Logged sign up event: $method');
    } catch (e) {
      log('❌ Failed to log sign up event: $e');
    }
  }

  Future<void> logImageUpload() async {
    try {
      await _analytics.logEvent(
        name: 'image_upload',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      log('📊 Logged image upload event');
    } catch (e) {
      log('❌ Failed to log image upload event: $e');
    }
  }

  Future<void> logAIProcessing({
    required String processingType,
    required Duration processingTime,
    required bool success,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_processing',
        parameters: {
          'processing_type': processingType,
          'processing_time_ms': processingTime.inMilliseconds,
          'success': success,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      log('📊 Logged AI processing event: $processingType');
    } catch (e) {
      log('❌ Failed to log AI processing event: $e');
    }
  }

  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? additionalContext,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          'additional_context': additionalContext ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      log('📊 Logged error event: $errorType');
    } catch (e) {
      log('❌ Failed to log error event: $e');
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      log('📊 Set user ID: $userId');
    } catch (e) {
      log('❌ Failed to set user ID: $e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      log('📊 Set user property: $name = $value');
    } catch (e) {
      log('❌ Failed to set user property: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      log('📊 Logged screen view: $screenName');
    } catch (e) {
      log('❌ Failed to log screen view: $e');
    }
  }
}
```

## 🔧 Firebase Emulator Setup for Development

### Emulator Configuration
```json
{
  "emulators": {
    "auth": {
      "port": 9099,
      "host": "127.0.0.1"
    },
    "firestore": {
      "port": 8080,
      "host": "127.0.0.1"
    },
    "storage": {
      "port": 9199,
      "host": "127.0.0.1"
    },
    "functions": {
      "port": 5001,
      "host": "127.0.0.1"
    },
    "ui": {
      "enabled": true,
      "port": 4000,
      "host": "127.0.0.1"
    },
    "singleProjectMode": true,
    "dataDir": "./.firebase/emulator-data"
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

### Emulator Scripts
```bash
# scripts/emulator.sh
#!/bin/bash

echo "🔥 Starting Firebase Emulators..."

# Export data on exit and import existing data
firebase emulators:start \
  --import=./.firebase/emulator-data \
  --export-on-exit=./.firebase/emulator-data

echo "✅ Firebase Emulators stopped"
```

This comprehensive Firebase integration guide provides production-ready implementation for all Firebase services used in the Aura application. Each service is properly configured with security rules, error handling, and monitoring capabilities.
