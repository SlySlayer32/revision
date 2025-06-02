import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('SignInWithGoogleUseCase', () {
    late SignInWithGoogleUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = SignInWithGoogleUseCase(mockRepository);
    });

    const user = User(
      id: '1',
      email: 'test@gmail.com',
      displayName: 'John Doe',
      photoUrl: 'https://example.com/photo.jpg',
      isEmailVerified: true, // Assuming Google sign-in implies verified email
      createdAt: '2023-01-01T00:00:00Z',
      customClaims: {},
    );

    test('should sign in user with Google successfully', () async {
      // Arrange
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Success(user));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Success(user)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
    test('should return failure when Google sign in is cancelled', () async {
      // Arrange
      const exception = UnexpectedAuthException('Google sign in cancelled');
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Failure<User>(exception));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Failure<User>(exception)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
    test('should return failure when network error occurs', () async {
      // Arrange
      const exception = NetworkException();
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Failure<User>(exception));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Failure<User>(exception)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
    test('should return failure when Google sign in fails', () async {
      // Arrange
      const exception = UnexpectedAuthException('Google sign in failed');
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Failure<User>(exception));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Failure<User>(exception)));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
  });
}
