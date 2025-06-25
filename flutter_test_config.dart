// Flutter test configuration file
// This file configures global test behavior and Firebase emulator setup

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'test/helpers/firebase_emulator_helper.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Configure test environment
  await _configureTestEnvironment();

  // Run the actual tests
  await testMain();
}

Future<void> _configureTestEnvironment() async {
  // Set test timeout
  if (Platform.environment['FLUTTER_TEST_TIMEOUT'] == null) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMessageHandler('flutter/test_timeout', (data) async {
      return null;
    });
  }

  // Configure Firebase emulators for integration tests
  await _setupFirebaseEmulators();
}

Future<void> _setupFirebaseEmulators() async {
  try {
    // Check if we're running integration tests
    final isIntegrationTest = Platform.environment['FLUTTER_TEST'] == null ||
        Platform.environment['FLUTTER_TEST']!.contains('integration');

    if (isIntegrationTest) {
      // Only initialize emulators for integration tests
      print('🔧 Configuring Firebase emulators for integration tests...');

      // Check if emulators are already running
      final isEmulatorRunning = await _checkEmulatorHealth();

      if (!isEmulatorRunning) {
        print(
            '⚠️  Firebase emulators not detected - skipping emulator-dependent tests');
        print('💡 To run integration tests, start emulators with:');
        print('   firebase emulators:start --only auth');
      } else {
        print('✅ Firebase emulators detected and ready');
        await FirebaseEmulatorHelper.initializeForTesting();
      }
    }
  } catch (e) {
    print('⚠️  Firebase emulator setup failed: $e');
    print('Continuing with non-emulator tests...');
  }
}

Future<bool> _checkEmulatorHealth() async {
  try {
    final result = await Process.run(
      'curl',
      ['-s', 'http://localhost:9099'],
      runInShell: true,
    ).timeout(const Duration(seconds: 3));

    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}
