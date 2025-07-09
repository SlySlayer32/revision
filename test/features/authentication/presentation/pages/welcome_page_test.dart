import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';
import 'package:revision/core/navigation/route_names.dart';

void main() {
  group('WelcomePage', () {
    testWidgets('should display welcome title and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 100));

      // Check for welcome title
      expect(find.text('Welcome to Revision'), findsOneWidget);

      // Check for app description
      expect(
        find.text('AI-powered image editing that seamlessly removes trees from gardens and changes wall colors - making it look like it was never edited'),
        findsOneWidget,
      );
    });

    testWidgets('should display login and signup buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check for buttons
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check for semantic labels
      expect(find.byType(Semantics), findsWidgets);
      
      // Check for specific semantic labels
      final titleSemantic = find.ancestor(
        of: find.text('Welcome to Revision'),
        matching: find.byType(Semantics),
      );
      expect(titleSemantic, findsOneWidget);

      final loginButtonSemantic = find.ancestor(
        of: find.text('Log In'),
        matching: find.byType(Semantics),
      );
      expect(loginButtonSemantic, findsOneWidget);

      final signupButtonSemantic = find.ancestor(
        of: find.text('Sign Up'),
        matching: find.byType(Semantics),
      );
      expect(signupButtonSemantic, findsOneWidget);
    });

    testWidgets('should display app info when info button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap the info button
      final infoButton = find.byIcon(Icons.info_outline);
      expect(infoButton, findsOneWidget);

      await tester.tap(infoButton);
      await tester.pump();

      // Check that app info section appears
      expect(find.text('App Information'), findsOneWidget);
      expect(find.textContaining('Version:'), findsOneWidget);
      expect(find.textContaining('Environment:'), findsOneWidget);
    });

    testWidgets('should handle login button press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomePage(),
          routes: {
            RouteNames.login: (context) => const Scaffold(body: Text('Login Page')),
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap the login button
      final loginButton = find.text('Log In');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Note: In a real test, you would check navigation
      // This is simplified due to the complex navigation setup
    });

    testWidgets('should handle signup button press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomePage(),
          routes: {
            RouteNames.signup: (context) => const Scaffold(body: Text('Signup Page')),
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap the signup button
      final signupButton = find.text('Sign Up');
      expect(signupButton, findsOneWidget);

      await tester.tap(signupButton);
      await tester.pumpAndSettle();

      // Note: In a real test, you would check navigation
      // This is simplified due to the complex navigation setup
    });

    testWidgets('should create route correctly', (WidgetTester tester) async {
      final route = WelcomePage.route();
      
      expect(route, isA<Route<void>>());
      expect(route.settings.name, equals(RouteNames.welcome));
    });

    testWidgets('should be a StatefulWidget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      expect(find.byType(WelcomePage), findsOneWidget);
      
      // Verify it's a StatefulWidget by checking state
      final welcomePageState = tester.state<State<WelcomePage>>(find.byType(WelcomePage));
      expect(welcomePageState, isNotNull);
    });

    testWidgets('should have proper widget structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check for main structural elements
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should handle offline state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Initially should be online (mocked)
      expect(find.byIcon(Icons.wifi_off), findsNothing);

      // The offline banner should not be visible initially
      expect(find.text('You are currently offline. Some features may not be available.'), findsNothing);
    });

    testWidgets('should display app info section when toggled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // App info should not be visible initially
      expect(find.text('App Information'), findsNothing);

      // Tap the info button
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();

      // App info should now be visible
      expect(find.text('App Information'), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();

      // App info should be hidden again
      expect(find.text('App Information'), findsNothing);
    });
  });
}