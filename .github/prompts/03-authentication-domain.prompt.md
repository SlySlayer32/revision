# Phase 2: Authentication Domain Layer (Test-First)

## Context & Requirements
Create the authentication domain layer using test-first development and VGV clean architecture. This layer must provide a secure, scalable foundation for user authentication with comprehensive error handling and support for multiple authentication providers.

**Critical Technical Requirements:**
- VGV clean architecture compliance (domain → data → presentation)
- Test-first development (write tests before implementation)
- Firebase Authentication integration
- Multiple auth providers (email/password, Google, Apple)
- Secure token management with automatic refresh
- Offline-first authentication state management
- Comprehensive error handling with user-friendly messages

## Exact Implementation Specifications

### 1. User Entity (Domain Model)
```dart
// lib/features/authentication/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.isEmailVerified,
    required this.createdAt,
    this.lastSignInAt,
    this.authProvider,
    this.preferences,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final AuthProvider? authProvider;
  final UserPreferences? preferences;

  /// Creates an anonymous user for testing
  factory User.anonymous() {
    return User(
      id: 'anonymous',
      email: '',
      isEmailVerified: false,
      createdAt: DateTime.now(),
      authProvider: AuthProvider.anonymous,
    );
  }

  /// Creates a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    AuthProvider? authProvider,
    UserPreferences? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      authProvider: authProvider ?? this.authProvider,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        phoneNumber,
        isEmailVerified,
        createdAt,
        lastSignInAt,
        authProvider,
        preferences,
      ];
}

enum AuthProvider {
  email('email'),
  google('google.com'),
  apple('apple.com'),
  anonymous('anonymous');

  const AuthProvider(this.providerId);
  final String providerId;
}

class UserPreferences extends Equatable {
  const UserPreferences({
    this.theme = AppTheme.system,
    this.language = 'en',
    this.aiProcessingQuality = AIQuality.high,
    this.autoSaveResults = true,
    this.enableAnalytics = true,
  });

  final AppTheme theme;
  final String language;
  final AIQuality aiProcessingQuality;
  final bool autoSaveResults;
  final bool enableAnalytics;

  @override
  List<Object?> get props => [
        theme,
        language,
        aiProcessingQuality,
        autoSaveResults,
        enableAnalytics,
      ];
}
```

### 2. Authentication Repository Interface
```dart
// lib/features/authentication/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  /// Gets the current authentication state
  Stream<User?> get authStateChanges;
  
  /// Gets the current user (null if not authenticated)
  Future<Either<Failure, User?>> getCurrentUser();
  
  /// Signs in with email and password
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  /// Signs up with email and password
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });
  
  /// Signs in with Google
  Future<Either<Failure, User>> signInWithGoogle();
  
  /// Signs in with Apple (iOS only)
  Future<Either<Failure, User>> signInWithApple();
  
  /// Signs out the current user
  Future<Either<Failure, void>> signOut();
  
  /// Sends password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });
  
  /// Sends email verification
  Future<Either<Failure, void>> sendEmailVerification();
  
  /// Updates user profile
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  });
  
  /// Updates user preferences
  Future<Either<Failure, User>> updatePreferences({
    required UserPreferences preferences,
  });
  
  /// Deletes the user account
  Future<Either<Failure, void>> deleteAccount();
  
  /// Re-authenticates user (required for sensitive operations)
  Future<Either<Failure, void>> reauthenticate({
    required String password,
  });
}
```

