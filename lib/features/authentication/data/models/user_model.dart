import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:revision/features/authentication/domain/entities/user.dart';

/// Model class that extends the User entity and provides conversion methods
/// to and from Firebase User
class UserModel extends User {
  /// Creates a new [UserModel]
  const UserModel({
    required super.id,
    required super.email,
    required super.isEmailVerified,
    required super.createdAt,
    required super.customClaims,
    super.displayName,
    super.photoUrl,
  });

  /// Creates a [UserModel] from a map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool,
      createdAt:
          map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      customClaims: Map<String, dynamic>.from(
        map['customClaims'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Creates a [UserModel] from a JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
  }

  /// Creates a [UserModel] from a Firebase User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt:
          firebaseUser.metadata.creationTime?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      customClaims: const {}, // Default to empty map
    );
  }

  /// Creates a [UserModel] from a Firebase User with custom claims
  factory UserModel.fromFirebaseUserWithClaims(
    firebase_auth.User firebaseUser,
    Map<String, dynamic> customClaims,
  ) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt:
          firebaseUser.metadata.creationTime?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      customClaims: customClaims,
    );
  }

  /// Creates a Firebase User map from this model
  // This is useful if we need to save the user to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'customClaims': customClaims,
    };
  }

  /// Converts this model to a JSON map
  Map<String, dynamic> toJson() {
    return toMap();
  }
}
