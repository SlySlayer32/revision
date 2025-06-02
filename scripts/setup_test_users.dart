#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as path;

/// Quick setup script to create Firebase emulator test users
///
/// Usage: dart run_setup_test_users.dart
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
    // Start emulators
    print('🚀 Starting Firebase emulators...');
    final emulatorProcess = await Process.start(
      'firebase',
      ['emulators:start', '--only=auth'],
      mode: ProcessStartMode.detached,
    );

    // Wait for emulators to start
    await Future.delayed(const Duration(seconds: 5));

    // Create test users via HTTP API
    await _createTestUsersViaAPI();

    print('\n✅ Setup complete! You can now use these credentials:');
    print('   📧 test@example.com / password123');
    print('   📧 admin@test.com / admin123');
    print('   📧 user@demo.com / demo123');
    print('   📧 john@example.com / john123');
    print('   📧 jane@example.com / jane123');

    print('\n🌐 Firebase Emulator UI: http://localhost:4000');
    print('🔐 Auth Emulator: http://localhost:9099');

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

  for (final user in testUsers) {
    try {
      final result = await Process.run('curl', [
        '-X',
        'POST',
        '-H',
        'Content-Type: application/json',
        '-d',
        '{"email":"${user['email']}","password":"${user['password']}","displayName":"${user['displayName']}","emailVerified":true}',
        'http://localhost:9099/emulator/v1/projects/demo-project/accounts',
      ]);

      if (result.exitCode == 0) {
        print('✅ Created user: ${user['email']}');
      } else {
        print('⚠️  User ${user['email']} might already exist');
      }
    } catch (e) {
      print('⚠️  Failed to create ${user['email']}: $e');
    }
  }
}
