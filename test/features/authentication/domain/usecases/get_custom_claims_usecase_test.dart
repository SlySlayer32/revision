import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_custom_claims_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('GetCustomClaimsUseCase', () {
    late GetCustomClaimsUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = GetCustomClaimsUseCase(mockRepository);
    });
    test('should return custom claims when successful', () async {
      // Arrange
      const customClaims = {'role': 'admin', 'premium': true};
      when(() => mockRepository.getCustomClaims())
          .thenAnswer((_) async => const Success(customClaims));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Success<Map<String, dynamic>>(customClaims)));
      verify(() => mockRepository.getCustomClaims()).called(1);
    });
    test('should return failure when repository throws exception', () async {
      // Arrange
      const exception = UnexpectedAuthException('Failed to get custom claims');
      when(() => mockRepository.getCustomClaims())
          .thenAnswer((_) async => const Failure(exception));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Failure<Map<String, dynamic>>(exception)));
      verify(() => mockRepository.getCustomClaims()).called(1);
    });
    test('should return empty claims when user has no custom claims', () async {
      // Arrange
      const emptyClaims = <String, dynamic>{};
      when(() => mockRepository.getCustomClaims())
          .thenAnswer((_) async => const Success(emptyClaims));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Success<Map<String, dynamic>>(emptyClaims)));
      verify(() => mockRepository.getCustomClaims()).called(1);
    });
  });
}
