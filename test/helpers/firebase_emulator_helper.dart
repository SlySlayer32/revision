import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/firebase_options.dart';

/// Enhanced Firebase emulator helper for integration testing
class FirebaseEmulatorHelper {
  static const String _authEmulatorHost = 'localhost';
  static const int _authEmulatorPort = 9099;
  static const String _projectId = 'revision-fc66c';

  static bool _isInitialized = false;
  static bool _emulatorsStarted = false;

  /// Initialize Firebase with emulator configuration for integration tests
  static Future<void> initializeForTesting() async {
    if (_isInitialized) return;

    // Ensure binding is initialized for tests
    TestWidgetsFlutterBinding.ensureInitialized();

    // Platform-specific host logic for emulator (match app logic)
    var emulatorHost = _authEmulatorHost;
    if (Platform.isAndroid) {
      emulatorHost = '10.0.2.2';
    } else if (Platform.isIOS) {
      emulatorHost = 'localhost';
    } else {
      emulatorHost = '127.0.0.1';
    }

    try {
      // Check if Firebase is already initialized to prevent duplicate app error
      try {
        Firebase.app(); // Try to get existing default app
        print('✅ Firebase already initialized, reusing existing app');
      } catch (e) {
        // App doesn't exist, initialize it
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform.copyWith(
            projectId: _projectId,
          ),
        );
        print('✅ Firebase initialized successfully for testing');
      }

      // Configure Auth emulator - must be called before any auth operations
      try {
        await FirebaseAuth.instance.useAuthEmulator(
          emulatorHost,
          _authEmulatorPort,
        );
        print(
          '✅ Firebase Auth emulator connected on '
          '[33m$emulatorHost:$_authEmulatorPort[0m',
        );
      } catch (e) {
        print('⚠️ Could not connect to auth emulator on $emulatorHost: $e');
        rethrow; // Rethrow to fail test if emulator connection fails
      }

      // Disable app verification for testing
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );

      _isInitialized = true;
      print('✅ Firebase initialized for integration testing');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Start Firebase emulators if not already running
  static Future<void> startEmulators() async {
    if (_emulatorsStarted) return;

    try {
      // Check if emulators are already running
      final healthCheck = await _checkEmulatorHealth();
      if (healthCheck) {
        // print('🔥 Firebase emulators already running');
        _emulatorsStarted = true;
        return;
      }

      // print('🚀 Starting Firebase emulators...');

      // Start emulators in detached mode
      await Process.start(
        'firebase',
        ['emulators:start', '--only=auth', '--project=$_projectId'],
        mode: ProcessStartMode.detached,
      );

      // Wait for emulators to be ready
      await _waitForEmulators();

      _emulatorsStarted = true;
      // print('✅ Firebase emulators started successfully');
    } catch (e) {
      // print('❌ Failed to start Firebase emulators: $e');
      // print('💡 Make sure Firebase CLI is installed and configured');
      rethrow;
    }
  }

  /// Stop Firebase emulators
  static Future<void> stopEmulators() async {
    if (!_emulatorsStarted) return;

    try {
      await Process.run('firebase', ['emulators:stop']);
      _emulatorsStarted = false;
      // print('🛑 Firebase emulators stopped');
    } catch (e) {
      // print('⚠️ Failed to stop emulators gracefully: $e');
    }
  }

  /// Clear all emulator data
  static Future<void> clearEmulatorData() async {
    if (!_emulatorsStarted) return;

    try {
      // Clear Auth emulator data
      final response = await Process.run('curl', [
        '-X',
        'DELETE',
        'http://$_authEmulatorHost:$_authEmulatorPort',
        '/emulator/v1/projects/$_projectId/accounts',
      ]);

      if (response.exitCode == 0) {
        // print('🧹 Emulator data cleared successfully');
      } else {
        // print('⚠️ Failed to clear emulator data: ${response.stderr}');
      }
    } catch (e) {
      // print('⚠️ Error clearing emulator data: $e');
    }
  }

