import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isEmailVerified,
    required this.createdAt,
    required this.customClaims,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final String createdAt; // ISO 8601 string
  final Map<String, dynamic> customClaims;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    isEmailVerified,
    createdAt,
    customClaims,
  ];

  /// Validates email format using regex
  bool get hasValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Checks if user profile has all required information
  bool get isProfileComplete {
    return displayName != null &&
        displayName!.isNotEmpty &&
        isEmailVerified &&
        hasValidEmail;
  }

  /// Creates a copy with updated values
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    String? createdAt,
    Map<String, dynamic>? customClaims,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      customClaims: customClaims ?? this.customClaims,
    );
  }
}
