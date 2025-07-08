#!/usr/bin/env dart

import 'dart:convert'; // For jsonEncode
import 'dart:io';

import 'package:path/path.dart' as path;

/// Quick setup script to create Firebase emulator test users
///
/// Usage: dart run_setup_test_users.dart
// Configuration
const String firebaseProjectId =
    'revision-fc66c'; // Read from firebase_options.dart

Future<void> main() async {
  print('🔥 Firebase Emulator Test User Setup');
  print('=====================================');

  // Check if we're in the right directory
  final currentDir = Directory.current;
  final firebaseJsonPath = path.join(currentDir.path, 'firebase.json');

  if (!File(firebaseJsonPath).existsSync()) {
    print('❌ firebase.json not found. Please run this from the project root.');
    exit(1);
  }
  try {
    // Check if Firebase CLI is available
    final firebaseCliAvailable = await _checkFirebaseCLI();
    if (!firebaseCliAvailable) {
      print(
        '⚠️  Firebase CLI not found. Please ensure emulators are running manually.',
      );
      print('   Run: firebase emulators:start --only=auth,ui');
      print('   Or install Firebase CLI: npm install -g firebase-tools\n');
    } else {
      // Start emulators
      print('🚀 Starting Firebase emulators...');
      await Process.start('firebase', [
        'emulators:start',
        '--only=auth,ui',
      ], mode: ProcessStartMode.detached);
      // Wait for emulators to start
      await Future<void>.delayed(const Duration(seconds: 8));
    }

    // Check if emulator is running
    print('🔍 Checking emulator health...');
    final isHealthy = await _checkEmulatorHealth();
    if (!isHealthy) {
      print(
        '❌ Emulator is not responding. Please check if it started correctly.',
      );
      print('   Make sure to run: firebase emulators:start --only=auth,ui');
      exit(1);
    }
    print('✅ Emulator is healthy!');

    // Create test users via HTTP API
    await _createTestUsersViaAPI();

    print('\n✅ Setup complete! You can now use these credentials:');
    print('   📧 test@example.com / password123');
    print('   📧 admin@test.com / admin123');
    print('   📧 user@demo.com / demo123');
    print('   📧 john@example.com / john123');
    print('   📧 jane@example.com / jane123');
    print('\n🌐 Firebase Emulator UI: http://localhost:4001');
    print('🔐 Auth Emulator: http://localhost:9098');

    print('\n💡 Tip: Keep emulators running and test your login in the app!');
  } catch (e) {
    print('❌ Setup failed: $e');
    print(
      '💡 Make sure Firebase CLI is installed: npm install -g firebase-tools',
    );
    exit(1);
  }
}

Future<void> _createTestUsersViaAPI() async {
  final testUsers = [
    {
      'email': 'test@example.com',
      'password': 'password123',
      'displayName': 'Test User',
    },
    {
      'email': 'admin@test.com',
      'password': 'admin123',
      'displayName': 'Admin User',
    },
    {
      'email': 'user@demo.com',
      'password': 'demo123',
      'displayName': 'Demo User',
    },
    {
      'email': 'john@example.com',
      'password': 'john123',
      'displayName': 'John Doe',
    },
    {
      'email': 'jane@example.com',
      'password': 'jane123',
      'displayName': 'Jane Smith',
    },
  ];
  final client = HttpClient();
  const baseUrl =
      'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key';
  for (final user in testUsers) {
    try {
      final request = await client.postUrl(Uri.parse(baseUrl));
      request.headers.contentType = ContentType.json;
      final userData = {
        'email': user['email'],
        'password': user['password'],
        'displayName': user['displayName'],
        'returnSecureToken': true,
      };
      request.write(jsonEncode(userData)); // Use jsonEncode

      final response = await request.close();
      // final responseBody = await response.transform(utf8.decoder).join(); // Optional: log response body

      if (response.statusCode == 200) {
        print('✅ Created user: ${user['email']}');
      } else if (response.statusCode == 400) {
        // Often indicates user already exists
        print(
          '⚠️  User ${user['email']} might already exist (Status: ${response.statusCode})',
        );
      } else {
        print(
          '⚠️  Failed to create user ${user['email']}. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('⚠️  Exception while creating ${user['email']}: $e');
    }
  }
}

/// Check if the Firebase Auth emulator is running and healthy
Future<bool> _checkEmulatorHealth() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:9099/'));
    request.headers.add('Accept', 'application/json');
    final response = await request.close();
    client.close();
    // Any response indicates the emulator is running
    return response.statusCode >= 200 && response.statusCode < 500;
  } catch (e) {
    return false;
  }
}

/// Check if Firebase CLI is available
Future<bool> _checkFirebaseCLI() async {
  try {
    final result = await Process.run('firebase', ['--version']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}
