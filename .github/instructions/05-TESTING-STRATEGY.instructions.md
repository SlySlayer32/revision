---
applyTo: '**'
---

# 🧪 Testing Strategy - Complete Production Testing Guide

## 📋 Testing Philosophy & Principles

Testing is not optional—it's a fundamental requirement for production-grade Flutter applications. This guide provides comprehensive testing strategies that ensure reliability, maintainability, and confidence in your codebase.

### 🎯 Testing Pyramid (MANDATORY COVERAGE)

```
           🔺 End-to-End Tests (5-10%)
          ███ Integration Tests (20-30%)
         █████ Unit Tests (60-70%)
```

### 📊 Coverage Requirements by Layer

| Layer | Minimum Coverage | Target Coverage | Test Types |
|-------|------------------|-----------------|------------|
| Domain | 100% | 100% | Unit Tests |
| Data | 95% | 98% | Unit + Integration |
| Presentation | 90% | 95% | Widget + BLoC Tests |
| E2E | Key Flows | All Critical Paths | Integration Tests |

## 🏗️ Test Project Structure

### Test Directory Organization
```
test/
├── 🧪 unit/                         # Unit tests
│   ├── core/                        # Core utilities testing
│   │   ├── di/
│   │   ├── error/
│   │   ├── services/
│   │   └── utils/
│   └── features/                    # Feature testing
│       ├── authentication/
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       └── image_editor/
├── 🎨 widget/                       # Widget tests
│   ├── authentication/
│   └── image_editor/
├── 🔗 integration/                  # Integration tests
│   ├── firebase_auth_test.dart
│   ├── ai_processing_test.dart
│   └── e2e_user_journey_test.dart
├── 📚 helpers/                      # Test utilities
│   ├── mocks/
│   │   ├── mock_repositories.dart
│   │   ├── mock_services.dart
│   │   └── mock_data_sources.dart
│   ├── test_data/
│   │   ├── test_images.dart
│   │   ├── test_users.dart
│   │   └── test_ai_responses.dart
│   ├── factories/
│   │   ├── entity_factory.dart
│   │   ├── model_factory.dart
│   │   └── response_factory.dart
│   ├── matchers/
│   │   ├── custom_matchers.dart
│   │   └── bloc_matchers.dart
│   └── utilities/
│       ├── pump_app.dart
│       ├── test_environment.dart
│       └── golden_test_helper.dart
└── ⚙️ fixtures/                     # Test data files
    ├── images/
    │   ├── test_image_1.jpg
    │   ├── test_image_2.png
    │   └── test_mask.png
    ├── json/
    │   ├── user_response.json
    │   ├── ai_analysis_response.json
    │   └── error_responses.json
    └── configurations/
        ├── test_firebase_config.json
        └── test_environment_config.json
```

## 🧰 Test Setup & Configuration

### Test Dependencies
```yaml
dev_dependencies:
  # Core testing
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  
  # BLoC testing
  bloc_test: ^9.1.7
  
  # Mocking
  mocktail: ^1.0.4
  mockito: ^5.4.4
  build_runner: ^2.4.9
  
  # Network testing
  http_mock_adapter: ^0.6.1
  nock: ^1.2.4
  
  # Firebase testing
  fake_cloud_firestore: ^2.5.2
  firebase_auth_mocks: ^0.13.0
  firebase_storage_mocks: ^0.6.1
  
  # Test utilities
  golden_toolkit: ^0.15.0
  flutter_driver:
    sdk: flutter
  test: ^1.25.8
  
  # Code coverage
  coverage: ^1.8.0
  very_good_analysis: ^5.1.0
```

### Test Configuration Files

#### dart_test.yaml
```yaml
# dart_test.yaml
tags:
  unit:
  widget:
  integration:
  e2e:
  slow:

# Test timeouts
timeout: 30s
test_on: "vm"

# Override configuration for specific test types
override:
  integration:
    timeout: 2m
  e2e:
    timeout: 5m
  slow:
    timeout: 1m

# Test file patterns
file_selectors:
  unit:
    - "test/unit/**"
  widget:
    - "test/widget/**"
  integration:
    - "test/integration/**"

# Reporter configuration
reporter: expanded

# Test concurrency
concurrency: 4

# Test randomization
shuffle: auto
```

