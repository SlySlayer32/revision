import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

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
      when(() => mockRepository.sendPasswordResetEmail(email))
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(const Success(null)));
      verify(() => mockRepository.sendPasswordResetEmail(email)).called(1);
    });
    test('should return failure when user not found', () async {
      // Arrange
      const exception = UserNotFoundException();
      when(() => mockRepository.sendPasswordResetEmail(email))
          .thenAnswer((_) async => Failure<void>(exception));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(Failure<void>(exception)));
      verify(() => mockRepository.sendPasswordResetEmail(email)).called(1);
    });
    test('should return failure when network error occurs', () async {
      // Arrange
      const exception = NetworkException();
      when(() => mockRepository.sendPasswordResetEmail(email))
          .thenAnswer((_) async => Failure<void>(exception));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(Failure<void>(exception)));
      verify(() => mockRepository.sendPasswordResetEmail(email)).called(1);
    });
    test('should return failure when unexpected error occurs', () async {
      // Arrange
      const exception = UnexpectedAuthException('Failed to send email');
      when(() => mockRepository.sendPasswordResetEmail(email))
          .thenAnswer((_) async => Failure<void>(exception));

      // Act
      final result = await useCase(email);

      // Assert
      expect(result, equals(Failure<void>(exception)));
      verify(() => mockRepository.sendPasswordResetEmail(email)).called(1);
    });
  });
}
