import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('SignUpUseCase', () {
    late SignUpUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = SignUpUseCase(mockRepository);
    });

    const email = 'test@example.com';
    const password = 'password123';
    const user = User(id: '1', email: email);

    test('should create user when email and password are valid', () async {
      // Arrange
      when(
        () => mockRepository.signUp(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => const Success(user));

      // Act
      final result = await useCase(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(const Success(user)));
      verify(
        () => mockRepository.signUp(
          email: email,
          password: password,
        ),
      ).called(1);
    });
    test('should return failure when email is already in use', () async {
      // Arrange
      const exception = EmailAlreadyInUseException();
      when(
        () => mockRepository.signUp(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => Failure<User>(exception));

      // Act
      final result = await useCase(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(Failure<User>(exception)));
      verify(
        () => mockRepository.signUp(
          email: email,
          password: password,
        ),
      ).called(1);
    });

    test('should return failure when password is weak', () async {
      // Arrange
      const exception = WeakPasswordException();
      when(
        () => mockRepository.signUp(
          email: email,
          password: 'weak',
        ),
      ).thenAnswer((_) async => Failure<User>(exception));

      // Act
      final result = await useCase(
        email: email,
        password: 'weak',
      );

      // Assert
      expect(result, equals(Failure<User>(exception)));
      verify(
        () => mockRepository.signUp(
          email: email,
          password: 'weak',
        ),
      ).called(1);
    });
    test('should return failure when network error occurs', () async {
      // Arrange
      const exception = NetworkException();
      when(
        () => mockRepository.signUp(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => Failure<User>(exception));

      // Act
      final result = await useCase(
        email: email,
        password: password,
      );

      // Assert
      expect(result, equals(Failure<User>(exception)));
      verify(
        () => mockRepository.signUp(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });
}
