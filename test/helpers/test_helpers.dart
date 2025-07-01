import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:flutter/services.dart';

// This is the key to mocking Firebase initialization.
// We set up a mock handler for the 'plugins.flutter.io/firebase_core' channel.
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The following code is from the firebase_core documentation for testing.
  // It mocks the native platform calls that Firebase.initializeApp() makes.
  final binaryMessenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
  binaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': defaultFirebaseAppName,
            'options': {
              'apiKey': 'mock_api_key',
              'appId': 'mock_app_id',
              'messagingSenderId': 'mock_sender_id',
              'projectId': 'mock_project_id',
            },
            'pluginConstants': {},
          }
        ];
      }
      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': methodCall.arguments['appName'],
          'options': methodCall.arguments['options'],
          'pluginConstants': {},
        };
      }
      return null;
    },
  );
}

class VGVTestHelper {
  static Future<void> setupTestDependencies() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    // Reset the service locator to ensure a clean state for each test
    getIt.reset();
    // Setup the service locator with test dependencies
    setupServiceLocator();
  }

  static Future<void> tearDownTestDependencies() async {
    // Reset the service locator after each test
    getIt.reset();
  }

  static Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: widget,
      ),
    );
    await tester.pumpAndSettle();
  }
}