#### Test Environment Setup
```dart
// test/helpers/test_environment.dart
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_firebase.dart';

class TestEnvironment {
  static Future<void> setUp() async {
    // Set up test environment
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock Firebase
    setupFirebaseAuthMocks();
    
    // Set up mock method channels
    _setupMethodChannelMocks();
    
    // Register mock fallback values
    _registerFallbackValues();
    
    // Initialize test-specific services
    await _initializeTestServices();
  }

  static void tearDown() {
    // Clean up after tests
    reset();
  }

  static void _setupMethodChannelMocks() {
    // Mock platform channels for testing
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'pickImage':
            return 'test_image_path.jpg';
          case 'getImage':
            return 'test_image_path.jpg';
          default:
            return null;
        }
      },
    );

    // Mock Firebase method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  }

  static void _registerFallbackValues() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeUser());
    registerFallbackValue(FakeAuthCredential());
    registerFallbackValue(FakeFirebaseException());
  }

  static Future<void> _initializeTestServices() async {
    // Initialize any test-specific services
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      ),
    );
  }
}

// Fallback values for mocktail
class FakeUser extends Fake implements User {}
class FakeAuthCredential extends Fake implements AuthCredential {}
class FakeFirebaseException extends Fake implements FirebaseException {}
```

## 🎯 Domain Layer Testing (Unit Tests)

### Entity Testing
```dart
// test/unit/features/authentication/domain/entities/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    test('should create user with valid data', () {
      // arrange
      const id = 'test-id';
      const email = 'test@example.com';
      const displayName = 'Test User';

      // act
      const user = User(
        id: id,
        email: email,
        displayName: displayName,
      );

      // assert
      expect(user.id, equals(id));
      expect(user.email, equals(email));
      expect(user.displayName, equals(displayName));
    });

    test('should support value equality', () {
      // arrange
      const user1 = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      const user2 = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      // assert
      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('should have correct props for equality', () {
      // arrange
      const user = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      // assert
      expect(
        user.props,
        equals(['test-id', 'test@example.com', 'Test User']),
      );
    });

    group('validation', () {
      test('should validate email format', () {
        // arrange & act & assert
        expect(
          () => User(
            id: 'test-id',
            email: 'invalid-email',
            displayName: 'Test User',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should not allow empty id', () {
        // arrange & act & assert
        expect(
          () => User(
            id: '',
            email: 'test@example.com',
            displayName: 'Test User',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
```

### Use Case Testing
```dart
// test/unit/features/authentication/domain/usecases/sign_in_with_email_usecase_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_email_usecase.dart';

import '../../../../helpers/test_data/test_users.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmailUseCase(mockRepository);
  });

  group('SignInWithEmailUseCase', () {
    final tUser = TestUsers.createValidUser();
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    final tParams = SignInWithEmailParams(email: tEmail, password: tPassword);

    test('should return User when sign in is successful', () async {
      // arrange
      when(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(tUser));

      // act
      final result = await useCase(tParams);

      // assert
      expect(result, equals(Right(tUser)));
      verify(
        () => mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AuthFailure when credentials are invalid', () async {
      // arrange
      const tFailure = AuthFailure(message: 'Invalid credentials');
      when(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(tParams);

      // assert
      expect(result, equals(const Left(tFailure)));
      verify(
        () => mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should validate email format in parameters', () {
      // arrange
      const invalidEmail = 'invalid-email';
      final invalidParams = SignInWithEmailParams(
        email: invalidEmail,
        password: tPassword,
      );

      // act & assert
      expect(
        () => useCase(invalidParams),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate password strength in parameters', () {
      // arrange
      const weakPassword = '123';
      final invalidParams = SignInWithEmailParams(
        email: tEmail,
        password: weakPassword,
      );

      // act & assert
      expect(
        () => useCase(invalidParams),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

## 💾 Data Layer Testing

### Repository Implementation Testing
```dart
// test/unit/features/authentication/data/repositories/auth_repository_impl_test.dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:revision/core/error/exceptions.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/core/network/network_info.dart';
import 'package:revision/features/authentication/data/datasources/local/auth_local_data_source.dart';
import 'package:revision/features/authentication/data/datasources/remote/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/models/user_model.dart';
import 'package:revision/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

