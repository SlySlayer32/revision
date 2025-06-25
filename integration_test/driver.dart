import 'package:flutter/widgets.dart'; // Required for WidgetsFlutterBinding
import 'package:integration_test/integration_test_driver.dart';

import '../test/helpers/firebase_emulator_helper.dart'; // Import the helper

Future<void> main() async {
  // Ensure Flutter bindings are initialized before any Flutter services are used.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for testing, using the emulator.
  // This should ideally use a shared configuration or the helper if appropriate.
  print('Driver: Initializing Firebase for integration tests...');
  try {
    // Use the existing helper to initialize Firebase and connect to emulators
    await FirebaseEmulatorHelper.initializeForTesting();
    print('Driver: Firebase initialized successfully with emulator settings.');
  } catch (e) {
    print('Driver: Firebase initialization failed: $e');
    print(
        'Driver: Ensure Firebase emulators are running (firebase emulators:start --only auth).');
    // Optionally, rethrow or exit if Firebase initialization is critical for all tests.
    // For now, we'll let individual tests handle failures if they depend on Firebase.
  }

  // Proceed with the standard integration test driver setup.
  await integrationDriver();
}
