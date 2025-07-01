import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:firebase_core/firebase_core.dart';
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

// Simple mock for testing - Firebase AI classes are final and can't be mocked directly
class MockFirebaseAIRemoteConfigService extends Mock
    implements FirebaseAIRemoteConfigService {}

void main() {
  group('GeminiAIService', () {
    late MockFirebaseAIRemoteConfigService mockRemoteConfigService;

    setUp(() async {
      setupFirebaseCoreMocks();
      await Firebase.initializeApp();
      mockRemoteConfigService = MockFirebaseAIRemoteConfigService();

      // Setup basic mock behaviors
      when(() => mockRemoteConfigService.initialize())
          .thenAnswer((_) async => {});
      when(() => mockRemoteConfigService.geminiModel)
          .thenReturn('gemini-1.5-flash');
      when(() => mockRemoteConfigService.geminiImageModel)
          .thenReturn('gemini-1.5-flash');
      when(() => mockRemoteConfigService.temperature).thenReturn(0.7);
      when(() => mockRemoteConfigService.maxOutputTokens).thenReturn(1000);
      when(() => mockRemoteConfigService.analysisSystemPrompt)
          .thenReturn('Test analysis prompt');
      when(() => mockRemoteConfigService.requestTimeout)
          .thenReturn(const Duration(seconds: 30));
      when(() => mockRemoteConfigService.debugMode).thenReturn(false);
      when(() => mockRemoteConfigService.enableAdvancedFeatures)
          .thenReturn(true);
    });

    test('should create service instance', () {
      // Arrange & Act
      final service = GeminiAIService(
        remoteConfigService: mockRemoteConfigService,
      );

      // Assert
      expect(service, isNotNull);
    });

    test('should initialize remote config service', () async {
      // Arrange
      final service = GeminiAIService(
        remoteConfigService: mockRemoteConfigService,
      );

      // Act
      await service.waitForInitialization();

      // Assert
      verify(() => mockRemoteConfigService.initialize()).called(1);
    });

    test('should expose debug mode setting', () async {
      // Arrange
      final service = GeminiAIService(
        remoteConfigService: mockRemoteConfigService,
      );

      // Act
      await service.waitForInitialization();

      // Assert
      expect(service.isDebugMode, false);
    });

    test('should expose advanced features setting', () async {
      // Arrange
      final service = GeminiAIService(
        remoteConfigService: mockRemoteConfigService,
      );

      // Act
      await service.waitForInitialization();

      // Assert
      expect(service.isAdvancedFeaturesEnabled, true);
    });
  });
}
