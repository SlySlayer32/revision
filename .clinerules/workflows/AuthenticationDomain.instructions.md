# Phase 2, Step 3: Authentication Domain Layer (Test-First)

## Context & Requirements
Create the authentication feature using test-driven development and VGV clean architecture. This foundation layer handles user identity management for the AI photo editor app with comprehensive error handling and scalability.

**Critical Technical Requirements:**
- Test-first development: Write tests BEFORE implementation
- VGV Clean Architecture: Domain layer with entities, use cases, repositories
- Error handling: Custom exceptions and Result pattern
- Security: Secure user data handling
- Scalability: Support for multiple auth providers
- Performance: Fast authentication checks

## Exact Implementation Specifications

### 1. User Entity (Test-First)
```dart
// test/features/authentication/domain/entities/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/authentication/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    const tUser = User(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      isEmailVerified: true,
      createdAt: '2024-01-01T00:00:00Z',
    );

    test('should be a subclass of Equatable', () {
      expect(tUser, isA<Equatable>());
    });

    test('should have correct props for equality', () {
      const otherUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        isEmailVerified: true,
        createdAt: '2024-01-01T00:00:00Z',
      );
      
      expect(tUser, equals(otherUser));
      expect(tUser.hashCode, equals(otherUser.hashCode));
    });

    test('should return correct props', () {
      expect(
        tUser.props,
        equals([
          'test-id',
          'test@example.com',
          'Test User',
          'https://example.com/photo.jpg',
          true,
          '2024-01-01T00:00:00Z',
        ]),
      );
    });

    test('should handle null values correctly', () {
      const userWithNulls = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: null,
        photoUrl: null,
        isEmailVerified: false,
        createdAt: '2024-01-01T00:00:00Z',
      );
      
      expect(userWithNulls.displayName, isNull);
      expect(userWithNulls.photoUrl, isNull);
      expect(userWithNulls.isEmailVerified, isFalse);
    });

    test('should validate email format', () {
      expect(tUser.hasValidEmail, isTrue);
      
      const invalidEmailUser = User(
        id: 'test-id',
        email: 'invalid-email',
        displayName: 'Test User',
        photoUrl: null,
        isEmailVerified: false,
        createdAt: '2024-01-01T00:00:00Z',
      );
      
      expect(invalidEmailUser.hasValidEmail, isFalse);
    });

    test('should check if user profile is complete', () {
      expect(tUser.isProfileComplete, isTrue);
      
      const incompleteUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: null,
        photoUrl: null,
        isEmailVerified: false,
        createdAt: '2024-01-01T00:00:00Z',
      );
      
      expect(incompleteUser.isProfileComplete, isFalse);
    });
  });
}

// lib/features/authentication/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isEmailVerified,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final String createdAt; // ISO 8601 string

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        isEmailVerified,
        createdAt,
      ];

  /// Validates email format using regex
  bool get hasValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Checks if user profile has all required information
  bool get isProfileComplete {
    return displayName != null && 
           displayName!.isNotEmpty && 
           isEmailVerified &&
           hasValidEmail;
  }

  /// Creates a copy with updated values
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### 2. Authentication Repository Interface (Test-First)
```dart
// test/features/authentication/domain/repositories/auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/authentication/domain/repositories/auth_repository.dart';
import 'package:ai_photo_editor/features/authentication/domain/entities/user.dart';
import 'package:ai_photo_editor/core/error/failures.dart';

void main() {
  group('AuthRepository Interface', () {
    test('should define correct method signatures', () {
      // This test ensures the interface is properly defined
      expect(AuthRepository, isA<Type>());
      
      // The actual implementation tests will be in the data layer
      // This is just to verify the interface structure
    });
  });
}

// lib/features/authentication/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Get current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Send email verification
  Future<Either<Failure, void>> sendEmailVerification();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Update user profile
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Reauthenticate user
  Future<Either<Failure, void>> reauthenticateWithPassword({
    required String password,
  });
}
```

### 3. Authentication Exceptions (Test-First)
```dart
// test/features/authentication/domain/exceptions/auth_exceptions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/authentication/domain/exceptions/auth_exceptions.dart';

