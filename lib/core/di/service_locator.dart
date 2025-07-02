import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_ai/firebase_ai.dart'; // Removed - using REST API instead
import 'package:revision/core/services/circuit_breaker.dart';
import 'package:revision/core/services/error_handler_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
// import 'package:revision/core/services/gemini_pipeline_service.dart'; // Disabled
import 'package:revision/core/services/image_save_service.dart';
import 'package:revision/core/services/logging_service.dart';
// AI processing feature temporarily disabled
// import 'package:revision/features/ai_processing/data/services/ai_result_save_service.dart';
// import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';
// import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';
// import 'package:revision/features/image_editing/presentation/cubit/image_annotation_cubit.dart'; // Disabled
import 'package:revision/features/image_selection/data/datasources/image_picker_data_source.dart';
import 'package:revision/features/image_selection/data/repositories/image_selection_repository_impl.dart';
import 'package:revision/features/image_selection/domain/repositories/image_selection_repository.dart'
    as image_selection;
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Set up all dependencies in the service locator
void setupServiceLocator() {
  debugPrint('setupServiceLocator: Starting dependency registration...');

  try {
    // Reset service locator for hot reload safety
    if (getIt.isRegistered<AuthRepository>()) {
      debugPrint(
          'setupServiceLocator: Dependencies already registered, resetting...');
      getIt.reset();
    }

    _registerCoreServices();
    _registerDataSources();
    _registerRepositories();
    _registerUseCases();
    _registerServices();
    _registerBlocs();

    debugPrint('setupServiceLocator: All dependencies registered successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ setupServiceLocator failed: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    rethrow;
  }
}

void _registerCoreServices() {
  getIt
    // Core Services
    ..registerLazySingleton<CircuitBreaker>(CircuitBreaker.new)
    ..registerLazySingleton(() => LoggingService.instance)
    ..registerLazySingleton(() => ErrorHandlerService.instance)
    ..registerLazySingleton<FirebaseAIRemoteConfigService>(
      FirebaseAIRemoteConfigService.new,
    )
    ..registerLazySingleton<GeminiAIService>(
      () => GeminiAIService(
          remoteConfigService: getIt<FirebaseAIRemoteConfigService>()),
    );
}

void _registerDataSources() {
  // Skip Firebase data sources if already registered (test mode)
  if (!getIt.isRegistered<FirebaseAuthDataSource>()) {
    getIt
      // Data Sources
      ..registerLazySingleton<FirebaseAuthDataSource>(
        () {
          try {
            return FirebaseAuthDataSourceImpl();
          } catch (e) {
            debugPrint('Error while creating FirebaseAuthDataSource: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
            rethrow;
          }
        },
      );
  }

  getIt
    ..registerLazySingleton<ImagePicker>(ImagePicker.new)
    ..registerLazySingleton<ImagePickerDataSource>(
      () => ImagePickerDataSource(getIt<ImagePicker>()),
    );
}

void _registerRepositories() {
  // Skip Firebase repositories if already registered (test mode)
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt
      // Repositories
      ..registerLazySingleton<AuthRepository>(
        () {
          try {
            return FirebaseAuthenticationRepository(
              firebaseAuthDataSource: getIt<FirebaseAuthDataSource>(),
            );
          } catch (e) {
            debugPrint('Error while creating AuthRepository: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
            rethrow;
          }
        },
      );
  }

  getIt
    ..registerLazySingleton<image_selection.ImageRepository>(
      () => ImageSelectionRepositoryImpl(getIt<ImagePickerDataSource>()),
    );
}

void _registerUseCases() {
  getIt
    // Use Cases
    ..registerLazySingleton<SignInUseCase>(
>>>>>>> Stashed changes
        () {
          try {
            return SignInUseCase(getIt<AuthRepository>());
          } catch (e) {
            debugPrint('Error while creating SignInUseCase: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
            rethrow;
          }
        },
      )
      ..registerLazySingleton<SignInWithGoogleUseCase>(
        () => SignInWithGoogleUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignUpUseCase>(
        () => SignUpUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignOutUseCase>(
        () {
          try {
            return SignOutUseCase(getIt<AuthRepository>());
          } catch (e) {
            debugPrint('Error while creating SignOutUseCase: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
            rethrow;
          }
        },
      )
      ..registerLazySingleton<SendPasswordResetEmailUseCase>(
        () => SendPasswordResetEmailUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<GetCurrentUserUseCase>(
        () => GetCurrentUserUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<GetAuthStateChangesUseCase>(
        () {
          try {
            return GetAuthStateChangesUseCase(getIt<AuthRepository>());
          } catch (e) {
            debugPrint('Error while creating GetAuthStateChangesUseCase: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
            rethrow;
          }
        },
      )
    ..registerLazySingleton<SelectImageUseCase>(
>>>>>>> Stashed changes
      () => SelectImageUseCase(getIt<image_selection.ImageRepository>()),
    );
}

void _registerServices() {
  getIt..registerLazySingleton<ImageSaveService>(ImageSaveService.new);
}

void _registerBlocs() {
  getIt
    // BLoCs and Cubits
    ..registerFactory<AuthenticationBloc>(
      () {
        try {
          return AuthenticationBloc(
            getAuthStateChanges: getIt<GetAuthStateChangesUseCase>(),
            signOut: getIt<SignOutUseCase>(),
          );
        } catch (e) {
          debugPrint('Error while creating AuthenticationBloc: $e');
          debugPrint('Stack trace: ${StackTrace.current}');
          rethrow;
        }
      },
    )
    ..registerFactory<LoginBloc>(
      () => LoginBloc(
        signIn: getIt<SignInUseCase>(),
        signInWithGoogle: getIt<SignInWithGoogleUseCase>(),
        sendPasswordResetEmail: getIt<SendPasswordResetEmailUseCase>(),
      ),
    )
    ..registerFactory<SignupBloc>(
      () => SignupBloc(signUp: getIt<SignUpUseCase>()),
    )
    ..registerFactory<ImageSelectionCubit>(
      () => ImageSelectionCubit(getIt<SelectImageUseCase>()),
    );
}
