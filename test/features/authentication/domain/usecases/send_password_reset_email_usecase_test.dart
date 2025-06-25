import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';

class MockAuthenticationRepository extends Mock implements AuthRepository {}

void main() {
  group('SendPasswordResetEmailUseCase', () {
    late SendPasswordResetEmailUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = SendPasswordResetEmailUseCase(mockRepository);
    });

    const email = 'test@example.com';

    test('should send password reset email successfully', () async {
      // Arrange
      when(() => mockRepository.sendPasswordResetEmail(email: email))
          .thenAnswer((_) async => const Right<Failure, void>(null));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockRepository.sendPasswordResetEmail(email: email))
          .called(1);
    });

    test('should return failure when user not found (AuthenticationFailure)',
        () async {
      // Arrange
      const failure = AuthenticationFailure('User not found');
      when(() => mockRepository.sendPasswordResetEmail(email: email))
          .thenAnswer((_) async => const Left<Failure, void>(failure));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(const Left<Failure, void>(failure)));
      verify(() => mockRepository.sendPasswordResetEmail(email: email))
          .called(1);
    });

    test('should return failure when network error occurs (NetworkFailure)',
        () async {
      // Arrange
      const failure = NetworkFailure('Network error');
      when(() => mockRepository.sendPasswordResetEmail(email: email))
          .thenAnswer((_) async => const Left<Failure, void>(failure));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(const Left<Failure, void>(failure)));
      verify(() => mockRepository.sendPasswordResetEmail(email: email))
          .called(1);
    });

    test(
        'should return failure when unexpected error occurs (AuthenticationFailure)',
        () async {
      // Arrange
      const failure = AuthenticationFailure('Failed to send email');
      when(() => mockRepository.sendPasswordResetEmail(email: email))
          .thenAnswer((_) async => const Left<Failure, void>(failure));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(const Left<Failure, void>(failure)));
      verify(() => mockRepository.sendPasswordResetEmail(email: email))
          .called(1);
    });
  });
}
