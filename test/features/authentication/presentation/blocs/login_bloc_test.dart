import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignInWithGoogleUseCase extends Mock implements SignInWithGoogleUseCase {}
class MockSendPasswordResetEmailUseCase extends Mock implements SendPasswordResetEmailUseCase {}

void main() {
  late LoginBloc loginBloc;
  late MockSignInUseCase mockSignInUseCase;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockSendPasswordResetEmailUseCase mockSendPasswordResetEmailUseCase;

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockSendPasswordResetEmailUseCase = MockSendPasswordResetEmailUseCase();
    
    loginBloc = LoginBloc(
      signIn: mockSignInUseCase,
      signInWithGoogle: mockSignInWithGoogleUseCase,
      sendPasswordResetEmail: mockSendPasswordResetEmailUseCase,
    );
  });

  tearDown(() {
    loginBloc.close();
  });

  group('LoginBloc', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    final testUser = User(
      id: '1',
      email: testEmail,
      displayName: 'Test User',
      photoUrl: '',
      isEmailVerified: true,
      createdAt: DateTime.now(),
      customClaims: const {},
    );

    group('LoginRequested', () {
      test('should sanitize input before processing', () {
        // Test input sanitization
        const maliciousEmail = 'test@example.com<script>alert("xss")</script>';
        const maliciousPassword = 'password<script>alert("xss")</script>';
        
        final sanitizedEmail = SecurityUtils.sanitizeInput(maliciousEmail);
        final sanitizedPassword = SecurityUtils.sanitizeInput(maliciousPassword);
        
        expect(sanitizedEmail, equals('test@example.com'));
        expect(sanitizedPassword, equals('password'));
      });

      blocTest<LoginBloc, LoginState>(
        'emits [loading, success] when login is successful',
        setUp: () {
          when(() => mockSignInUseCase(any()))
              .thenAnswer((_) async => const Right(testUser));
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const LoginRequested(email: testEmail, password: testPassword),
        ),
        expect: () => [
          const LoginState(status: LoginStatus.loading),
          const LoginState(
            status: LoginStatus.success,
            failedAttempts: 0,
            showCaptcha: false,
            isRateLimited: false,
          ),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'emits [loading, failure] when login fails',
        setUp: () {
          when(() => mockSignInUseCase(any()))
              .thenAnswer((_) async => const Left(ServerFailure('Login failed')));
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const LoginRequested(email: testEmail, password: testPassword),
        ),
        expect: () => [
          const LoginState(status: LoginStatus.loading),
          const LoginState(
            status: LoginStatus.failure,
            errorMessage: 'Login failed',
            failedAttempts: 1,
            showCaptcha: false,
          ),
        ],
      );
    });

    group('PasswordStrengthChecked', () {
      blocTest<LoginBloc, LoginState>(
        'emits state with password strength',
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const PasswordStrengthChecked(password: 'Password123!'),
        ),
        expect: () => [
          const LoginState(passwordStrength: PasswordStrength.strong),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'emits state with weak password strength',
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const PasswordStrengthChecked(password: 'weak'),
        ),
        expect: () => [
          const LoginState(passwordStrength: PasswordStrength.weak),
        ],
      );
    });

    group('ForgotPasswordRequested', () {
      blocTest<LoginBloc, LoginState>(
        'sanitizes email input',
        setUp: () {
          when(() => mockSendPasswordResetEmailUseCase(any()))
              .thenAnswer((_) async => const Right(null));
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const ForgotPasswordRequested(email: 'test@example.com<script>alert("xss")</script>'),
        ),
        verify: (bloc) {
          verify(() => mockSendPasswordResetEmailUseCase('test@example.com')).called(1);
        },
      );
    });
  });

  group('SecurityUtils', () {
    test('validatePasswordStrength works correctly', () {
      expect(SecurityUtils.validatePasswordStrength('weak'), PasswordStrength.weak);
      expect(SecurityUtils.validatePasswordStrength('Password123'), PasswordStrength.medium);
      expect(SecurityUtils.validatePasswordStrength('Password123!@#'), PasswordStrength.strong);
    });

    test('sanitizeInput removes malicious content', () {
      const maliciousInput = 'test<script>alert("xss")</script>';
      final sanitized = SecurityUtils.sanitizeInput(maliciousInput);
      expect(sanitized, equals('test'));
    });

    test('isValidEmail validates email format', () {
      expect(SecurityUtils.isValidEmail('test@example.com'), isTrue);
      expect(SecurityUtils.isValidEmail('invalid-email'), isFalse);
      expect(SecurityUtils.isValidEmail(''), isFalse);
    });

    test('isRateLimited works correctly', () {
      const identifier = 'test-user';
      
      // Should not be rate limited initially
      expect(SecurityUtils.isRateLimited(identifier), isFalse);
      
      // Should be rate limited after max attempts
      for (int i = 0; i < 10; i++) {
        SecurityUtils.isRateLimited(identifier);
      }
      expect(SecurityUtils.isRateLimited(identifier), isTrue);
    });
  });
}
