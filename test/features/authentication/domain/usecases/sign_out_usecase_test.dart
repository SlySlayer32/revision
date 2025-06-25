import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';

class MockAuthenticationRepository extends Mock implements AuthRepository {}

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
          .thenAnswer((_) async => const Right<Failure, void>(null));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockRepository.signOut()).called(1);
    });

    test('should return failure when sign out fails', () async {
      // Arrange
      const tFailure = AuthenticationFailure('Sign out failed');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const Left<Failure, void>(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Left<Failure, void>(tFailure)));
      verify(() => mockRepository.signOut()).called(1);
    });

    test('should return failure when network error occurs', () async {
      // Arrange
      const tFailure = NetworkFailure('Network error');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const Left<Failure, void>(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Left<Failure, void>(tFailure)));
      verify(() => mockRepository.signOut()).called(1);
    });
  });
}
