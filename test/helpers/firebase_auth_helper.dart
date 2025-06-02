import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/firebase_options.dart';

/// Optimized Firebase mock helper for UNIT TESTS ONLY
///
/// For integration tests, use FirebaseEmulatorHelper instead
/// This provides method channel mocking for isolated unit tests
Future<void> setupFirebaseAuthMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mock the method channel for firebase_core
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_core'),
          (MethodCall methodCall) async {
    if (methodCall.method == 'Firebase#initializeCore') {
      return <Map<String, dynamic>>[
        <String, dynamic>{
          'name': defaultFirebaseAppName,
          'options': <String, dynamic>{
            'apiKey': 'mock_api_key',
            'appId': 'mock_app_id',
            'messagingSenderId': 'mock_sender_id',
            'projectId': 'mock_project_id',
          },
          'pluginConstants': <String, dynamic>{},
        }
      ];
    }
    if (methodCall.method == 'Firebase#initializeApp') {
      return <String, dynamic>{
        'name': methodCall.arguments['appName'],
        'options': methodCall.arguments['options'],
        'pluginConstants': <String, dynamic>{},
      };
    }
    return <String, dynamic>{};
  }); // Mock the method channel for firebase_auth
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_auth'),
          (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Auth#signInWithEmailAndPassword':
        return <String, dynamic>{
          'user': <String, dynamic>{
            'uid': 'test-uid',
            'email': 'test@example.com',
            'isEmailVerified': false,
            'metadata': <String, dynamic>{
              'creationTime': DateTime.now().millisecondsSinceEpoch,
              'lastSignInTime': DateTime.now().millisecondsSinceEpoch,
            },
          },
        };
      case 'Auth#signOut':
        return <String, dynamic>{};
      case 'Auth#authStateChanges':
        return <String, dynamic>{};
      default:
        return <String, dynamic>{};
    }
  });

  // Initialize Firebase (this will now use the mocked handlers)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
