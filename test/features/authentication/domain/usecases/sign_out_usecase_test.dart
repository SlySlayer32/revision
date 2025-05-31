import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('SignOutUseCase', () {
    late SignOutUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = SignOutUseCase(mockRepository);
    });

    test('should sign out user successfully', () async {
      // Arrange
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Success(null)));
      verify(() => mockRepository.signOut()).called(1);
    });
    test('should return failure when sign out fails', () async {
      // Arrange
      const exception = UnexpectedAuthException('Sign out failed');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => Failure<void>(exception));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(Failure<void>(exception)));
      verify(() => mockRepository.signOut()).called(1);
    });
    test('should return failure when network error occurs', () async {
      // Arrange
      const exception = NetworkException();
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => Failure<void>(exception));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(Failure<void>(exception)));
      verify(() => mockRepository.signOut()).called(1);
    });
  });
}
