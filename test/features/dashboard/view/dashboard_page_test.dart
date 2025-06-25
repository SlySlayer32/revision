import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/dashboard/view/dashboard_page.dart';

import '../../../helpers/helpers.dart';

void main() {
  group('DashboardPage', () {
    late MockAuthenticationBloc mockAuthenticationBloc;

    setUp(() {
      mockAuthenticationBloc = MockAuthenticationBloc();
    });

    // A sample user for tests, created using VGVTestDataFactory
    // Ensure VGVTestDataFactory is imported, likely via helpers.dart
    final tUser = VGVTestDataFactory.createTestUser(
      email: 'test@example.com',
      id: 'dashboard-user',
      displayName: 'Dashboard User', // Default display name
    );
    final tUserNoName = VGVTestDataFactory.createTestUser(
      email: 'noname@example.com',
      id: 'no-name-user',
    );

    group('when user is authenticated', () {
      testWidgets('renders dashboard with welcome message', (tester) async {
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(tUser),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        expect(find.text('Revision Dashboard'), findsOneWidget);
        expect(find.text('Welcome back!'), findsOneWidget);
        expect(find.text(tUser.email), findsOneWidget);
      });

      testWidgets('displays tools grid with coming soon features',
          (tester) async {
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(tUser),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        expect(find.text('Available Tools'), findsOneWidget);
        expect(find.text('AI Object Removal'), findsOneWidget);
        expect(find.text('Background Editor'), findsOneWidget);
        expect(find.text('Smart Enhance'), findsOneWidget);
        expect(find.text('Batch Processing'), findsOneWidget);
      });

      testWidgets('shows status cards with authentication active',
          (tester) async {
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(tUser),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        expect(find.text('Authentication'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('AI Services'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);
      });

      testWidgets('shows coming soon dialog when tapping a tool',
          (tester) async {
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(tUser),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        // Tap on AI Object Removal tool
        await tester.tap(find.text('AI Object Removal'));
        await tester.pumpAndSettle();

        expect(find.text('Coming Soon'), findsOneWidget);
        expect(find.text('Got it'), findsOneWidget);
      });

      testWidgets('logout works when tapping logout in profile menu',
          (tester) async {
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(tUser),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        // Find and tap the profile avatar
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap logout
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Verify that the logout event was added
        verify(
          () => mockAuthenticationBloc.add(AuthenticationLogoutRequested()),
        ).called(1);
      });
    });

    group('edge cases', () {
      testWidgets('handles user with missing display name', (tester) async {
        // Uses tUserNoName defined above which has displayName: null
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(tUserNoName),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        expect(find.text('Revision Dashboard'), findsOneWidget);
        expect(find.text('Welcome back!'), findsOneWidget);
        // Dashboard shows email when displayName is null, not "Unknown User"
        expect(find.text(tUserNoName.email), findsOneWidget);
      });
    });
  });
}