import '../../../../helpers/test_data/test_users.dart';

class MockFirebaseAuthDataSource extends Mock implements FirebaseAuthDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuthDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockFirebaseAuthDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  void runTestsOnline(Function body) {
    group('device is online', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
      });

      body();
    });
  }

  void runTestsOffline(Function body) {
    group('device is offline', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);
      });

      body();
    });
  }

  group('AuthRepositoryImpl', () {
    group('signInWithEmail', () {
      const tEmail = 'test@example.com';
      const tPassword = 'password123';
      final tUserModel = TestUsers.createValidUserModel();

      runTestsOnline(() {
        test('should return UserModel when sign in is successful', () async {
          // arrange
          when(
            () => mockRemoteDataSource.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => tUserModel);

          when(
            () => mockLocalDataSource.cacheUser(any()),
          ).thenAnswer((_) async => Future.value());

          // act
          final result = await repository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          );

          // assert
          expect(result, equals(Right(tUserModel)));
          verify(
            () => mockRemoteDataSource.signInWithEmailAndPassword(
              email: tEmail,
              password: tPassword,
            ),
          ).called(1);
          verify(
            () => mockLocalDataSource.cacheUser(tUserModel),
          ).called(1);
        });

        test('should return AuthFailure when FirebaseAuthException occurs', () async {
          // arrange
          when(
            () => mockRemoteDataSource.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(
            const FirebaseAuthException(
              code: 'user-not-found',
              message: 'No user found for that email.',
            ),
          );

          // act
          final result = await repository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          );

          // assert
          expect(
            result,
            equals(
              const Left(AuthFailure(message: 'Invalid email or password')),
            ),
          );
          verify(
            () => mockRemoteDataSource.signInWithEmailAndPassword(
              email: tEmail,
              password: tPassword,
            ),
          ).called(1);
          verifyNever(() => mockLocalDataSource.cacheUser(any()));
        });

        test('should return ServerFailure when unexpected exception occurs', () async {
          // arrange
          when(
            () => mockRemoteDataSource.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(Exception('Unexpected error'));

          // act
          final result = await repository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          );

          // assert
          expect(
            result,
            equals(
              const Left(ServerFailure(message: 'Exception: Unexpected error')),
            ),
          );
        });
      });

      runTestsOffline(() {
        test('should return NetworkFailure when device is offline', () async {
          // act
          final result = await repository.signInWithEmail(
            email: tEmail,
            password: tPassword,
          );

          // assert
          expect(
            result,
            equals(
              const Left(NetworkFailure(message: 'No internet connection')),
            ),
          );
          verifyNever(
            () => mockRemoteDataSource.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
        });
      });
    });

    group('getCurrentUser', () {
      final tUserModel = TestUsers.createValidUserModel();

      test('should return cached user when available', () async {
        // arrange
        when(() => mockLocalDataSource.getLastUser())
            .thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, equals(Right(tUserModel)));
        verify(() => mockLocalDataSource.getLastUser()).called(1);
        verifyNever(() => mockRemoteDataSource.getCurrentUser());
      });

      test('should fetch from remote when no cached user', () async {
        // arrange
        when(() => mockLocalDataSource.getLastUser())
            .thenThrow(CacheException());
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => tUserModel);
        when(() => mockLocalDataSource.cacheUser(any()))
            .thenAnswer((_) async => Future.value());

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, equals(Right(tUserModel)));
        verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
        verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
      });
    });
  });
}
```

### Data Source Testing
```dart
// test/unit/features/authentication/data/datasources/remote/firebase_auth_data_source_test.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

import 'package:revision/core/error/exceptions.dart';
import 'package:revision/features/authentication/data/datasources/remote/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/models/user_model.dart';

