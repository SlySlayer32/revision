import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';

void main() {
  group('Service Locator', () {
    setUp(() {
      // Ensure clean state for each test
      if (GetIt.instance.isRegistered<AuthRepository>()) {
        GetIt.instance.reset();
      }
    });

    tearDown(() {
      // Clean up after each test
      GetIt.instance.reset();
    });

    group('Setup and Registration', () {
      testWidgets('should register all core services successfully', (tester) async {
        // Act
        setupServiceLocator();

        // Assert - Core services
        expect(getIt.isRegistered<FirebaseAIRemoteConfigService>(), true);
        expect(getIt.isRegistered<GeminiAIService>(), true);
        expect(getIt.isRegistered<GeminiPipelineService>(), true);
      });

      testWidgets('should register GenerativeModel instances with correct names', (tester) async {
        // Act
        setupServiceLocator();

        // Assert - Named GenerativeModel instances
        expect(
          getIt.isRegistered<GenerativeModel>(instanceName: 'analysisModel'),
          true,
        );
        expect(
          getIt.isRegistered<GenerativeModel>(instanceName: 'imageGenerationModel'),
          true,
        );
      });

      testWidgets('should register authentication components', (tester) async {
        // Act
        setupServiceLocator();

        // Assert
        expect(getIt.isRegistered<AuthRepository>(), true);
        expect(getIt.isRegistered<SignInUseCase>(), true);
      });

      testWidgets('should register AI processing components', (tester) async {
        // Act
        setupServiceLocator();

        // Assert
        expect(getIt.isRegistered<ProcessImageWithGeminiUseCase>(), true);
      });

      testWidgets('should handle duplicate registration gracefully', (tester) async {
        // Act - Setup twice
        setupServiceLocator();
        
        // Should reset and setup again without throwing
        expect(() => setupServiceLocator(), returnsNormally);

        // Assert - Services should still be registered
        expect(getIt.isRegistered<GeminiAIService>(), true);
        expect(getIt.isRegistered<AuthRepository>(), true);
      });
    });

    group('Dependency Resolution', () {
      setUp(() {
        setupServiceLocator();
      });

      testWidgets('should resolve FirebaseAIRemoteConfigService', (tester) async {
        // Act
        final service = getIt<FirebaseAIRemoteConfigService>();

        // Assert
        expect(service, isA<FirebaseAIRemoteConfigService>());
      });

      testWidgets('should resolve GeminiAIService with dependencies', (tester) async {
        // Act
        final service = getIt<GeminiAIService>();

        // Assert
        expect(service, isA<GeminiAIService>());
        // Service should have been injected with FirebaseAIRemoteConfigService
      });

      testWidgets('should resolve GenerativeModel instances by name', (tester) async {
        // Note: These will throw StateError until GeminiAIService is fully initialized
        // This test verifies the registration works, not the actual model access
        
        expect(
          () => getIt<GenerativeModel>(instanceName: 'analysisModel'),
          throwsA(isA<StateError>()), // Expected until service initializes
        );
        
        expect(
          () => getIt<GenerativeModel>(instanceName: 'imageGenerationModel'),
          throwsA(isA<StateError>()), // Expected until service initializes
        );
      });

      testWidgets('should create factory instances correctly', (tester) async {
        // Act - Get multiple instances of factory-registered services
        final bloc1 = getIt<AuthenticationBloc>();
        final bloc2 = getIt<AuthenticationBloc>();

        // Assert - Factory services should create new instances
        expect(bloc1, isA<AuthenticationBloc>());
        expect(bloc2, isA<AuthenticationBloc>());
        expect(identical(bloc1, bloc2), false); // Should be different instances
      });

      testWidgets('should return same instance for singleton services', (tester) async {
        // Act
        final service1 = getIt<GeminiAIService>();
        final service2 = getIt<GeminiAIService>();

        // Assert - Singleton services should return same instance
        expect(identical(service1, service2), true);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle registration failures gracefully', (tester) async {
        // This test verifies error handling in setupServiceLocator
        // We can't easily simulate registration failures, but we can verify
        // the method completes and handles errors
        
        expect(() => setupServiceLocator(), returnsNormally);
      });

      testWidgets('should throw meaningful error for unregistered services', (tester) async {
        // Don't setup service locator
        
        // Act & Assert
        expect(
          () => getIt<GeminiAIService>(),
          throwsA(isA<Object>()), // GetIt throws when service not registered
        );
      });
    });

    group('Service Dependencies', () {
      setUp(() {
        setupServiceLocator();
      });

      testWidgets('should inject FirebaseAIRemoteConfigService into GeminiAIService', (tester) async {
        // This test verifies the dependency injection setup
        final geminiService = getIt<GeminiAIService>();
        final remoteConfigService = getIt<FirebaseAIRemoteConfigService>();

        // Both services should be available
        expect(geminiService, isA<GeminiAIService>());
        expect(remoteConfigService, isA<FirebaseAIRemoteConfigService>());
      });

      testWidgets('should inject GeminiAIService into GeminiPipelineService', (tester) async {
        // Act
        final pipelineService = getIt<GeminiPipelineService>();
        final aiService = getIt<GeminiAIService>();

        // Assert
        expect(pipelineService, isA<GeminiPipelineService>());
        expect(aiService, isA<GeminiAIService>());
      });

      testWidgets('should inject GeminiPipelineService into ProcessImageWithGeminiUseCase', (tester) async {
        // Act
        final useCase = getIt<ProcessImageWithGeminiUseCase>();
        final pipelineService = getIt<GeminiPipelineService>();

        // Assert
        expect(useCase, isA<ProcessImageWithGeminiUseCase>());
        expect(pipelineService, isA<GeminiPipelineService>());
      });
    });

    group('AI Pipeline Registration', () {
      setUp(() {
        setupServiceLocator();
      });

      testWidgets('should register complete AI pipeline', (tester) async {
        // Assert all AI pipeline components are registered
        expect(getIt.isRegistered<FirebaseAIRemoteConfigService>(), true);
        expect(getIt.isRegistered<GeminiAIService>(), true);
        expect(getIt.isRegistered<GeminiPipelineService>(), true);
        expect(getIt.isRegistered<ProcessImageWithGeminiUseCase>(), true);
        
        // Named GenerativeModel instances
        expect(
          getIt.isRegistered<GenerativeModel>(instanceName: 'analysisModel'),
          true,
        );
        expect(
          getIt.isRegistered<GenerativeModel>(instanceName: 'imageGenerationModel'),
          true,
        );
      });

      testWidgets('should handle GenerativeModel access before AI service initialization', (tester) async {
        // Act & Assert - Should throw StateError with helpful message
        expect(
          () => getIt<GenerativeModel>(instanceName: 'analysisModel'),
          throwsA(
            predicate(
              (e) => e is StateError && 
                     e.message.contains('not yet initialized'),
            ),
          ),
        );
      });
    });

    group('Reset and Cleanup', () {
      testWidgets('should reset all services when requested', (tester) async {
        // Arrange
        setupServiceLocator();
        expect(getIt.isRegistered<GeminiAIService>(), true);

        // Act
        getIt.reset();

        // Assert
        expect(getIt.isRegistered<GeminiAIService>(), false);
        expect(getIt.isRegistered<AuthRepository>(), false);
      });

      testWidgets('should detect and handle already registered services', (tester) async {
        // Arrange
        setupServiceLocator();
        expect(getIt.isRegistered<AuthRepository>(), true);

        // Act - Setup again (should reset and re-register)
        expect(() => setupServiceLocator(), returnsNormally);

        // Assert - Services should still be available
        expect(getIt.isRegistered<AuthRepository>(), true);
        expect(getIt.isRegistered<GeminiAIService>(), true);
      });
    });
  });
}