### 3. Authentication Exceptions
```dart
// lib/features/authentication/domain/exceptions/auth_exceptions.dart
import '../../../../core/error/exceptions.dart';

abstract class AuthException extends AppException {
  const AuthException(super.message, super.code);
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super(
          'An account already exists with this email address',
          'email-already-in-use',
        );
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super(
          'Password is too weak. Please use at least 8 characters with letters and numbers',
          'weak-password',
        );
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException()
      : super(
          'No account found with this email address',
          'user-not-found',
        );
}

class WrongPasswordException extends AuthException {
  const WrongPasswordException()
      : super(
          'Incorrect password. Please try again',
          'wrong-password',
        );
}

class InvalidEmailException extends AuthException {
  const InvalidEmailException()
      : super(
          'Please enter a valid email address',
          'invalid-email',
        );
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
      : super(
          'Too many failed attempts. Please try again later',
          'too-many-requests',
        );
}

class NetworkRequestFailedException extends AuthException {
  const NetworkRequestFailedException()
      : super(
          'Network error. Please check your connection',
          'network-request-failed',
        );
}

class UserDisabledException extends AuthException {
  const UserDisabledException()
      : super(
          'Your account has been disabled. Please contact support',
          'user-disabled',
        );
}

class OperationNotAllowedException extends AuthException {
  const OperationNotAllowedException()
      : super(
          'This operation is not allowed. Please contact support',
          'operation-not-allowed',
        );
}

class RequiresRecentLoginException extends AuthException {
  const RequiresRecentLoginException()
      : super(
          'Please sign in again to continue',
          'requires-recent-login',
        );
}

class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException()
      : super(
          'Google sign-in was cancelled',
          'google-sign-in-cancelled',
        );
}

class AppleSignInNotAvailableException extends AuthException {
  const AppleSignInNotAvailableException()
      : super(
          'Apple Sign-In is not available on this device',
          'apple-sign-in-not-available',
        );
}
```

### 4. Use Cases Implementation
```dart
// lib/features/authentication/domain/usecases/sign_in_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase implements UseCase<User, SignInParams> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Perform sign-in
    return _repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }

  ValidationFailure? _validateParams(SignInParams params) {
    if (params.email.isEmpty) {
      return const ValidationFailure('Email is required');
    }
    
    if (!_isValidEmail(params.email)) {
      return const ValidationFailure('Please enter a valid email address');
    }
    
    if (params.password.isEmpty) {
      return const ValidationFailure('Password is required');
    }
    
    if (params.password.length < 6) {
      return const ValidationFailure('Password must be at least 6 characters');
    }
    
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

class SignInParams extends Equatable {
  const SignInParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}
```

```dart
// lib/features/authentication/domain/usecases/sign_up_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<User, SignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Perform sign-up
    return _repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }

  ValidationFailure? _validateParams(SignUpParams params) {
    if (params.email.isEmpty) {
      return const ValidationFailure('Email is required');
    }
    
    if (!_isValidEmail(params.email)) {
      return const ValidationFailure('Please enter a valid email address');
    }
    
    if (params.password.isEmpty) {
      return const ValidationFailure('Password is required');
    }
    
    if (!_isStrongPassword(params.password)) {
      return const ValidationFailure(
        'Password must be at least 8 characters with letters and numbers',
      );
    }
    
    if (params.confirmPassword != params.password) {
      return const ValidationFailure('Passwords do not match');
    }
    
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    return true;
  }
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.displayName,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final String? displayName;

  @override
  List<Object?> get props => [email, password, confirmPassword, displayName];
}
```

### 5. Comprehensive Test Suite (Write These First!)
```dart
// test/features/authentication/domain/entities/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/authentication/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    const tUser = User(
      id: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      isEmailVerified: true,
      createdAt: DateTime(2024, 1, 1),
      authProvider: AuthProvider.email,
    );

    test('should be a subclass of Equatable', () {
      expect(tUser, isA<Equatable>());
    });

    test('should support value equality', () {
      const tUser2 = User(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        isEmailVerified: true,
        createdAt: DateTime(2024, 1, 1),
        authProvider: AuthProvider.email,
      );

      expect(tUser, equals(tUser2));
    });

    test('should create anonymous user correctly', () {
      final anonymousUser = User.anonymous();
      
      expect(anonymousUser.id, equals('anonymous'));
      expect(anonymousUser.email, equals(''));
      expect(anonymousUser.isEmailVerified, isFalse);
      expect(anonymousUser.authProvider, equals(AuthProvider.anonymous));
    });

    test('copyWith should return updated user', () {
      final updatedUser = tUser.copyWith(
        displayName: 'Updated Name',
        isEmailVerified: false,
      );

      expect(updatedUser.id, equals(tUser.id));
      expect(updatedUser.email, equals(tUser.email));
      expect(updatedUser.displayName, equals('Updated Name'));
      expect(updatedUser.isEmailVerified, isFalse);
    });
  });
}
```