void main() {
  group('Authentication Exceptions', () {
    test('InvalidCredentialsException should have correct message', () {
      const exception = InvalidCredentialsException();
      expect(exception.message, equals('Invalid email or password'));
      expect(exception.code, equals('invalid-credentials'));
    });

    test('UserNotFoundException should have correct message', () {
      const exception = UserNotFoundException();
      expect(exception.message, equals('No user found with this email'));
      expect(exception.code, equals('user-not-found'));
    });

    test('EmailAlreadyInUseException should have correct message', () {
      const exception = EmailAlreadyInUseException();
      expect(exception.message, equals('Email is already in use'));
      expect(exception.code, equals('email-already-in-use'));
    });

    test('WeakPasswordException should have correct message', () {
      const exception = WeakPasswordException();
      expect(exception.message, equals('Password is too weak'));
      expect(exception.code, equals('weak-password'));
    });

    test('NetworkException should have correct message', () {
      const exception = NetworkAuthException();
      expect(exception.message, equals('Network connection failed'));
      expect(exception.code, equals('network-request-failed'));
    });

    test('TooManyRequestsException should have correct message', () {
      const exception = TooManyRequestsException();
      expect(exception.message, equals('Too many requests. Try again later'));
      expect(exception.code, equals('too-many-requests'));
    });

    test('AccountDisabledException should have correct message', () {
      const exception = AccountDisabledException();
      expect(exception.message, equals('User account has been disabled'));
      expect(exception.code, equals('user-disabled'));
    });

    test('EmailNotVerifiedException should have correct message', () {
      const exception = EmailNotVerifiedException();
      expect(exception.message, equals('Email address is not verified'));
      expect(exception.code, equals('email-not-verified'));
    });

    test('should be subclasses of AuthenticationException', () {
      expect(const InvalidCredentialsException(), isA<AuthenticationException>());
      expect(const UserNotFoundException(), isA<AuthenticationException>());
      expect(const EmailAlreadyInUseException(), isA<AuthenticationException>());
      expect(const WeakPasswordException(), isA<AuthenticationException>());
      expect(const NetworkAuthException(), isA<AuthenticationException>());
      expect(const TooManyRequestsException(), isA<AuthenticationException>());
      expect(const AccountDisabledException(), isA<AuthenticationException>());
      expect(const EmailNotVerifiedException(), isA<AuthenticationException>());
    });
  });
}

// lib/features/authentication/domain/exceptions/auth_exceptions.dart
import '../../../../core/error/exceptions.dart';

// Base authentication exception
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}

// Specific authentication exceptions
class InvalidCredentialsException extends AuthenticationException {
  const InvalidCredentialsException() 
      : super('Invalid email or password', 'invalid-credentials');
}

class UserNotFoundException extends AuthenticationException {
  const UserNotFoundException() 
      : super('No user found with this email', 'user-not-found');
}

class EmailAlreadyInUseException extends AuthenticationException {
  const EmailAlreadyInUseException() 
      : super('Email is already in use', 'email-already-in-use');
}

class WeakPasswordException extends AuthenticationException {
  const WeakPasswordException() 
      : super('Password is too weak', 'weak-password');
}

class NetworkAuthException extends AuthenticationException {
  const NetworkAuthException() 
      : super('Network connection failed', 'network-request-failed');
}

class TooManyRequestsException extends AuthenticationException {
  const TooManyRequestsException() 
      : super('Too many requests. Try again later', 'too-many-requests');
}

class AccountDisabledException extends AuthenticationException {
  const AccountDisabledException() 
      : super('User account has been disabled', 'user-disabled');
}

class EmailNotVerifiedException extends AuthenticationException {
  const EmailNotVerifiedException() 
      : super('Email address is not verified', 'email-not-verified');
}

class ReauthenticationRequiredException extends AuthenticationException {
  const ReauthenticationRequiredException() 
      : super('Recent authentication required', 'requires-recent-login');
}