  /// Create test users in the emulator
  static Future<void> seedTestUsers() async {
    if (!_isInitialized) {
      throw StateError(
        'Firebase not initialized. Call initializeForTesting() first.',
      );
    }

    try {
      final auth = FirebaseAuth.instance;

      // Create standard test users
      final testUsers = [
        {
          'email': 'test@example.com',
          'password': 'password123',
          'name': 'Test User',
        },
        {
          'email': 'admin@test.com',
          'password': 'admin123',
          'name': 'Admin User',
        },
        {'email': 'user@demo.com', 'password': 'demo123', 'name': 'Demo User'},
        {
          'email': 'john@example.com',
          'password': 'john123',
          'name': 'John Doe',
        },
        {
          'email': 'jane@example.com',
          'password': 'jane123',
          'name': 'Jane Smith',
        },
      ];

      for (final userData in testUsers) {
        try {
          final userCredential = await auth.createUserWithEmailAndPassword(
            email: userData['email']!,
            password: userData['password']!,
          );

          // Update display name
          await userCredential.user?.updateDisplayName(userData['name']);

          log('✅ Created user: ${userData['email']}');
        } catch (e) {
          log('⚠️  User ${userData['email']} might already exist: $e');
        }
      }

      // Sign out after creating users
      await auth.signOut();

      log('👥 Test users seeded successfully');
    } catch (e) {
      log('⚠️ Failed to seed test users: $e');
    }
  }

  /// Create a single test user
  static Future<User?> createTestUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_isInitialized) {
      throw StateError(
        'Firebase not initialized. Call initializeForTesting() first.',
      );
    }

    try {
      final auth = FirebaseAuth.instance;

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      log('✅ Created test user: $email');
      return userCredential.user;
    } catch (e) {
      log('⚠️ Failed to create user $email: $e');
      return null;
    }
  }

  /// Sign in with test credentials
  static Future<User?> signInTestUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) {
      throw StateError(
        'Firebase not initialized. Call initializeForTesting() first.',
      );
    }

    try {
      final auth = FirebaseAuth.instance;

      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      log('✅ Signed in test user: $email');
      return userCredential.user;
    } catch (e) {
      log('❌ Failed to sign in $email: $e');
      return null;
    }
  }

  /// Get list of common test credentials
  static List<Map<String, String>> getTestCredentials() {
    return [
      {'email': 'test@example.com', 'password': 'password123'},
      {'email': 'admin@test.com', 'password': 'admin123'},
      {'email': 'user@demo.com', 'password': 'demo123'},
      {'email': 'john@example.com', 'password': 'john123'},
      {'email': 'jane@example.com', 'password': 'jane123'},
    ];
  }

  /// Setup complete testing environment
  static Future<void> setupTestEnvironment() async {
    await startEmulators();
    await initializeForTesting();
    await clearEmulatorData();
    await seedTestUsers();
    // print('🎯 Firebase testing environment ready');
  }

  /// Cleanup testing environment
  static Future<void> teardownTestEnvironment() async {
    await clearEmulatorData();
    // print('🧹 Firebase testing environment cleaned up');
  }

  /// Check if Auth emulator is running and healthy
  static Future<bool> _checkEmulatorHealth() async {
    try {
      final result = await Process.run('curl', [
        '-s',
        'http://$_authEmulatorHost:$_authEmulatorPort',
        '/emulator/v1/projects/$_projectId/config',
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Wait for emulators to be ready
  static Future<void> _waitForEmulators() async {
    const maxAttempts = 30;
    const delay = Duration(seconds: 1);

    for (var i = 0; i < maxAttempts; i++) {
      if (await _checkEmulatorHealth()) {
        return;
      }
      await Future<void>.delayed(delay);
      // print('⏳ Waiting for emulators to start... (${i + 1}/$maxAttempts)');
    }

    throw const TimeoutException(
      'Firebase emulators failed to start within timeout',
    );
  }

  /// Get emulator connection info
  static Map<String, dynamic> getEmulatorInfo() {
    return {
      'authHost': _authEmulatorHost,
      'authPort': _authEmulatorPort,
      'projectId': _projectId,
      'isRunning': _emulatorsStarted,
      'isInitialized': _isInitialized,
    };
  }

  /// Clear all authentication data from emulator
  static Future<void> clearAuthData() async {
    try {
      await FirebaseAuth.instance.signOut();
      // In a real emulator environment, you might also call:
      // await _clearAllUsersFromEmulator();
      print('✅ Auth data cleared');
    } catch (e) {
      print('⚠️ Failed to clear auth data: $e');
    }
  }
}

/// Exception thrown when emulator operations timeout
class TimeoutException implements Exception {
  const TimeoutException(this.message);
  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
