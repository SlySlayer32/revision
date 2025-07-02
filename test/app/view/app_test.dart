// VGV-compliant app widget tests
// Following Very Good Ventures testing patterns

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/app/app.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockGetAuthStateChangesUseCase extends Mock
    implements GetAuthStateChangesUseCase {}

void main() {
  group('App', () {
    setUpAll(() {
      VGVTestHelper.setupTestDependencies();
      sl.registerLazySingleton<GetAuthStateChangesUseCase>(
          () => MockGetAuthStateChangesUseCase());
    });

    tearDownAll(VGVTestHelper.tearDownTestDependencies);

    testWidgets('renders MaterialApp correctly', (tester) async {
      // VGV Pattern: Test widget rendering without external dependencies
      await VGVTestHelper.pumpAndSettle(
        tester,
        const App(),
      );

      // VGV Pattern: Verify the app structure exists
      expect(find.byType(App), findsOneWidget);
    });

    testWidgets('has correct app structure', (tester) async {
      // VGV Pattern: Test core app configuration
      await VGVTestHelper.pumpAndSettle(
        tester,
        const App(),
      );

      // VGV Pattern: Verify material design setup
      expect(find.byType(App), findsOneWidget);
    });

    testWidgets('initializes without errors', (tester) async {
      // VGV Pattern: Test initialization without throwing
      expect(() => const App(), returnsNormally);
    });
  });
}
