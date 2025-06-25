import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = User(
    id: 'test-id',
    email: tEmail,
    displayName: 'Test User',
    photoUrl: null,
    isEmailVerified: true,
    createdAt: '2024-01-01T00:00:00Z',
    customClaims: <String, dynamic>{},
  );

  group('SignInUseCase', () {
    test('should sign in user with valid credentials', () async {
      // arrange
      when(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right<Failure, User>(tUser));

      // act
      final result = await usecase(
        const SignInParams(
          email: tEmail,
          password: tPassword,
        ),
      );

      // assert
      expect(
        result,
        equals(const Right<Failure, User>(tUser)),
      );
      verify(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return failure when sign in fails', () async {
      // arrange
      const tFailure = AuthenticationFailure('Invalid credentials');
      when(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left<Failure, User>(tFailure));

      // act
      final result = await usecase(
        const SignInParams(
          email: tEmail,
          password: tPassword,
        ),
      );

      // assert
      expect(
        result,
        equals(const Left<Failure, User>(tFailure)),
      );
      verify(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test('should validate email format', () async {
      // act
      final result = await usecase(
        const SignInParams(
          email: 'invalid-email',
          password: tPassword,
        ),
      );

      // assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (user) => fail('Should return validation failure'),
      );
      verifyNever(
        () => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('should validate password is not empty', () async {
      // act
      final result = await usecase(
        const SignInParams(
          email: tEmail,
          password: '',
        ),
      );

      // assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (user) => fail('Should return validation failure'),
      );
    });
  });
}
