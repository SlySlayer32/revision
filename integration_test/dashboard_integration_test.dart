import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/dashboard/view/dashboard_page.dart';
import 'package:revision/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Page Integration Tests', () {
    setUp(() {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Dashboard loads with all components', (WidgetTester tester) async {
      // Initialize preferences service
      await PreferencesService.init();

      // Create a mock user
      final mockUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        customClaims: {'roles': ['user']},
      );

      // Create a mock authentication state
      final authState = AuthenticationState.authenticated(mockUser);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthenticationBloc>(
                create: (context) => AuthenticationBloc()
                  ..add(AuthenticationUserChanged(mockUser)),
              ),
            ],
            child: const DashboardPage(),
          ),
        ),
      );

      // Wait for the dashboard to load
      await tester.pumpAndSettle();

      // Verify that the dashboard components are present
      expect(find.text('Revision Dashboard'), findsOneWidget);
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('System Status'), findsOneWidget);
      expect(find.text('Available Tools'), findsOneWidget);
      expect(find.text('Authentication'), findsOneWidget);
      expect(find.text('AI Services'), findsOneWidget);
    });

    testWidgets('Pull-to-refresh functionality works', (WidgetTester tester) async {
      await PreferencesService.init();

      final mockUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthenticationBloc>(
                create: (context) => AuthenticationBloc()
                  ..add(AuthenticationUserChanged(mockUser)),
              ),
            ],
            child: const DashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      // Perform pull-to-refresh gesture
      await tester.drag(refreshIndicator, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify that the dashboard is still loaded after refresh
      expect(find.text('Welcome back!'), findsOneWidget);
    });

    testWidgets('Privacy controls work correctly', (WidgetTester tester) async {
      await PreferencesService.init();

      final mockUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthenticationBloc>(
                create: (context) => AuthenticationBloc()
                  ..add(AuthenticationUserChanged(mockUser)),
              ),
            ],
            child: const DashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, email should be visible
      expect(find.text('test@example.com'), findsOneWidget);

      // Find and tap the visibility toggle
      final visibilityToggle = find.byIcon(Icons.visibility);
      expect(visibilityToggle, findsOneWidget);
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Email should now be masked
      expect(find.text('test@example.com'), findsNothing);
      expect(find.text('te**@e*.com'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Session indicator is displayed', (WidgetTester tester) async {
      await PreferencesService.init();

      final mockUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthenticationBloc>(
                create: (context) => AuthenticationBloc()
                  ..add(AuthenticationUserChanged(mockUser)),
              ),
            ],
            child: const DashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find session indicator
      expect(find.byType(SessionIndicator), findsOneWidget);
    });

    testWidgets('Role-based access controls work', (WidgetTester tester) async {
      await PreferencesService.init();

      final mockUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        customClaims: {'roles': ['user']}, // Regular user, not premium
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthenticationBloc>(
                create: (context) => AuthenticationBloc()
                  ..add(AuthenticationUserChanged(mockUser)),
              ),
            ],
            child: const DashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Regular user should see AI Image Generation (available to all users)
      expect(find.text('AI Image Generation'), findsOneWidget);

      // Premium features should show as locked
      expect(find.text('Premium Feature'), findsWidgets);
    });

    testWidgets('Menu navigation works', (WidgetTester tester) async {
      await PreferencesService.init();

      final mockUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthenticationBloc>(
                create: (context) => AuthenticationBloc()
                  ..add(AuthenticationUserChanged(mockUser)),
              ),
            ],
            child: const DashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the user menu
      final userMenu = find.byType(PopupMenuButton<String>);
      expect(userMenu, findsOneWidget);
      await tester.tap(userMenu);
      await tester.pumpAndSettle();

      // Verify menu items are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Tap preferences
      await tester.tap(find.text('Preferences'));
      await tester.pumpAndSettle();

      // Verify preferences dialog opens
      expect(find.text('Preferences'), findsWidgets);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Auto Save'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });
  });
}

// Mock classes for testing
class User {
  final String id;
  final String email;
  final String name;
  final Map<String, dynamic>? customClaims;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.customClaims,
  });
}

class AuthenticationState {
  final User? user;
  
  const AuthenticationState({this.user});
  
  factory AuthenticationState.authenticated(User user) {
    return AuthenticationState(user: user);
  }
}

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(const AuthenticationState());

  @override
  Stream<AuthenticationState> mapEventToState(AuthenticationEvent event) async* {
    if (event is AuthenticationUserChanged) {
      yield AuthenticationState.authenticated(event.user);
    }
  }
}

abstract class AuthenticationEvent {}

class AuthenticationUserChanged extends AuthenticationEvent {
  final User user;
  
  AuthenticationUserChanged(this.user);
}

// Mock widget for SessionIndicator
class SessionIndicator extends StatelessWidget {
  const SessionIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: const Text('Active'),
    );
  }
}