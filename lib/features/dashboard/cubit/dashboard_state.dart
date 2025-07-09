part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.isLoading = false,
    this.preferences,
    this.isSessionExpired = false,
    this.error,
  });

  final bool isLoading;
  final DashboardPreferences? preferences;
  final bool isSessionExpired;
  final String? error;

  DashboardState copyWith({
    bool? isLoading,
    DashboardPreferences? preferences,
    bool? isSessionExpired,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      preferences: preferences ?? this.preferences,
      isSessionExpired: isSessionExpired ?? this.isSessionExpired,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    preferences,
    isSessionExpired,
    error,
  ];
}

class DashboardPreferences extends Equatable {
  const DashboardPreferences({
    this.theme = 'system',
    this.language = 'en',
    this.autoSave = true,
    this.qualityPreference = 'high',
    this.notifications = true,
    this.emailVisibility = true,
  });

  final String theme;
  final String language;
  final bool autoSave;
  final String qualityPreference;
  final bool notifications;
  final bool emailVisibility;

  DashboardPreferences copyWith({
    String? theme,
    String? language,
    bool? autoSave,
    String? qualityPreference,
    bool? notifications,
    bool? emailVisibility,
  }) {
    return DashboardPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      autoSave: autoSave ?? this.autoSave,
      qualityPreference: qualityPreference ?? this.qualityPreference,
      notifications: notifications ?? this.notifications,
      emailVisibility: emailVisibility ?? this.emailVisibility,
    );
  }

  @override
  List<Object?> get props => [
    theme,
    language,
    autoSave,
    qualityPreference,
    notifications,
    emailVisibility,
  ];
}