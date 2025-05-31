import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('SignInUseCase', () {
    late SignInUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = SignInUseCase(mockRepository);
    });

    const email = 'test@example.com';
    const password = 'password123';
    const user = User(id: '1', email: email);

    test('should sign in user when credentials are valid', () async {
      // Arrange
      when(
        () => mockRepository.signIn(
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
        () => mockRepository.signIn(
          email: email,
          password: password,
        ),
      ).called(1);
    });
    test('should return failure when credentials are invalid', () async {
      // Arrange
      const exception = InvalidCredentialsException();
      when(
        () => mockRepository.signIn(
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
        () => mockRepository.signIn(
          email: email,
          password: password,
        ),
      ).called(1);
    });
    test('should return failure when network error occurs', () async {
      // Arrange
      const exception = NetworkException();
      when(
        () => mockRepository.signIn(
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
        () => mockRepository.signIn(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });
}
