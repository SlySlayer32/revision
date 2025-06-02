import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SignUpUseCase', () {
    late SignUpUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignUpUseCase(mockRepository);
    });

    const email = 'test@example.com';
    const password = 'password123';
    const user = User(
      id: '1',
      email: email,
      displayName: null,
      photoUrl: null,
      isEmailVerified: false,
      createdAt: '2023-01-01T00:00:00Z',
      customClaims: {},
    );

    test('should create user when email and password are valid', () async {
      // Arrange
      when(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => const Right(user));

      // Act
      final result = await useCase(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(const Right(user)));
      verify(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });

    test('should return failure when email is already in use', () async {
      // Arrange
      const failure = Failure('Email already in use');
      when(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });

    test('should return failure when password is weak', () async {
      // Arrange
      const failure = Failure('Password is too weak');
      when(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: 'weak',
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        email: email,
        password: 'weak',
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: 'weak',
        ),
      ).called(1);
    });

    test('should return failure when network error occurs', () async {
      // Arrange
      const failure = Failure('Network error');
      when(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(const Left(failure)));
      verify(
        () => mockRepository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });
}
