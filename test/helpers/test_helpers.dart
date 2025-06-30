// VGV-compliant test helpers
// Following Very Good Ventures testing patterns

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';

import 'mocks.dart';

/// VGV Test Helper utilities following Very Good Ventures patterns
class VGVTestHelper {
  /// Sets up GetIt service locator with mock dependencies for testing
  static void setupTestDependencies() {
    // Reset GetIt
    if (GetIt.instance.isRegistered<AuthRepository>()) {
      GetIt.instance.reset();
    } // Mock instances
    final mockAuthRepository = MockAuthRepository();
    final mockSignInUseCase = MockSignInUseCase();
    final mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    final mockSignUpUseCase = MockSignUpUseCase();
    final mockSignOutUseCase = MockSignOutUseCase();
    final mockSendPasswordResetEmailUseCase =
        MockSendPasswordResetEmailUseCase();
    final mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    final mockGetAuthStateChangesUseCase = MockGetAuthStateChangesUseCase();
    final mockLoginBloc = MockLoginBloc();
    final mockSignupBloc = MockSignupBloc();


    // Configure mock behaviors to return proper values
    when(mockGetAuthStateChangesUseCase.call)
        .thenAnswer((_) => Stream<User?>.value(null));

    when(mockSignOutUseCase.call)
        .thenAnswer((_) async => const Right<Failure, void>(null));

    // Register mocks in GetIt
    getIt
      // Repository
      ..registerLazySingleton<AuthRepository>(() => mockAuthRepository)

      // Use Cases
      ..registerLazySingleton<SignInUseCase>(() => mockSignInUseCase)
      ..registerLazySingleton<SignInWithGoogleUseCase>(
          () => mockSignInWithGoogleUseCase)
      ..registerLazySingleton<SignUpUseCase>(() => mockSignUpUseCase)
      ..registerLazySingleton<SignOutUseCase>(() => mockSignOutUseCase)
      ..registerLazySingleton<SendPasswordResetEmailUseCase>(
          () => mockSendPasswordResetEmailUseCase)
      ..registerLazySingleton<GetCurrentUserUseCase>(
          () => mockGetCurrentUserUseCase)
      ..registerLazySingleton<GetAuthStateChangesUseCase>(
          () => mockGetAuthStateChangesUseCase)

      // BLoCs - Remove AuthenticationBloc from here since app creates it directly
      ..registerFactory<LoginBloc>(() => mockLoginBloc)
      ..registerFactory<SignupBloc>(() => mockSignupBloc)
      
      // Mock GenerativeModel instances - commented out because GenerativeModel is final
      // and can't be properly mocked. Services that need these will handle gracefully.
      // ..registerLazySingleton<GenerativeModel>(
      //   () => mockAnalysisModel,
      //   instanceName: 'analysisModel',
      // )
      // ..registerLazySingleton<GenerativeModel>(
      //   () => mockImageModel,
      //   instanceName: 'imageGenerationModel',
      // )
      ;
  }

  /// Tears down test dependencies
  static void tearDownTestDependencies() {
    GetIt.instance.reset();
  }

  /// Creates a VGV-compliant widget test wrapper
  static Widget createApp({
    required Widget child,
    List<BlocProvider> providers = const [],
  }) {
    return MultiBlocProvider(
      providers: providers,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Creates a VGV-compliant page test wrapper
  static Widget createPage({
    required Widget page,
    List<BlocProvider> providers = const [],
  }) {
    return MultiBlocProvider(
      providers: providers,
      child: MaterialApp(
        home: Scaffold(body: page),
      ),
    );
  }

  /// Pumps and settles widget with standard VGV timing
  static Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(timeout);
  }

  /// VGV-compliant BLoC test helper for single event
  static void testBlocEvent<B extends BlocBase<S>, S>({
    required String description,
    required B Function() build,
    required dynamic Function(B bloc) act,
    required List<S> expect,
    S? seed,
    int skip = 0,
    Duration? wait,
    dynamic Function(B bloc)? verify,
  }) {
    blocTest<B, S>(
      description,
      build: build,
      seed: seed == null ? null : () => seed, // Re-applying seed!
      act: act,
      skip: skip,
      wait: wait,
      expect: () => expect,
      verify: verify,
    );
  }

  /// VGV-compliant mock verification helper
  static void verifyMockCall<T>(
    Mock mock,
    dynamic Function() call, {
    int times = 1,
  }) {
    verify(call).called(times);
  }

  /// VGV-compliant mock verification for never called
  static void verifyMockNeverCalled<T>(
    Mock mock,
    dynamic Function() call,
  ) {
    verifyNever(call);
  }

  /// Sets up mock return value
  static void whenMockCall<T>(
    dynamic Function() call,
    T returnValue,
  ) {
    when(call).thenReturn(returnValue);
  }

  /// Sets up mock async return value
  static void whenMockCallAsync<T>(
    dynamic Function() call,
    Future<T> returnValue,
  ) {
    when(call).thenAnswer((_) => returnValue);
  }

  /// Sets up mock stream return value
  static void whenMockCallStream<T>(
    dynamic Function() call,
    Stream<T> returnValue,
  ) {
    when(call).thenAnswer((_) => returnValue);
  }

  /// Sets up mock to throw exception
  static void whenMockCallThrows(
    dynamic Function() call,
    Object exception,
  ) {
    when(call).thenThrow(exception);
  }
}

/// VGV-compliant test constants
class VGVTestConstants {
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(milliseconds: 500);
  static const Duration longTimeout = Duration(seconds: 30);

  // Test data
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'TestPass123!';
  static const String testDisplayName = 'Test User';
  static const String testUserId = 'test-user-id';
  static const String testErrorMessage = 'Test error message';
}

/// VGV-compliant pump extensions for widget testing
extension VGVWidgetTesterExtensions on WidgetTester {
  /// Pumps widget and waits for animations with VGV timing
  Future<void> pumpAndSettleVGV([
    Duration timeout = VGVTestConstants.defaultTimeout,
  ]) async {
    await pumpAndSettle(timeout);
  }

  /// Finds widget by type with VGV error handling
  Finder findByTypeVGV<T extends Widget>() {
    return find.byType(T);
  }

  /// Finds widget by key with VGV error handling
  Finder findByKeyVGV(Key key) {
    return find.byKey(key);
  }

  /// Finds text with VGV error handling
  Finder findTextVGV(String text) {
    return find.text(text);
  }

  /// Taps widget and settles with VGV timing
  Future<void> tapAndSettleVGV(Finder finder) async {
    await tap(finder);
    await pumpAndSettleVGV();
  }

  /// Enters text and settles with VGV timing
  Future<void> enterTextAndSettleVGV(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettleVGV();
  }
}