import '../../../../../helpers/mock_firebase.dart';
import '../../../../../helpers/test_data/test_users.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

void main() {
  late FirebaseAuthDataSourceImpl dataSource;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    dataSource = FirebaseAuthDataSourceImpl(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('FirebaseAuthDataSource', () {
    group('signInWithEmailAndPassword', () {
      const tEmail = 'test@example.com';
      const tPassword = 'password123';
      late MockUserCredential mockUserCredential;
      late MockUser mockUser;
      late UserModel tUserModel;

      setUp(() {
        mockUserCredential = MockUserCredential();
        mockUser = MockUser();
        tUserModel = TestUsers.createValidUserModel();

        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUserModel.id);
        when(() => mockUser.email).thenReturn(tUserModel.email);
        when(() => mockUser.displayName).thenReturn(tUserModel.displayName);
        when(() => mockUser.photoURL).thenReturn(tUserModel.photoUrl);
      });

      test('should return UserModel when sign in is successful', () async {
        // arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockUserCredential);

        // act
        final result = await dataSource.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, equals(tUserModel));
        verify(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
        ).called(1);
      });

      test('should throw ServerException when FirebaseAuthException occurs', () async {
        // arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found for that email.',
          ),
        );

        // act
        final call = dataSource.signInWithEmailAndPassword;

        // assert
        expect(
          () => call(email: tEmail, password: tPassword),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw ServerException when unexpected exception occurs', () async {
        // arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Unexpected error'));

        // act
        final call = dataSource.signInWithEmailAndPassword;

        // assert
        expect(
          () => call(email: tEmail, password: tPassword),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('signInWithGoogle', () {
      late MockGoogleSignInAccount mockGoogleSignInAccount;
      late MockGoogleSignInAuthentication mockGoogleSignInAuthentication;
      late MockUserCredential mockUserCredential;
      late MockUser mockUser;
      late UserModel tUserModel;

      setUp(() {
        mockGoogleSignInAccount = MockGoogleSignInAccount();
        mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
        mockUserCredential = MockUserCredential();
        mockUser = MockUser();
        tUserModel = TestUsers.createValidUserModel();

        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUserModel.id);
        when(() => mockUser.email).thenReturn(tUserModel.email);
        when(() => mockUser.displayName).thenReturn(tUserModel.displayName);
        when(() => mockUser.photoURL).thenReturn(tUserModel.photoUrl);
      });

      test('should return UserModel when Google sign in is successful', () async {
        // arrange
        when(() => mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockGoogleSignInAccount);
        when(() => mockGoogleSignInAccount.authentication)
            .thenAnswer((_) async => mockGoogleSignInAuthentication);
        when(() => mockGoogleSignInAuthentication.accessToken)
            .thenReturn('access_token');
        when(() => mockGoogleSignInAuthentication.idToken)
            .thenReturn('id_token');
        when(
          () => mockFirebaseAuth.signInWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);

        // act
        final result = await dataSource.signInWithGoogle();

        // assert
        expect(result, equals(tUserModel));
        verify(() => mockGoogleSignIn.signIn()).called(1);
        verify(() => mockFirebaseAuth.signInWithCredential(any())).called(1);
      });

      test('should throw ServerException when user cancels Google sign in', () async {
        // arrange
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // act
        final call = dataSource.signInWithGoogle;

        // assert
        expect(() => call(), throwsA(isA<ServerException>()));
      });
    });

    group('signOut', () {
      test('should call FirebaseAuth and GoogleSignIn signOut', () async {
        // arrange
        when(() => mockFirebaseAuth.signOut())
            .thenAnswer((_) async => Future.value());
        when(() => mockGoogleSignIn.signOut())
            .thenAnswer((_) async => null);

        // act
        await dataSource.signOut();

        // assert
        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });
    });

    group('getCurrentUser', () {
      late MockUser mockUser;
      late UserModel tUserModel;

      setUp(() {
        mockUser = MockUser();
        tUserModel = TestUsers.createValidUserModel();

        when(() => mockUser.uid).thenReturn(tUserModel.id);
        when(() => mockUser.email).thenReturn(tUserModel.email);
        when(() => mockUser.displayName).thenReturn(tUserModel.displayName);
        when(() => mockUser.photoURL).thenReturn(tUserModel.photoUrl);
      });

      test('should return UserModel when user is authenticated', () async {
        // arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // act
        final result = await dataSource.getCurrentUser();

        // assert
        expect(result, equals(tUserModel));
      });

      test('should throw ServerException when no user is authenticated', () async {
        // arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // act
        final call = dataSource.getCurrentUser;

        // assert
        expect(() => call(), throwsA(isA<ServerException>()));
      });
    });

    group('authStateChanges', () {
      test('should return stream of User changes', () async {
        // arrange
        final mockUser = MockUser();
        final tUserModel = TestUsers.createValidUserModel();

        when(() => mockUser.uid).thenReturn(tUserModel.id);
        when(() => mockUser.email).thenReturn(tUserModel.email);
        when(() => mockUser.displayName).thenReturn(tUserModel.displayName);
        when(() => mockUser.photoURL).thenReturn(tUserModel.photoUrl);

        when(() => mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => Stream.fromIterable([mockUser, null]));

        // act
        final stream = dataSource.authStateChanges;

        // assert
        expect(
          stream,
          emitsInOrder([
            tUserModel,
            null,
          ]),
        );
      });
    });
  });
}
```

## 🎨 Presentation Layer Testing

### BLoC Testing
```dart
// test/unit/features/authentication/presentation/blocs/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/auth_bloc.dart';

import '../../../../helpers/test_data/test_users.dart';

class MockGetAuthStateChangesUseCase extends Mock implements GetAuthStateChangesUseCase {}
class MockSignInWithEmailUseCase extends Mock implements SignInWithEmailUseCase {}
class MockSignInWithGoogleUseCase extends Mock implements SignInWithGoogleUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockGetAuthStateChangesUseCase mockGetAuthStateChanges;
  late MockSignInWithEmailUseCase mockSignInWithEmail;
  late MockSignInWithGoogleUseCase mockSignInWithGoogle;
  late MockSignOutUseCase mockSignOut;

  setUp(() {
    mockGetAuthStateChanges = MockGetAuthStateChangesUseCase();
    mockSignInWithEmail = MockSignInWithEmailUseCase();
    mockSignInWithGoogle = MockSignInWithGoogleUseCase();
    mockSignOut = MockSignOutUseCase();

    // Default behavior: empty stream
    when(() => mockGetAuthStateChanges.call(any()))
        .thenAnswer((_) => Stream.empty());

    authBloc = AuthBloc(
      getAuthStateChanges: mockGetAuthStateChanges,
      signInWithEmail: mockSignInWithEmail,
      signInWithGoogle: mockSignInWithGoogle,
      signOut: mockSignOut,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, equals(const AuthState.initial()));
  });

  group('AuthSubscriptionRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [unauthenticated] when user stream emits null',
      build: () {
        when(() => mockGetAuthStateChanges.call(any()))
            .thenAnswer((_) => Stream.value(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [
        const AuthState.unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [authenticated] when user stream emits user',
      build: () {
        final user = TestUsers.createValidUser();
        when(() => mockGetAuthStateChanges.call(any()))
            .thenAnswer((_) => Stream.value(user));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [
        AuthState.authenticated(TestUsers.createValidUser()),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits multiple states when user stream changes',
      build: () {
        final user = TestUsers.createValidUser();
        when(() => mockGetAuthStateChanges.call(any()))
            .thenAnswer((_) => Stream.fromIterable([user, null, user]));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [
        AuthState.authenticated(TestUsers.createValidUser()),
        const AuthState.unauthenticated(),
        AuthState.authenticated(TestUsers.createValidUser()),
      ],
    );
  });

  group('SignInWithEmailRequested', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    final tUser = TestUsers.createValidUser();

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when sign in succeeds',
      build: () {
        when(() => mockSignInWithEmail.call(any()))
            .thenAnswer((_) async => Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const SignInWithEmailRequested(
          email: tEmail,
          password: tPassword,
        ),
      ),
      expect: () => [
        const AuthState.loading(),
        AuthState.authenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when sign in fails',
      build: () {
        when(() => mockSignInWithEmail.call(any()))
            .thenAnswer(
              (_) async => const Left(
                AuthFailure(message: 'Invalid credentials'),
              ),
            );
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const SignInWithEmailRequested(
          email: tEmail,
          password: tPassword,
        ),
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error(message: 'Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'calls SignInWithEmailUseCase with correct parameters',
      build: () {
        when(() => mockSignInWithEmail.call(any()))
            .thenAnswer((_) async => Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const SignInWithEmailRequested(
          email: tEmail,
          password: tPassword,
        ),
      ),
      verify: (_) {
        verify(
          () => mockSignInWithEmail.call(
            SignInWithEmailParams(email: tEmail, password: tPassword),
          ),
        ).called(1);
      },
    );
  });

  group('SignInWithGoogleRequested', () {
    final tUser = TestUsers.createValidUser();

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when Google sign in succeeds',
      build: () {
        when(() => mockSignInWithGoogle.call(any()))
            .thenAnswer((_) async => Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignInWithGoogleRequested()),
      expect: () => [
        const AuthState.loading(),
        AuthState.authenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when Google sign in fails',
      build: () {
        when(() => mockSignInWithGoogle.call(any()))
            .thenAnswer(
              (_) async => const Left(
                AuthFailure(message: 'Google sign in failed'),
              ),
            );
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignInWithGoogleRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error(message: 'Google sign in failed'),
      ],
    );
  });

  group('SignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when sign out succeeds',
      build: () {
        when(() => mockSignOut.call(any()))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when sign out fails',
      build: () {
        when(() => mockSignOut.call(any()))
            .thenAnswer(
              (_) async => const Left(
                ServerFailure(message: 'Sign out failed'),
              ),
            );
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error(message: 'Sign out failed'),
      ],
    );
  });
}
```

### Widget Testing
```dart
// test/widget/features/authentication/presentation/pages/login_page_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:revision/features/authentication/presentation/blocs/auth_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/login_page.dart';

import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/test_data/test_users.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  group('LoginPage', () {
    testWidgets('renders LoginView', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginPage(),
        ),
      );

      expect(find.byType(LoginView), findsOneWidget);
    });
  });

  group('LoginView', () {
    testWidgets('renders email and password text fields', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      expect(find.byKey(const Key('loginView_emailInput_textField')), findsOneWidget);
      expect(find.byKey(const Key('loginView_passwordInput_textField')), findsOneWidget);
    });

    testWidgets('renders sign in button', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      expect(find.byKey(const Key('loginView_signIn_elevatedButton')), findsOneWidget);
    });

    testWidgets('renders Google sign in button', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      expect(find.byKey(const Key('loginView_googleSignIn_elevatedButton')), findsOneWidget);
    });

    testWidgets('adds SignInWithEmailRequested when sign in button is tapped', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('loginView_emailInput_textField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginView_passwordInput_textField')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('loginView_signIn_elevatedButton')));

      verify(
        () => mockAuthBloc.add(
          const SignInWithEmailRequested(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
      ).called(1);
    });

    testWidgets('adds SignInWithGoogleRequested when Google sign in button is tapped', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      await tester.tap(find.byKey(const Key('loginView_googleSignIn_elevatedButton')));

      verify(
        () => mockAuthBloc.add(const SignInWithGoogleRequested()),
      ).called(1);
    });

    testWidgets('shows loading indicator when state is loading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.loading());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar when state is error', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      // Trigger state change to error
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState.error(message: 'Invalid credentials'),
      );

      mockAuthBloc.add(const SignInWithEmailRequested(
        email: 'test@example.com',
        password: 'wrong_password',
      ));

      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('validates email input', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('loginView_emailInput_textField')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('loginView_passwordInput_textField')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('loginView_signIn_elevatedButton')));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('validates password input', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthBloc,
          child: const LoginView(),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('loginView_emailInput_textField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginView_passwordInput_textField')),
        '123',
      );

      await tester.tap(find.byKey(const Key('loginView_signIn_elevatedButton')));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      verifyNever(() => mockAuthBloc.add(any()));
    });
  });
}
```

## 🔗 Integration Testing

### Firebase Authentication Integration Test
```dart
// test/integration/firebase_auth_integration_test.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_environment.dart';

