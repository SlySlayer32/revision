import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/dashboard/widgets/responsive_layout.dart';

void main() {
  group('ResponsiveLayout', () {
    testWidgets('shows mobile layout for small screens', (WidgetTester tester) async {
      const mobileWidget = Text('Mobile Layout');
      const tabletWidget = Text('Tablet Layout');
      const desktopWidget = Text('Desktop Layout');

      await tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile size

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: mobileWidget,
              tablet: tabletWidget,
              desktop: desktopWidget,
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('shows tablet layout for medium screens', (WidgetTester tester) async {
      const mobileWidget = Text('Mobile Layout');
      const tabletWidget = Text('Tablet Layout');
      const desktopWidget = Text('Desktop Layout');

      await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet size

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: mobileWidget,
              tablet: tabletWidget,
              desktop: desktopWidget,
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('shows desktop layout for large screens', (WidgetTester tester) async {
      const mobileWidget = Text('Mobile Layout');
      const tabletWidget = Text('Tablet Layout');
      const desktopWidget = Text('Desktop Layout');

      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop size

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: mobileWidget,
              tablet: tabletWidget,
              desktop: desktopWidget,
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet is not provided', (WidgetTester tester) async {
      const mobileWidget = Text('Mobile Layout');
      const desktopWidget = Text('Desktop Layout');

      await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet size

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: mobileWidget,
              desktop: desktopWidget,
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });
  });

  group('ScreenType', () {
    testWidgets('isMobile returns true for mobile screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(ScreenType.isMobile(context), true);
                expect(ScreenType.isTablet(context), false);
                expect(ScreenType.isDesktop(context), false);
                return const Scaffold();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for tablet screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(ScreenType.isMobile(context), false);
                expect(ScreenType.isTablet(context), true);
                expect(ScreenType.isDesktop(context), false);
                return const Scaffold();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true for desktop screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(ScreenType.isMobile(context), false);
                expect(ScreenType.isTablet(context), false);
                expect(ScreenType.isDesktop(context), true);
                return const Scaffold();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getCrossAxisCount returns correct values', (WidgetTester tester) async {
      // Test mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(ScreenType.getCrossAxisCount(context), 2);
                return const Scaffold();
              },
            ),
          ),
        ),
      );

      // Test tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(ScreenType.getCrossAxisCount(context), 3);
                return const Scaffold();
              },
            ),
          ),
        ),
      );

      // Test desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(ScreenType.getCrossAxisCount(context), 4);
                return const Scaffold();
              },
            ),
          ),
        ),
      );
    });
  });
}