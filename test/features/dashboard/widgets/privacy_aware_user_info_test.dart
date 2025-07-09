import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/dashboard/widgets/privacy_aware_user_info.dart';

void main() {
  group('PrivacyAwareUserInfo', () {
    testWidgets('displays email when visible is true', (WidgetTester tester) async {
      bool isVisible = true;
      const testEmail = 'test@example.com';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyAwareUserInfo(
              email: testEmail,
              isVisible: isVisible,
              onVisibilityChanged: (value) {
                isVisible = value;
              },
            ),
          ),
        ),
      );

      expect(find.text(testEmail), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('displays masked email when visible is false', (WidgetTester tester) async {
      bool isVisible = false;
      const testEmail = 'test@example.com';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyAwareUserInfo(
              email: testEmail,
              isVisible: isVisible,
              onVisibilityChanged: (value) {
                isVisible = value;
              },
            ),
          ),
        ),
      );

      expect(find.text(testEmail), findsNothing);
      expect(find.text('te**@e*.com'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('toggles visibility when icon is tapped', (WidgetTester tester) async {
      bool isVisible = true;
      const testEmail = 'test@example.com';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PrivacyAwareUserInfo(
                  email: testEmail,
                  isVisible: isVisible,
                  onVisibilityChanged: (value) {
                    setState(() {
                      isVisible = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text(testEmail), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      expect(find.text(testEmail), findsNothing);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('handles empty email gracefully', (WidgetTester tester) async {
      bool isVisible = false;
      const testEmail = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyAwareUserInfo(
              email: testEmail,
              isVisible: isVisible,
              onVisibilityChanged: (value) {
                isVisible = value;
              },
            ),
          ),
        ),
      );

      expect(find.text('Unknown User'), findsOneWidget);
    });

    testWidgets('handles invalid email format gracefully', (WidgetTester tester) async {
      bool isVisible = false;
      const testEmail = 'invalid-email';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyAwareUserInfo(
              email: testEmail,
              isVisible: isVisible,
              onVisibilityChanged: (value) {
                isVisible = value;
              },
            ),
          ),
        ),
      );

      expect(find.text('***@***.***'), findsOneWidget);
    });
  });
}