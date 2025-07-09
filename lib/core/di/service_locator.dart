import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/circuit_breaker.dart';
import 'package:revision/core/services/error_handler_service.dart';
import 'package:revision/core/services/feature_flag_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/core/services/image_save_service.dart';
import 'package:revision/core/services/logging_service.dart';
import 'package:revision/core/services/onboarding_service.dart';
import 'package:revision/core/services/security_notification_service.dart';

import 'package:revision/features/ai_processing/data/services/ai_result_save_service.dart';
import 'package:revision/features/ai_processing/domain/usecases/generate_segmentation_masks_usecase.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/send_email_verification_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_editor_cubit.dart';
import 'package:revision/features/image_selection/data/datasources/image_picker_data_source.dart';
import 'package:revision/features/image_selection/data/repositories/image_selection_repository_impl.dart';
import 'package:revision/features/image_selection/domain/repositories/image_selection_repository.dart'
    as image_selection;
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';

// Service locator instance
final getIt = GetIt.instance;

// Enhanced logger for diagnostics
final _logger = LoggingService.instance;

/// Set up all dependencies in the service locator.
Future<void> setupServiceLocator() async {
  _logger.info('Starting service locator setup');
  try {
    // Reset for hot reload or test safety
    if (getIt.isRegistered<AuthRepository>()) {
      _logger.info('Dependencies already registered, resetting...');
      await getIt.reset();
    }

    _registerCoreServices();
    _registerDataSources();
    _registerRepositories();
    _registerUseCases();
    _registerServices();
    _registerBlocs();

    _logger.info('Service locator setup completed successfully');
  } catch (e, stackTrace) {
    _logger.error(
      'Service locator setup failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Shutdown service locator with cleanup
Future<void> shutdownServiceLocator() async {
  _logger.info('Shutting down service locator...');
  try {
    await getIt.reset();
    _logger.info('Service locator shutdown completed');
  } catch (e, stackTrace) {
    _logger.error(
      'Error during service locator shutdown: $e',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

void _registerCoreServices() {
  _logger.info('Registering core services');
  getIt
    ..registerLazySingleton<CircuitBreaker>(CircuitBreaker.new)
    ..registerLazySingleton(() => LoggingService.instance)
    ..registerLazySingleton(() => ErrorHandlerService.instance)
    ..registerLazySingleton(() => AnalyticsService())
    ..registerLazySingleton(() => OnboardingService())
    ..registerLazySingleton(() => SecurityNotificationService())
    ..registerLazySingleton<FirebaseAIRemoteConfigService>(FirebaseAIRemoteConfigService.new)
    ..registerLazySingleton<FeatureFlagService>(() {
      final service = FeatureFlagService();
      service.initialize(getIt<FirebaseAIRemoteConfigService>());
      return service;
    })
    ..registerLazySingleton<GeminiAIService>(() =>
        GeminiAIService(remoteConfigService: getIt<FirebaseAIRemoteConfigService>()));
  _logger.info('Core services registration completed');
}

void _registerDataSources() {
  _logger.info('Registering data sources');
  getIt
    ..registerLazySingleton<FirebaseAuthDataSource>(FirebaseAuthDataSourceImpl.new)
    ..registerLazySingleton<ImagePicker>(ImagePicker.new)
    ..registerLazySingleton<ImagePickerDataSource>(
        () => ImagePickerDataSource(getIt<ImagePicker>()));
  _logger.info('Data sources registration completed');
}

void _registerRepositories() {
  _logger.info('Registering repositories');
  getIt
    ..registerLazySingleton<AuthRepository>(() =>
        FirebaseAuthenticationRepository(firebaseAuthDataSource: getIt<FirebaseAuthDataSource>()))
    ..registerLazySingleton<image_selection.ImageRepository>(() =>
        ImageSelectionRepositoryImpl(getIt<ImagePickerDataSource>()));
  _logger.info('Repositories registration completed');
}

void _registerUseCases() {
  _logger.info('Registering use cases');
  getIt
    ..registerLazySingleton<SignInUseCase>(() => SignInUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<SignInWithGoogleUseCase>(() => SignInWithGoogleUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<SignUpUseCase>(() => SignUpUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<SendPasswordResetEmailUseCase>(() => SendPasswordResetEmailUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<SendEmailVerificationUseCase>(() => SendEmailVerificationUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<GetAuthStateChangesUseCase>(() => GetAuthStateChangesUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton<SelectImageUseCase>(() => SelectImageUseCase(getIt<image_selection.ImageRepository>()))
    ..registerLazySingleton<ProcessImageWithGeminiUseCase>(() => ProcessImageWithGeminiUseCase(getIt<GeminiPipelineService>()))
    ..registerLazySingleton<GenerateSegmentationMasksUseCase>(() => GenerateSegmentationMasksUseCase(getIt<GeminiAIService>()));
  _logger.info('Use cases registration completed');
}

void _registerServices() {
  _logger.info('Registering additional services');
  getIt
    ..registerLazySingleton<ImageSaveService>(ImageSaveService.new)
    ..registerLazySingleton<AIResultSaveService>(AIResultSaveService.new)
    ..registerLazySingleton<GeminiPipelineService>(
        () => GeminiPipelineService(geminiAIService: getIt<GeminiAIService>()));
  _logger.info('Additional services registration completed');
}

void _registerBlocs() {
  _logger.info('Registering blocs and cubits');
  getIt
    ..registerFactory<AuthenticationBloc>(() => AuthenticationBloc(
          getAuthStateChanges: getIt<GetAuthStateChangesUseCase>(),
          signOut: getIt<SignOutUseCase>(),
        ))
    ..registerFactory<LoginBloc>(() => LoginBloc(
          signIn: getIt<SignInUseCase>(),
          signInWithGoogle: getIt<SignInWithGoogleUseCase>(),
          sendPasswordResetEmail: getIt<SendPasswordResetEmailUseCase>(),
        ))
    ..registerFactory<SignupBloc>(() => SignupBloc(
          signUp: getIt<SignUpUseCase>(),
          sendEmailVerification: getIt<SendEmailVerificationUseCase>(),
        ))
    ..registerFactory<ImageSelectionCubit>(() => ImageSelectionCubit(getIt<SelectImageUseCase>()))
    ..registerFactory<ImageEditorCubit>(() => ImageEditorCubit())
    ..registerFactory<GeminiPipelineCubit>(() => GeminiPipelineCubit(getIt<ProcessImageWithGeminiUseCase>()));
  _logger.info('Blocs and cubits registration completed');
}