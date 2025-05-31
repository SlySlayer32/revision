import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user in the domain layer
class User extends Equatable {
  /// Creates a new User entity
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
  });

  /// The unique identifier of the user
  final String id;

  /// The email address of the user
  final String email;

  /// The display name of the user, if provided
  final String? displayName;

  /// The URL of the user's profile photo, if provided
  final String? photoUrl;

  /// Whether the user's email address has been verified
  final bool isEmailVerified;

  @override
  List<Object?> get props =>
      [id, email, displayName, photoUrl, isEmailVerified];

  /// Creates a copy of this User with the given fields replaced with new values
  User copyWith({
    String? id,
    String? email,
    String? Function()? displayName,
    String? Function()? photoUrl,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName != null ? displayName() : this.displayName,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
