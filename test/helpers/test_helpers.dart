import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:revision/core/di/service_locator.dart';
import 'firebase_options_for_testing.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

class VGVTestHelper {
  static Future<void> setupTestDependencies() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock Firebase Core
    final auth = MockFirebaseAuth();
    final googleSignIn = MockGoogleSignIn();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
