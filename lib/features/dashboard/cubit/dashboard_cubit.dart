import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/core/services/preferences_service.dart';
import 'package:revision/core/services/logging_service.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  Future<void> loadDashboard() async {
    try {
      emit(state.copyWith(isLoading: true));
      
      // Load user preferences
      final preferences = DashboardPreferences(
        theme: PreferencesService.getTheme(),
        language: PreferencesService.getLanguage(),
        autoSave: PreferencesService.getAutoSave(),
        qualityPreference: PreferencesService.getQualityPreference(),
        notifications: PreferencesService.getNotifications(),
        emailVisibility: PreferencesService.getEmailVisibility(),
      );

      // Update session activity
      await PreferencesService.updateSessionActivity();

      // Log user action
      LoggingService.instance.userAction('dashboard_loaded', data: {
        'theme': preferences.theme,
        'language': preferences.language,
        'timestamp': DateTime.now().toIso8601String(),
      });

      emit(state.copyWith(
        isLoading: false,
        preferences: preferences,
        isSessionExpired: PreferencesService.isSessionExpired(),
      ));
    } catch (e) {
      LoggingService.instance.error('Failed to load dashboard', error: e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard: ${e.toString()}',
      ));
    }
  }

  Future<void> updatePreferences(DashboardPreferences preferences) async {
    try {
      emit(state.copyWith(isLoading: true));

      // Save preferences
      await PreferencesService.setTheme(preferences.theme);
      await PreferencesService.setLanguage(preferences.language);
      await PreferencesService.setAutoSave(preferences.autoSave);
      await PreferencesService.setQualityPreference(preferences.qualityPreference);
      await PreferencesService.setNotifications(preferences.notifications);
      await PreferencesService.setEmailVisibility(preferences.emailVisibility);

      // Log user action
      LoggingService.instance.userAction('preferences_updated', data: {
        'theme': preferences.theme,
        'language': preferences.language,
        'email_visibility': preferences.emailVisibility,
        'timestamp': DateTime.now().toIso8601String(),
      });

      emit(state.copyWith(
        isLoading: false,
        preferences: preferences,
      ));
    } catch (e) {
      LoggingService.instance.error('Failed to update preferences', error: e);
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to update preferences: ${e.toString()}',
      ));
    }
  }

  Future<void> refreshDashboard() async {
    // Log user action
    LoggingService.instance.userAction('dashboard_refreshed', data: {
      'timestamp': DateTime.now().toIso8601String(),
    });

    await loadDashboard();
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  void logUserAction(String action, {Map<String, dynamic>? data}) {
    LoggingService.instance.userAction(action, data: {
      'dashboard_context': true,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    });
  }
}