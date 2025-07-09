import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/features/authentication/presentation/widgets/password_strength_indicator.dart';

void main() {
  group('PasswordStrengthIndicator', () {
    testWidgets('displays nothing when strength is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(strength: null),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Password strength: Weak'), findsNothing);
    });

    testWidgets('displays weak strength correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(
              strength: PasswordStrength.weak,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Password strength: Weak'), findsOneWidget);
      
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.33));
    });

    testWidgets('displays medium strength correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(
              strength: PasswordStrength.medium,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Password strength: Medium'), findsOneWidget);
      
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.66));
    });

    testWidgets('displays strong strength correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(
              strength: PasswordStrength.strong,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Password strength: Strong'), findsOneWidget);
      
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(1.0));
    });

    testWidgets('hides text when showText is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(
              strength: PasswordStrength.strong,
              showText: false,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Password strength: Strong'), findsNothing);
    });
  });
}