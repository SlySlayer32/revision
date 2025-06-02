import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_with_claims_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('GetCurrentUserWithClaimsUseCase', () {
    late GetCurrentUserWithClaimsUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = GetCurrentUserWithClaimsUseCase(mockRepository);
    });

    const user = User(
      id: '1',
      email: 'test@example.com',
      displayName: 'Admin User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2023-01-01T00:00:00Z',
      customClaims: {'role': 'admin', 'premium': true},
    );
    test('should return user with custom claims when successful', () async {
      // Arrange
      when(() => mockRepository.getCurrentUserWithClaims())
          .thenAnswer((_) async => const Success(user));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Success<User?>(user)));
      verify(() => mockRepository.getCurrentUserWithClaims()).called(1);
    });

    test('should return null when no user is authenticated', () async {
      // Arrange
      when(() => mockRepository.getCurrentUserWithClaims())
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Success<User?>(null)));
      verify(() => mockRepository.getCurrentUserWithClaims()).called(1);
    });
    test('should return failure when repository throws exception', () async {
      // Arrange
      const exception =
          UnexpectedAuthException('Failed to get user with claims');
      when(() => mockRepository.getCurrentUserWithClaims())
          .thenAnswer((_) async => const Failure(exception));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Failure<User?>(exception)));
      verify(() => mockRepository.getCurrentUserWithClaims()).called(1);
    });
    test('should return user with empty claims when user has no custom claims',
        () async {
      // Arrange
      const userWithoutClaims = User(
        id: '1',
        email: 'test@example.com',
        displayName: 'Regular User',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-02T00:00:00Z',
        customClaims: {},
      );
      when(() => mockRepository.getCurrentUserWithClaims())
          .thenAnswer((_) async => const Success(userWithoutClaims));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Success<User?>(userWithoutClaims)));
      verify(() => mockRepository.getCurrentUserWithClaims()).called(1);
    });
  });
}
