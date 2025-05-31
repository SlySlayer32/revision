import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('GetCurrentUserUseCase', () {
    late GetCurrentUserUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = GetCurrentUserUseCase(mockRepository);
    });

    test('should return current user when user is signed in', () {
      // Arrange
      const user = User(id: '1', email: 'test@example.com');
      when(() => mockRepository.currentUser).thenReturn(user);

      // Act
      final result = useCase();

      // Assert
      expect(result, equals(user));
      verify(() => mockRepository.currentUser).called(1);
    });

    test('should return null when no user is signed in', () {
      // Arrange
      when(() => mockRepository.currentUser).thenReturn(null);

      // Act
      final result = useCase();

      // Assert
      expect(result, isNull);
      verify(() => mockRepository.currentUser).called(1);
    });
  });
}
