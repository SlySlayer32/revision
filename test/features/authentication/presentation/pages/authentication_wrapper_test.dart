import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/authentication_wrapper.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';
import 'package:revision/features/dashboard/dashboard.dart';

class MockAuthenticationBloc extends Mock implements AuthenticationBloc {}

void main() {
  group('AuthenticationWrapper', () {
    late MockAuthenticationBloc mockAuthenticationBloc;

    setUp(() {
      mockAuthenticationBloc = MockAuthenticationBloc();
    });

    const testUser = User(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2023-01-01T00:00:00.000Z',
      customClaims: {},
    );

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: mockAuthenticationBloc,
          child: const AuthenticationWrapper(),
        ),
      );
    }

    testWidgets('should show loading indicator when status is unknown', (tester) async {
      // Arrange
      when(() => mockAuthenticationBloc.state)
          .thenReturn(const AuthenticationState.unknown());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show welcome page when unauthenticated', (tester) async {
      // Arrange
      when(() => mockAuthenticationBloc.state)
          .thenReturn(const AuthenticationState.unauthenticated());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('should show dashboard when authenticated', (tester) async {
      // Arrange
      when(() => mockAuthenticationBloc.state)
          .thenReturn(AuthenticationState.authenticated(testUser));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('should show error message when user is null but authenticated', (tester) async {
      // Arrange
      when(() => mockAuthenticationBloc.state)
          .thenReturn(const AuthenticationState.authenticated(null));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Authentication error: User is null'), findsOneWidget);
    });

    testWidgets('should handle rebuild when authentication status changes', (tester) async {
      // Arrange
      when(() => mockAuthenticationBloc.state)
          .thenReturn(const AuthenticationState.unknown());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Change state
      when(() => mockAuthenticationBloc.state)
          .thenReturn(const AuthenticationState.unauthenticated());

      // Trigger rebuild
      await tester.pump();

      // Assert
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}