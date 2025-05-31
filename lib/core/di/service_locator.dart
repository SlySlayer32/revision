import 'package:get_it/get_it.dart';

import 'package:revision/core/services/ai_service.dart';
import 'package:revision/core/services/circuit_breaker.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
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

/// Global service locator instance
final getIt = GetIt.instance;

/// Set up all dependencies in the service locator
void setupServiceLocator() {
  getIt
    // Core Services
    ..registerLazySingleton<CircuitBreaker>(CircuitBreaker.new)
    ..registerLazySingleton<AIService>(VertexAIService.new)

    // Data Sources
    ..registerLazySingleton<FirebaseAuthDataSource>(
      FirebaseAuthDataSourceImpl.new,
    )

    // Repositories
    ..registerLazySingleton<AuthenticationRepository>(
      () => FirebaseAuthenticationRepository(
        firebaseAuthDataSource: getIt<FirebaseAuthDataSource>(),
      ),
    )

    // Use Cases
    ..registerLazySingleton<SignInUseCase>(
      () => SignInUseCase(getIt<AuthenticationRepository>()),
    )
    ..registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(getIt<AuthenticationRepository>()),
    )
    ..registerLazySingleton<SignUpUseCase>(
      () => SignUpUseCase(getIt<AuthenticationRepository>()),
    )
    ..registerLazySingleton<SignOutUseCase>(
      () => SignOutUseCase(getIt<AuthenticationRepository>()),
    )
    ..registerLazySingleton<SendPasswordResetEmailUseCase>(
      () => SendPasswordResetEmailUseCase(getIt<AuthenticationRepository>()),
    )
    ..registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt<AuthenticationRepository>()),
    )
    ..registerLazySingleton<GetAuthStateChangesUseCase>(
      () => GetAuthStateChangesUseCase(getIt<AuthenticationRepository>()),
    )

    // BLoCs
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
      () => SignupBloc(
        signUp: getIt<SignUpUseCase>(),
      ),
    );

  // Add more services and repositories here as needed
}
