import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:revision/core/services/circuit_breaker.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/core/services/image_save_service.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
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
import 'package:revision/features/image_editing/presentation/cubit/image_annotation_cubit.dart';
import 'package:revision/features/image_selection/data/datasources/image_picker_data_source.dart';
import 'package:revision/features/image_selection/data/repositories/image_selection_repository_impl.dart';
import 'package:revision/features/image_selection/domain/repositories/image_selection_repository.dart';
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Set up all dependencies in the service locator
void setupServiceLocator() {
  debugPrint('setupServiceLocator: Starting dependency registration...');

  try {
    getIt
      // Core Services
      ..registerLazySingleton<CircuitBreaker>(CircuitBreaker.new)
      ..registerLazySingleton<GeminiPipelineService>(GeminiPipelineService.new)

      // Data Sources
      ..registerLazySingleton<FirebaseAuthDataSource>(
        FirebaseAuthDataSourceImpl.new,
      )
      ..registerLazySingleton<ImagePicker>(ImagePicker.new)
      ..registerLazySingleton<ImagePickerDataSource>(
        () => ImagePickerDataSource(getIt<ImagePicker>()),
      )

      // Repositories
      ..registerLazySingleton<AuthRepository>(
        () => FirebaseAuthenticationRepository(
          firebaseAuthDataSource: getIt<FirebaseAuthDataSource>(),
        ),
      )
      ..registerLazySingleton<ImageRepository>(
        () => ImageSelectionRepositoryImpl(getIt<ImagePickerDataSource>()),
      )

      // Use Cases
      ..registerLazySingleton<SignInUseCase>(
        () => SignInUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignInWithGoogleUseCase>(
        () => SignInWithGoogleUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignUpUseCase>(
        () => SignUpUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignOutUseCase>(
        () => SignOutUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SendPasswordResetEmailUseCase>(
        () => SendPasswordResetEmailUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<GetCurrentUserUseCase>(
        () => GetCurrentUserUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<GetAuthStateChangesUseCase>(
        () => GetAuthStateChangesUseCase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SelectImageUseCase>(
        () => SelectImageUseCase(getIt<ImageRepository>()),
      )
      ..registerLazySingleton<ImageSaveService>(ImageSaveService.new)

      // Gemini AI Pipeline (MVP Implementation)
      ..registerLazySingleton<ProcessImageWithGeminiUseCase>(
        () => ProcessImageWithGeminiUseCase(getIt<GeminiPipelineService>()),
      )

      // BLoCs and Cubits
      ..registerFactory<AuthenticationBloc>(
        () => AuthenticationBloc(
          getAuthStateChanges: getIt<GetAuthStateChangesUseCase>(),
          signOut: getIt<SignOutUseCase>(),
        ),
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
      )
      ..registerFactory<GeminiPipelineCubit>(
        () => GeminiPipelineCubit(getIt<ProcessImageWithGeminiUseCase>()),
      )
      ..registerFactory<ImageAnnotationCubit>(
        ImageAnnotationCubit.new,
      );

    debugPrint('setupServiceLocator: All dependencies registered successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ setupServiceLocator failed: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    rethrow;
  }

  // AI Processing dependencies are now registered
}
