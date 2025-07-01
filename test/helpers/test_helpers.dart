import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessenger.instance.setMockMethodCallHandler(
      MethodChannelFirebase.channel, (call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {},
        }
      ];
    }

    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }

    if (customHandlers != null) {
      customHandlers(call);
    }

    return null;
  });
}

class VGVTestHelper {
  static Future<void> setupTestDependencies() async {
    setupFirebaseMocks();
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
