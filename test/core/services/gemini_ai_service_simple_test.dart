import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

// Simple mock for testing
class MockFirebaseAIRemoteConfigService extends Mock implements FirebaseAIRemoteConfigService {}

void main() {
  group('GeminiAIService', () {
    late MockFirebaseAIRemoteConfigService mockRemoteConfigService;

    setUp(() {
      mockRemoteConfigService = MockFirebaseAIRemoteConfigService();
      
      // Setup basic mock behaviors
      when(() => mockRemoteConfigService.initialize())
          .thenAnswer((_) async => {});
      when(() => mockRemoteConfigService.geminiModel)
          .thenReturn('gemini-1.5-flash');
      when(() => mockRemoteConfigService.geminiImageModel)
          .thenReturn('gemini-1.5-flash');
      when(() => mockRemoteConfigService.temperature)
          .thenReturn(0.7);
      when(() => mockRemoteConfigService.maxOutputTokens)
          .thenReturn(1000);
      when(() => mockRemoteConfigService.analysisSystemPrompt)
          .thenReturn('Test analysis prompt');
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
  });
}
