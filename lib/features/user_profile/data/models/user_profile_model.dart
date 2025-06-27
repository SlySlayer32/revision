import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.photoUrl,
    required super.createdAt,
    required super.lastLoginAt,
    super.preferences,
    super.subscription,
    super.usageStats,
  });

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
      preferences: entity.preferences,
      subscription: entity.subscription,
      usageStats: entity.usageStats,
    );
  }

  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserProfileModel(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      preferences: data['preferences'] != null
          ? UserPreferencesModel.fromMap(
              data['preferences'] as Map<String, dynamic>,
            )
          : null,
      subscription: data['subscription'] != null
          ? UserSubscriptionModel.fromMap(
              data['subscription'] as Map<String, dynamic>,
            )
          : null,
      usageStats: data['usageStats'] != null
          ? UserUsageStatsModel.fromMap(
              data['usageStats'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      if (preferences != null)
        'preferences': UserPreferencesModel.fromEntity(preferences!).toMap(),
      if (subscription != null)
        'subscription':
            UserSubscriptionModel.fromEntity(subscription!).toMap(),
      if (usageStats != null)
        'usageStats': UserUsageStatsModel.fromEntity(usageStats!).toMap(),
    };
  }
}

class UserPreferencesModel extends UserPreferences {
  const UserPreferencesModel({
    super.theme,
    super.language,
    super.autoSave,
    super.qualityPreference,
    super.notifications,
  });

  factory UserPreferencesModel.fromEntity(UserPreferences entity) {
    return UserPreferencesModel(
      theme: entity.theme,
      language: entity.language,
      autoSave: entity.autoSave,
      qualityPreference: entity.qualityPreference,
      notifications: entity.notifications,
    );
  }

  factory UserPreferencesModel.fromMap(Map<String, dynamic> data) {
    return UserPreferencesModel(
      theme: data['theme'] as String? ?? 'system',
      language: data['language'] as String? ?? 'en',
      autoSave: data['autoSave'] as bool? ?? true,
      qualityPreference: data['qualityPreference'] as String? ?? 'high',
      notifications: data['notifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'autoSave': autoSave,
      'qualityPreference': qualityPreference,
      'notifications': notifications,
    };
  }
}

class UserSubscriptionModel extends UserSubscription {
  const UserSubscriptionModel({
    required super.plan,
    required super.status,
    required super.startDate,
    super.endDate,
    super.features,
  });

  factory UserSubscriptionModel.fromEntity(UserSubscription entity) {
    return UserSubscriptionModel(
      plan: entity.plan,
      status: entity.status,
      startDate: entity.startDate,
      endDate: entity.endDate,
      features: entity.features,
    );
  }

  factory UserSubscriptionModel.fromMap(Map<String, dynamic> data) {
    return UserSubscriptionModel(
      plan: data['plan'] as String,
      status: data['status'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      features: data['features'] != null
          ? List<String>.from(data['features'] as List)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (features != null) 'features': features,
    };
  }
}

class UserUsageStatsModel extends UserUsageStats {
  const UserUsageStatsModel({
    super.imagesProcessed,
    super.aiOperationsUsed,
    super.storageUsedMb,
    super.lastActivityAt,
  });

  factory UserUsageStatsModel.fromEntity(UserUsageStats entity) {
    return UserUsageStatsModel(
      imagesProcessed: entity.imagesProcessed,
      aiOperationsUsed: entity.aiOperationsUsed,
      storageUsedMb: entity.storageUsedMb,
      lastActivityAt: entity.lastActivityAt,
    );
  }

  factory UserUsageStatsModel.fromMap(Map<String, dynamic> data) {
    return UserUsageStatsModel(
      imagesProcessed: data['imagesProcessed'] as int? ?? 0,
      aiOperationsUsed: data['aiOperationsUsed'] as int? ?? 0,
      storageUsedMb: (data['storageUsedMb'] as num?)?.toDouble() ?? 0.0,
      lastActivityAt: data['lastActivityAt'] != null
          ? (data['lastActivityAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imagesProcessed': imagesProcessed,
      'aiOperationsUsed': aiOperationsUsed,
      'storageUsedMb': storageUsedMb,
      if (lastActivityAt != null)
        'lastActivityAt': Timestamp.fromDate(lastActivityAt!),
    };
  }
}
