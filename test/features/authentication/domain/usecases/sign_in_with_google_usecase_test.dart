import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';

class MockAuthenticationRepository extends Mock implements AuthRepository {}

void main() {
  group('SignInWithGoogleUseCase', () {
    late SignInWithGoogleUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = SignInWithGoogleUseCase(mockRepository);
    });

    const tUser = User(
      id: '1',
      email: 'test@gmail.com',
      displayName: 'John Doe',
      photoUrl: 'https://example.com/photo.jpg',
      isEmailVerified: true, // Assuming Google sign-in implies verified email
      createdAt: '2023-01-01T00:00:00Z',
      customClaims: <String, dynamic>{},
    );

    test('should sign in user with Google successfully', () async {
      // Arrange
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Right<Failure, User>(tUser));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, User>(tUser)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('should return failure when Google sign in is cancelled', () async {
      // Arrange
      const tFailure = AuthenticationFailure('Google sign in cancelled');
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Left<Failure, User>(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Left<Failure, User>(tFailure)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('should return failure when network error occurs', () async {
      // Arrange
      const tFailure = NetworkFailure('Network error');
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Left<Failure, User>(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Left<Failure, User>(tFailure)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('should return failure when Google sign in fails', () async {
      // Arrange
      const tFailure = AuthenticationFailure('Google sign in failed');
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Left<Failure, User>(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Left<Failure, User>(tFailure)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
  });
}