```dart
// test/features/authentication/domain/usecases/sign_in_usecase_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/core/error/failures.dart';
import 'package:ai_photo_editor/features/authentication/domain/entities/user.dart';
import 'package:ai_photo_editor/features/authentication/domain/repositories/auth_repository.dart';
import 'package:ai_photo_editor/features/authentication/domain/usecases/sign_in_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tParams = SignInParams(email: tEmail, password: tPassword);
  
  const tUser = User(
    id: '123',
    email: tEmail,
    isEmailVerified: true,
    createdAt: DateTime(2024, 1, 1),
    authProvider: AuthProvider.email,
  );

  group('SignInUseCase', () {
    test('should return User when sign-in is successful', () async {
      // arrange
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(tUser));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, equals(const Right(tUser)));
      verify(() => mockAuthRepository.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          )).called(1);
    });

    test('should return ValidationFailure when email is empty', () async {
      // arrange
      const tInvalidParams = SignInParams(email: '', password: tPassword);

      // act
      final result = await usecase(tInvalidParams);

      // assert
      expect(result, isA<Left<Failure, User>>());
      expect(
        result.fold((l) => l, (r) => null),
        isA<ValidationFailure>(),
      );
      verifyNever(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('should return ValidationFailure when email format is invalid', () async {
      // arrange
      const tInvalidParams = SignInParams(email: 'invalid-email', password: tPassword);

      // act
      final result = await usecase(tInvalidParams);

      // assert
      expect(result, isA<Left<Failure, User>>());
      expect(
        result.fold((l) => l.message, (r) => ''),
        contains('valid email'),
      );
    });

    test('should return ValidationFailure when password is too short', () async {
      // arrange
      const tInvalidParams = SignInParams(email: tEmail, password: '123');

      // act
      final result = await usecase(tInvalidParams);

      // assert
      expect(result, isA<Left<Failure, User>>());
      expect(
        result.fold((l) => l.message, (r) => ''),
        contains('6 characters'),
      );
    });

    test('should return AuthenticationFailure when repository fails', () async {
      // arrange
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(AuthenticationFailure('Sign-in failed')));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, isA<Left<Failure, User>>());
      expect(
        result.fold((l) => l, (r) => null),
        isA<AuthenticationFailure>(),
      );
    });
  });
}
```

### 6. Core Infrastructure for Authentication
```dart
// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
```

```dart
// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);
  
  final String message;
  
  @override
  List<Object> get props => [message];
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
```

## Acceptance Criteria (Must All Pass)
1. ✅ All domain entities are immutable and extend Equatable
2. ✅ Repository interface defines complete authentication contract
3. ✅ Use cases have comprehensive input validation
4. ✅ All exceptions provide user-friendly error messages
5. ✅ Test coverage is 100% for domain layer
6. ✅ Email validation handles all edge cases
7. ✅ Password strength validation meets security requirements
8. ✅ Error handling covers all authentication scenarios
9. ✅ Code follows VGV naming and structure conventions
10. ✅ No platform-specific code in domain layer

**Implementation Priority:** Write ALL tests first, then implement to make tests pass

**Quality Gate:** All tests must pass before proceeding to data layer

**Test Coverage Target:** 100% for domain layer (entities, use cases, contracts)

---

**Next Step:** After all tests pass, proceed to Authentication Data Layer (Phase 2, Step 4)
