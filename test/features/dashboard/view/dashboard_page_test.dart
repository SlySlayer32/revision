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

    group('when user is authenticated', () {
      testWidgets('renders dashboard with welcome message', (tester) async {
        final user = TestDataFactory.user();
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(user),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        expect(find.text('AI Photo Editor Dashboard'), findsOneWidget);
        expect(find.text('Welcome back!'), findsOneWidget);
        expect(find.text(user.email), findsOneWidget);
      });

      testWidgets('displays tools grid with coming soon features',
          (tester) async {
        final user = TestDataFactory.user();
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(user),
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
        final user = TestDataFactory.user();
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(user),
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
        final user = TestDataFactory.user();
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(user),
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
        final user = TestDataFactory.user();
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(user),
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
        final userWithoutDisplayName = TestDataFactory.user();
        when(() => mockAuthenticationBloc.state).thenReturn(
          AuthenticationState.authenticated(userWithoutDisplayName),
        );

        await tester.pumpApp(
          BlocProvider<AuthenticationBloc>.value(
            value: mockAuthenticationBloc,
            child: const DashboardPage(),
          ),
        );

        expect(find.text('AI Photo Editor Dashboard'), findsOneWidget);
        expect(find.text('Welcome back!'), findsOneWidget);
        expect(find.text('Unknown User'), findsOneWidget);
      });
    });
  });
}
