import 'package:equatable/equatable.dart';

/// Domain entity representing a user profile
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
    this.subscription,
    this.usageStats,
  });

  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences? preferences;
  final UserSubscription? subscription;
  final UserUsageStats? usageStats;

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    UserSubscription? subscription,
    UserUsageStats? usageStats,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      subscription: subscription ?? this.subscription,
      usageStats: usageStats ?? this.usageStats,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        createdAt,
        lastLoginAt,
        preferences,
        subscription,
        usageStats,
      ];
}

class UserPreferences extends Equatable {
  const UserPreferences({
    this.theme = 'system',
    this.language = 'en',
    this.autoSave = true,
    this.qualityPreference = 'high',
    this.notifications = true,
  });

  final String theme;
  final String language;
  final bool autoSave;
  final String qualityPreference;
  final bool notifications;

  UserPreferences copyWith({
    String? theme,
    String? language,
    bool? autoSave,
    String? qualityPreference,
    bool? notifications,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      autoSave: autoSave ?? this.autoSave,
      qualityPreference: qualityPreference ?? this.qualityPreference,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [
        theme,
        language,
        autoSave,
        qualityPreference,
        notifications,
      ];
}

class UserSubscription extends Equatable {
  const UserSubscription({
    required this.plan,
    required this.status,
    required this.startDate,
    this.endDate,
    this.features,
  });

  final String plan;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String>? features;

  UserSubscription copyWith({
    String? plan,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? features,
  }) {
    return UserSubscription(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      features: features ?? this.features,
    );
  }

  @override
  List<Object?> get props => [
        plan,
        status,
        startDate,
        endDate,
        features,
      ];
}

class UserUsageStats extends Equatable {
  const UserUsageStats({
    this.imagesProcessed = 0,
    this.aiOperationsUsed = 0,
    this.storageUsedMb = 0,
    this.lastActivityAt,
  });

  final int imagesProcessed;
  final int aiOperationsUsed;
  final double storageUsedMb;
  final DateTime? lastActivityAt;

  UserUsageStats copyWith({
    int? imagesProcessed,
    int? aiOperationsUsed,
    double? storageUsedMb,
    DateTime? lastActivityAt,
  }) {
    return UserUsageStats(
      imagesProcessed: imagesProcessed ?? this.imagesProcessed,
      aiOperationsUsed: aiOperationsUsed ?? this.aiOperationsUsed,
      storageUsedMb: storageUsedMb ?? this.storageUsedMb,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  List<Object?> get props => [
        imagesProcessed,
        aiOperationsUsed,
        storageUsedMb,
        lastActivityAt,
      ];
}
