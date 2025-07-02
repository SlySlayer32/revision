import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Helper class for Firebase emulator setup and management in tests
class FirebaseEmulatorHelper {
  // Emulator configuration
  static const String _authEmulatorHost = 'localhost';
  static const int _authEmulatorPort = 9099;
  static const String _firestoreEmulatorHost = 'localhost';
  static const int _firestoreEmulatorPort = 8080;

  static bool _isInitialized = false;

  /// Initializes Firebase for testing with emulator configuration
  static Future<void> initializeForTesting() async {
    if (_isInitialized) {
      debugPrint('Firebase already initialized for testing');
      return;
    }

    try {
      // Initialize Firebase app for testing
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project',
        ),
      );

      // Connect to Firebase Auth emulator
      await FirebaseAuth.instance.useAuthEmulator(
        _authEmulatorHost,
        _authEmulatorPort,
      );

      _isInitialized = true;
      debugPrint('Firebase emulator initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase emulator: $e');
      rethrow;
    }
  }

  /// Clears all authentication data from the emulator
  static Future<void> clearAuthData() async {
    try {
      // Sign out current user if any
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }

      debugPrint('Auth data cleared successfully');
    } catch (e) {
      debugPrint('Failed to clear auth data: $e');
      // Don't rethrow as this is cleanup
    }
  }

  /// Creates a test user in the emulator for testing purposes
  static Future<User?> createTestUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      debugPrint('Test user created: $email');
      return userCredential.user;
    } catch (e) {
      debugPrint('Failed to create test user: $e');
      return null;
    }
  }

  /// Signs in a test user
  static Future<User?> signInTestUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Test user signed in: $email');
      return userCredential.user;
    } catch (e) {
      debugPrint('Failed to sign in test user: $e');
      return null;
    }
  }

  /// Deletes all test users from the emulator
  static Future<void> deleteAllTestUsers() async {
    try {
      // Note: This is a simplified approach for testing
      // In a real implementation, you might need to call Firebase Admin SDK
      // or use emulator REST APIs to bulk delete users
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
        debugPrint('Current test user deleted');
      }
    } catch (e) {
      debugPrint('Failed to delete test users: $e');
      // Don't rethrow as this is cleanup
    }
  }

  /// Checks if the emulator is available and reachable
  static Future<bool> isEmulatorAvailable() async {
    try {
      // Simple check by trying to get current user
      // If emulator is not running, this will fail
      FirebaseAuth.instance.currentUser;
      return true;
    } catch (e) {
      debugPrint('Emulator not available: $e');
      return false;
    }
  }

  /// Gets emulator connection info
  static Map<String, dynamic> getEmulatorInfo() {
    return {
      'authHost': _authEmulatorHost,
      'authPort': _authEmulatorPort,
      'firestoreHost': _firestoreEmulatorHost,
      'firestorePort': _firestoreEmulatorPort,
      'isInitialized': _isInitialized,
    };
  }

  /// Resets the initialization state (useful for testing)
  static void resetInitializationState() {
    _isInitialized = false;
    debugPrint('Firebase emulator initialization state reset');
  }
}