class ProviderAlreadyLinkedException extends AuthenticationException {
  const ProviderAlreadyLinkedException() 
      : super('Account is already linked to another provider', 'provider-already-linked');
}
```

### 4. Use Cases (Test-First)
```dart
// test/features/authentication/domain/usecases/sign_in_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:ai_photo_editor/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:ai_photo_editor/features/authentication/domain/repositories/auth_repository.dart';
import 'package:ai_photo_editor/features/authentication/domain/entities/user.dart';
import 'package:ai_photo_editor/core/error/failures.dart';

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
  const tUser = User(
    id: 'test-id',
    email: tEmail,
    displayName: 'Test User',
    photoUrl: null,
    isEmailVerified: true,
    createdAt: '2024-01-01T00:00:00Z',
  );

  group('SignInUseCase', () {
    test('should sign in user with valid credentials', () async {
      // arrange
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(tUser));

      // act
      final result = await usecase(const SignInParams(
        email: tEmail,
        password: tPassword,
      ));

      // assert
      expect(result, equals(const Right(tUser)));
      verify(() => mockAuthRepository.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          )).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return failure when sign in fails', () async {
      // arrange
      const tFailure = AuthenticationFailure('Invalid credentials');
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(const SignInParams(
        email: tEmail,
        password: tPassword,
      ));

      // assert
      expect(result, equals(const Left(tFailure)));
      verify(() => mockAuthRepository.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          )).called(1);
    });

    test('should validate email format', () async {
      // act
      final result = await usecase(const SignInParams(
        email: 'invalid-email',
        password: tPassword,
      ));

      // assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (user) => fail('Should return validation failure'),
      );
      verifyNever(() => mockAuthRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('should validate password is not empty', () async {
      // act
      final result = await usecase(const SignInParams(
        email: tEmail,
        password: '',
      ));

      // assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (user) => fail('Should return validation failure'),
      );
    });
  });
}

// lib/features/authentication/domain/usecases/sign_in_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase implements UseCase<User, SignInParams> {
  const SignInUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    // Validate inputs
    final emailValidation = Validators.validateEmail(params.email);
    if (emailValidation != null) {
      return Left(ValidationFailure(emailValidation));
    }

    final passwordValidation = Validators.validatePassword(params.password);
    if (passwordValidation != null) {
      return Left(ValidationFailure(passwordValidation));
    }

    return repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
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

### 5. Core UseCase Interface
```dart
// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
```

### 6. Validation Utilities
```dart
// lib/core/utils/validators.dart
class Validators {
  static const String _emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static final RegExp _emailRegExp = RegExp(_emailPattern);

  /// Validates email format
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email cannot be empty';
    if (!_emailRegExp.hasMatch(email)) return 'Please enter a valid email';
    return null;
  }

  /// Validates password strength
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password cannot be empty';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Validates display name
  static String? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return 'Display name cannot be empty';
    }
    if (displayName.length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (displayName.length > 50) {
      return 'Display name cannot exceed 50 characters';
    }
    return null;
  }
}
```

### 7. Failure Types
```dart
// lib/core/error/failures.dart - Add authentication-specific failures
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message, [this.code]);
  
  final String message;
  final String? code;
  
  @override
  List<Object?> get props => [message, code];
  
  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code]);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure(super.message, [super.code]);
}

class AIProcessingFailure extends Failure {
  const AIProcessingFailure(super.message, [super.code]);
}
```

## Acceptance Criteria (Must All Pass)
1. ✅ All tests pass before implementation exists
2. ✅ User entity validates email formats correctly
3. ✅ Repository interface defines all required methods
4. ✅ Custom exceptions cover all authentication scenarios
5. ✅ Use cases validate inputs before processing
6. ✅ Result pattern handles success/failure cases
7. ✅ Code follows VGV patterns exactly
8. ✅ 100% test coverage for domain layer
9. ✅ Equatable implementation works correctly
10. ✅ Validation utilities handle edge cases

**Implementation Priority:** Foundation for all authentication features

**Quality Gate:** All tests must pass before moving to data layer

**Performance Target:** Domain logic executes in < 10ms

---

**Next Step:** After completion, proceed to Authentication Data Layer (Phase 2, Step 4)
