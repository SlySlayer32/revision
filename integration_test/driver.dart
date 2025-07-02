import 'dart:developer' as dev;

import 'package:flutter/widgets.dart'; // Required for WidgetsFlutterBinding
import 'package:integration_test/integration_test_driver.dart';

import '../test/helpers/firebase_emulator_helper.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before any Flutter services are used.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for testing, using the emulator.
  // This should ideally use a shared configuration or the helper if appropriate.
  dev.log('Driver: Initializing Firebase for integration tests...');
  try {
    // TODO: Implement Firebase emulator initialization
    // await FirebaseEmulatorHelper.initializeForTesting();
    dev.log(
        'Driver: Firebase initialization skipped - helper not implemented.');
  } catch (e) {
    dev.log('Driver: Firebase initialization failed: $e');
    dev.log(
        'Driver: Ensure Firebase emulators are running (firebase emulators:start --only auth).');
    // Optionally, rethrow or exit if Firebase initialization is critical for all tests.
    // For now, we'll let individual tests handle failures if they depend on Firebase.
  }

  // Proceed with the standard integration test driver setup.
  await integrationDriver();
}
