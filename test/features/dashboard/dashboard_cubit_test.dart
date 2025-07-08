import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:revision/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:revision/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DashboardCubit', () {
    late DashboardCubit cubit;

    setUp(() {
      // Initialize SharedPreferences with mock data
      SharedPreferences.setMockInitialValues({});
      cubit = DashboardCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state, const DashboardState());
    });

    blocTest<DashboardCubit, DashboardState>(
      'loadDashboard emits loading then loaded state',
      build: () => cubit,
      setUp: () async {
        await PreferencesService.init();
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        const DashboardState(isLoading: true),
        isA<DashboardState>()
          .having((state) => state.isLoading, 'isLoading', false)
          .having((state) => state.preferences, 'preferences', isNotNull),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'updatePreferences updates preferences correctly',
      build: () => cubit,
      setUp: () async {
        await PreferencesService.init();
        await cubit.loadDashboard();
      },
      act: (cubit) {
        final newPreferences = const DashboardPreferences(
          theme: 'dark',
          emailVisibility: false,
        );
        return cubit.updatePreferences(newPreferences);
      },
      expect: () => [
        isA<DashboardState>()
          .having((state) => state.isLoading, 'isLoading', true),
        isA<DashboardState>()
          .having((state) => state.isLoading, 'isLoading', false)
          .having((state) => state.preferences?.theme, 'theme', 'dark')
          .having((state) => state.preferences?.emailVisibility, 'emailVisibility', false),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'clearError clears error state',
      build: () => cubit,
      seed: () => const DashboardState(error: 'Test error'),
      act: (cubit) => cubit.clearError(),
      expect: () => [
        const DashboardState(error: null),
      ],
    );
  });
}