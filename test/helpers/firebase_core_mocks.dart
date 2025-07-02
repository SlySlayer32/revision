import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final apps = <String>[];

  const MethodChannel('plugins.flutter.io/firebase_core')
      .setMockMethodCallHandler((call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
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
      final appName = call.arguments['appName'] as String;
      if (apps.contains(appName)) {
        return {
          'name': appName,
          'options': call.arguments['options'],
          'pluginConstants': {},
        };
      }
      apps.add(appName);
      return {
        'name': appName,
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    return null;
  });
}
