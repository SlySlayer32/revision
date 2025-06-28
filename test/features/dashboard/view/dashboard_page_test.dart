import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/dashboard/view/dashboard_page.dart';
import 'package:user_repository/user_repository.dart';

class MockAuthenticationBloc extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

class MockUser extends Mock implements User {}

void main() {
  group('DashboardPage', () {
    late AuthenticationBloc authenticationBloc;
    late User user;

    setUp(() {
      authenticationBloc = MockAuthenticationBloc();
      user = MockUser();
      when(() => user.email).thenReturn('test@example.com');
    });

    testWidgets('renders DashboardView', (tester) async {
      when(() => authenticationBloc.state).thenReturn(
        AuthenticationState.authenticated(user),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authenticationBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      expect(find.byType(DashboardView), findsOneWidget);
    });

    testWidgets('displays user email in app bar', (tester) async {
      when(() => authenticationBloc.state).thenReturn(
        AuthenticationState.authenticated(user),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authenticationBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      expect(find.text('Revision Dashboard'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('displays logout button', (tester) async {
      when(() => authenticationBloc.state).thenReturn(
        AuthenticationState.authenticated(user),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authenticationBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      // Find the PopupMenuButton
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      expect(popupMenuButton, findsOneWidget);

      // Tap to open the popup menu
      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      // Check that logout option is present
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('displays dashboard content sections', (tester) async {
      when(() => authenticationBloc.state).thenReturn(
        AuthenticationState.authenticated(user),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authenticationBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      // Check for welcome section
      expect(find.text('Welcome back!'), findsOneWidget);
      
      // Check for system status section
      expect(find.text('System Status'), findsOneWidget);
      expect(find.text('Authentication'), findsOneWidget);
      expect(find.text('AI Services'), findsOneWidget);
      
      // Check for available tools section
      expect(find.text('Available Tools'), findsOneWidget);
    });

    testWidgets('triggers logout when logout is selected', (tester) async {
      when(() => authenticationBloc.state).thenReturn(
        AuthenticationState.authenticated(user),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authenticationBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      // Find and tap the PopupMenuButton
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      // Tap the logout option
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify that logout event was added
      verify(() => authenticationBloc.add(const AuthenticationLogoutRequested())).called(1);
    });
  });
}