void main() {
  group('Firebase Authentication Integration', () {
    setUpAll(() async {
      await TestEnvironment.setUp();
    });

    tearDownAll(() {
      TestEnvironment.tearDown();
    });

    group('Email/Password Authentication', () {
      test('should create user with email and password', () async {
        // arrange
        const email = 'test@example.com';
        const password = 'password123';

        // act
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // assert
        expect(userCredential.user, isNotNull);
        expect(userCredential.user!.email, equals(email));
        expect(userCredential.user!.emailVerified, isFalse);

        // cleanup
        await userCredential.user!.delete();
      });

      test('should sign in existing user with correct credentials', () async {
        // arrange
        const email = 'test2@example.com';
        const password = 'password123';

        // Create user first
        final createResult = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Sign out
        await FirebaseAuth.instance.signOut();

        // act
        final signInResult = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // assert
        expect(signInResult.user, isNotNull);
        expect(signInResult.user!.email, equals(email));
        expect(signInResult.user!.uid, equals(createResult.user!.uid));

        // cleanup
        await signInResult.user!.delete();
      });

      test('should throw exception for invalid credentials', () async {
        // arrange
        const email = 'nonexistent@example.com';
        const password = 'wrongpassword';

        // act & assert
        expect(
          () => FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Auth State Changes', () {
      test('should emit auth state changes', () async {
        // arrange
        const email = 'test3@example.com';
        const password = 'password123';
        final authStateChanges = FirebaseAuth.instance.authStateChanges();
        
        final states = <User?>[];
        final subscription = authStateChanges.listen(states.add);

        // act
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        await FirebaseAuth.instance.signOut();

        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.last, isNull); // Last state should be null (signed out)

        // cleanup
        await subscription.cancel();
        if (userCredential.user != null) {
          await userCredential.user!.delete();
        }
      });
    });
  });
}
```

## 🎬 End-to-End Testing

### Complete User Journey Test
```dart
// test/integration/e2e_user_journey_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:revision/main.dart' as app;
import '../helpers/test_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End User Journey', () {
    setUpAll(() async {
      await TestEnvironment.setUp();
    });

    tearDownAll(() {
      TestEnvironment.tearDown();
    });

    testWidgets('complete authentication and image editing flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify welcome screen is shown
      expect(find.text('Welcome to Revision'), findsOneWidget);
      
      // 2. Navigate to login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // 3. Enter credentials and sign in
      await tester.enterText(
        find.byKey(const Key('loginView_emailInput_textField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('loginView_passwordInput_textField')),
        'password123',
      );
      
      await tester.tap(find.byKey(const Key('loginView_signIn_elevatedButton')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 4. Verify user is signed in and home screen is shown
      expect(find.text('Home'), findsOneWidget);
      
      // 5. Navigate to image editor
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();

      // 6. Select image from gallery (mocked)
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // 7. Verify image is displayed
      expect(find.byType(Image), findsOneWidget);

      // 8. Start drawing mask
      final imageWidget = find.byType(Image);
      final imageRect = tester.getRect(imageWidget);
      
      // Simulate drawing gestures
      await tester.dragFrom(
        imageRect.center,
        const Offset(50, 50),
      );
      await tester.pumpAndSettle();

      // 9. Generate AI prompt
      await tester.tap(find.text('Generate Prompt'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 10. Verify AI prompt is generated
      expect(find.textContaining('AI Generated:'), findsOneWidget);

      // 11. Process image with AI
      await tester.tap(find.text('Process Image'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 12. Verify processed image is shown
      expect(find.text('Processing Complete'), findsOneWidget);

      // 13. Save result
      await tester.tap(find.text('Save to Gallery'));
      await tester.pumpAndSettle();

      // 14. Verify success message
      expect(find.text('Image saved successfully'), findsOneWidget);

      // 15. Sign out
      await tester.tap(find.byIcon(Icons.account_circle));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // 16. Verify user is signed out
      expect(find.text('Welcome to Revision'), findsOneWidget);
    });
  });
}
```

## 📊 Test Execution & Coverage

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test types
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run with specific tags
flutter test --tags unit
flutter test --tags integration
flutter test --tags slow

# Run tests in parallel
flutter test --concurrency=4

# Run specific test file
flutter test test/unit/features/authentication/domain/usecases/sign_in_with_email_usecase_test.dart
```

### Coverage Report Generation
```bash
# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html

# Generate coverage summary
lcov --summary coverage/lcov.info
```

### Continuous Integration Configuration
```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Analyze code
      run: flutter analyze
    
    - name: Run unit tests
      run: flutter test --tags unit --coverage
    
    - name: Run widget tests
      run: flutter test --tags widget
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
    
    - name: Check coverage threshold
      run: |
        coverage_percentage=$(lcov --summary coverage/lcov.info | grep -o '[0-9.]*%' | tail -1 | sed 's/%//')
        if (( $(echo "$coverage_percentage < 90" | bc -l) )); then
          echo "Coverage is below 90%: $coverage_percentage%"
          exit 1
        fi
```

## 🔧 Test Utilities & Helpers

### Custom Test Matchers
```dart
// test/helpers/matchers/custom_matchers.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:revision/core/error/failures.dart';

// Custom matcher for testing Failure types
Matcher isAuthFailure([String? message]) => _FailureMatcher(
      AuthFailure,
      message,
    );

Matcher isNetworkFailure([String? message]) => _FailureMatcher(
      NetworkFailure,
      message,
    );

Matcher isServerFailure([String? message]) => _FailureMatcher(
      ServerFailure,
      message,
    );

class _FailureMatcher extends Matcher {
  const _FailureMatcher(this.failureType, this.expectedMessage);

  final Type failureType;
  final String? expectedMessage;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! Failure) return false;
    if (item.runtimeType != failureType) return false;
    if (expectedMessage != null && item.message != expectedMessage) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('is a $failureType');
    if (expectedMessage != null) {
      description.add(' with message "$expectedMessage"');
    }
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! Failure) {
      return mismatchDescription.add('is not a Failure');
    }
    if (item.runtimeType != failureType) {
      return mismatchDescription.add('is ${item.runtimeType}, not $failureType');
    }
    if (expectedMessage != null && item.message != expectedMessage) {
      return mismatchDescription.add('has message "${item.message}", not "$expectedMessage"');
    }
    return mismatchDescription;
  }
}

// Email validation matcher
Matcher isValidEmail() => _EmailMatcher();

class _EmailMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! String) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(item);
  }

  @override
  Description describe(Description description) {
    return description.add('is a valid email address');
  }
}
```

### Golden Test Helpers
```dart
// test/helpers/golden_test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'pump_app.dart';

extension GoldenTestHelper on WidgetTester {
  Future<void> pumpAppGolden(
    Widget widget, {
    String? name,
    Size? surfaceSize,
  }) async {
    await loadAppFonts();
    
    await pumpWidgetBuilder(
      widget,
      surfaceSize: surfaceSize ?? const Size(375, 812), // iPhone X size
      wrapper: materialAppWrapper(
        theme: ThemeData.light(),
        localizations: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      ),
    );
  }

  Future<void> expectGolden(String fileName) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$fileName.png'),
    );
  }
}

// Usage example:
// testGoldens('LoginPage golden test', (tester) async {
//   await tester.pumpAppGolden(const LoginPage());
//   await tester.expectGolden('login_page_initial');
// });
```

This comprehensive testing strategy ensures that your Flutter application is thoroughly tested at all levels, providing confidence in code quality, reliability, and maintainability. The testing approach follows industry best practices and integrates seamlessly with the VGV Clean Architecture pattern.
