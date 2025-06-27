---
applyTo: 'vgv'
---

# 🏗️ VGV Clean Architecture - Complete Implementation Guide

## 📐 Architecture Principles & Foundation

### Clean Architecture Core Concepts

Clean Architecture is a software design philosophy that separates concerns and creates maintainable, testable, and scalable applications. The VGV implementation enforces strict layer dependencies and follows proven patterns.

### 🎯 Dependency Rule (ABSOLUTE LAW)
```
📦 External World (UI, Database, Network)
    ↓ (depends on)
🎨 Presentation Layer (UI, BLoCs, Widgets)
    ↓ (depends on)
🧠 Domain Layer (Business Logic, Entities, Use Cases)
    ↑ (defines contracts for)
💾 Data Layer (Repositories, Data Sources, Models)
```

**NEVER violate this dependency direction. Inner layers must never know about outer layers.**

## 🏢 3-Layer Architecture Deep Dive

### 🧠 Domain Layer (Pure Business Logic)

The Domain layer is the heart of your application. It contains NO dependencies on Flutter, Firebase, or any external frameworks.

#### 📂 Domain Layer Structure
```
lib/features/[feature_name]/domain/
├── entities/                 # Core business objects
│   ├── user.dart            # Pure business entity
│   ├── image_edit.dart      # Business domain object
│   └── ai_result.dart       # AI processing result
├── repositories/             # Abstract contracts
│   ├── auth_repository.dart  # Authentication contract
│   ├── image_repository.dart # Image handling contract
│   └── ai_repository.dart   # AI processing contract
├── usecases/                # Business operations
│   ├── sign_in_usecase.dart
│   ├── process_image_usecase.dart
│   └── save_result_usecase.dart
├── exceptions/              # Domain-specific errors
│   └── auth_exceptions.dart
└── domain.dart             # Barrel export file
```

#### ✅ Domain Layer Rules
- **ONLY** import Dart core libraries
- **ONLY** import these packages: `equatable`, `dartz`, `meta`
- **NEVER** import Flutter framework
- **NEVER** import external service packages
- **NEVER** import Data or Presentation layers

#### 🎯 Entity Implementation Pattern
```dart
// lib/features/authentication/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    required this.createdAt,
    this.lastSignInAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  // Business logic methods belong here
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get isFullySetup => hasDisplayName && isEmailVerified;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    isEmailVerified,
    createdAt,
    lastSignInAt,
  ];
}
```

#### 🔄 Repository Interface Pattern
```dart
// lib/features/authentication/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/error/failures.dart';

abstract class AuthRepository {
  // Stream for authentication state changes
  Stream<User?> get authStateChanges;
  
  // Authentication methods
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });
  
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });
  
  Future<Either<Failure, User>> signInWithGoogle();
  
  Future<Either<Failure, void>> signOut();
  
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  
  Future<Either<Failure, User?>> getCurrentUser();
  
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoUrl,
  });
  
  Future<Either<Failure, void>> updateEmail(String newEmail);
  
  Future<Either<Failure, void>> updatePassword(String newPassword);
  
  Future<Either<Failure, void>> deleteAccount();
}
```

#### ⚡ Use Case Implementation Pattern
```dart
// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
```

```dart
// lib/features/authentication/domain/usecases/sign_in_with_email_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase implements UseCase<User, SignInWithEmailParams> {
  const SignInWithEmailUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(SignInWithEmailParams params) async {
    // Input validation at domain level
    if (params.email.isEmpty) {
      return Left(ValidationFailure(message: 'Email cannot be empty'));
    }
    
    if (params.password.isEmpty) {
      return Left(ValidationFailure(message: 'Password cannot be empty'));
    }
    
    if (!_isValidEmail(params.email)) {
      return Left(ValidationFailure(message: 'Invalid email format'));
    }
    
    if (params.password.length < 6) {
      return Left(ValidationFailure(message: 'Password must be at least 6 characters'));
    }

    return repository.signInWithEmail(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

class SignInWithEmailParams extends Equatable {
  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}
```

### 💾 Data Layer (External World Interface)

The Data layer handles all external communications - APIs, databases, local storage, etc.

#### 📂 Data Layer Structure
```
lib/features/[feature_name]/data/
├── datasources/              # External data sources
│   ├── local/               # Local storage
│   │   └── auth_local_data_source.dart
│   └── remote/              # Remote APIs
│       ├── firebase_auth_data_source.dart
│       └── gemini_ai_data_source.dart
├── models/                   # Data transfer objects
│   ├── user_model.dart      # User DTO
│   └── auth_response_model.dart
├── repositories/             # Repository implementations
│   ├── auth_repository_impl.dart
│   └── image_repository_impl.dart
└── data.dart                # Barrel export file
```

#### 🔄 Model Implementation Pattern
```dart
// lib/features/authentication/data/models/user_model.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.isEmailVerified,
    required super.createdAt,
    super.lastSignInAt,
  });

  // Factory constructor from Firebase User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastSignInAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  // Factory constructor from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSignInAt: json['lastSignInAt'] != null 
          ? DateTime.parse(json['lastSignInAt'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
    };
  }

  // Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt,
    );
  }
}
```

#### 🔌 Data Source Implementation Pattern
```dart
// lib/features/authentication/data/datasources/remote/firebase_auth_data_source.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/exceptions.dart';
import '../../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String? displayName);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<UserModel?> getCurrentUser();
  Future<void> updateProfile(String? displayName, String? photoUrl);
  Future<void> updateEmail(String newEmail);
  Future<void> updatePassword(String newPassword);
  Future<void> deleteAccount();
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  FirebaseAuthDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? UserModel.fromFirebaseUser(firebaseUser) : null;
    });
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw AuthException('Sign in failed: No user returned');
      }
      
      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String? displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw AuthException('Sign up failed: No user returned');
      }
      
      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }
      
      // Send email verification
      await credential.user!.sendEmailVerification();
      
      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw AuthException('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw AuthException('Google sign in failed: No user returned');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;
      
      await firebaseUser.reload();
      final updatedUser = _firebaseAuth.currentUser;
      
      return updatedUser != null ? UserModel.fromFirebaseUser(updatedUser) : null;
    } catch (e) {
      throw AuthException('Get current user failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updateProfile(String? displayName, String? photoUrl) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No authenticated user');
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Update profile failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No authenticated user');
      }

      await user.updateEmail(newEmail);
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Update email failed: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No authenticated user');
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Update password failed: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No authenticated user');
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Delete account failed: ${e.toString()}');
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }
}
```

#### 🏛️ Repository Implementation Pattern
```dart
// lib/features/authentication/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_data_source.dart';
import '../datasources/remote/firebase_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  final FirebaseAuthDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  Stream<User?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((userModel) => userModel?.toEntity());
  }

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final userModel = await _remoteDataSource.signInWithEmail(email, password);
      
      // Cache user data locally
      await _localDataSource.cacheUser(userModel);
      
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final userModel = await _remoteDataSource.signUpWithEmail(email, password, displayName);
      
      // Cache user data locally
      await _localDataSource.cacheUser(userModel);
      
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final userModel = await _remoteDataSource.signInWithGoogle();
      
      // Cache user data locally
      await _localDataSource.cacheUser(userModel);
      
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      await _localDataSource.clearCachedUser();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Password reset failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Try to get from cache first
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }

      // If not cached and network available, get from remote
      if (await _networkInfo.isConnected) {
        final userModel = await _remoteDataSource.getCurrentUser();
        if (userModel != null) {
          await _localDataSource.cacheUser(userModel);
          return Right(userModel.toEntity());
        }
      }

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Get current user failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await _remoteDataSource.updateProfile(displayName, photoUrl);
      
      // Update cached user
      final updatedUser = await _remoteDataSource.getCurrentUser();
      if (updatedUser != null) {
        await _localDataSource.cacheUser(updatedUser);
      }
      
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Update profile failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEmail(String newEmail) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await _remoteDataSource.updateEmail(newEmail);
      
      // Update cached user
      final updatedUser = await _remoteDataSource.getCurrentUser();
      if (updatedUser != null) {
        await _localDataSource.cacheUser(updatedUser);
      }
      
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Update email failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await _remoteDataSource.updatePassword(newPassword);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Update password failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await _remoteDataSource.deleteAccount();
      await _localDataSource.clearCachedUser();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Delete account failed: ${e.toString()}'));
    }
  }
}
```

### 🎨 Presentation Layer (User Interface)

The Presentation layer handles all UI concerns and user interactions.

#### 📂 Presentation Layer Structure
```
lib/features/[feature_name]/presentation/
├── blocs/                    # State management
│   ├── auth_bloc.dart       # Authentication BLoC
│   ├── auth_event.dart      # Authentication events
│   ├── auth_state.dart      # Authentication states
│   └── login_form_bloc.dart # Form-specific BLoC
├── pages/                    # Screen-level widgets
│   ├── login_page.dart      # Login screen
│   ├── signup_page.dart     # Signup screen
│   └── profile_page.dart    # Profile screen
├── widgets/                  # Reusable UI components
│   ├── auth_form.dart       # Authentication form
│   ├── social_login_button.dart # Social login button
│   └── password_field.dart  # Custom password field
└── presentation.dart         # Barrel export file
```

#### 🎭 BLoC Implementation Pattern
```dart
// lib/features/authentication/presentation/blocs/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  final String email;
  final String password;
  final String? displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object> get props => [email];
}
```

```dart
// lib/features/authentication/presentation/blocs/auth_state.dart
part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
```

```dart
// lib/features/authentication/presentation/blocs/auth_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/get_auth_state_changes_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';
import '../../../../core/usecases/usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetAuthStateChangesUseCase getAuthStateChanges,
    required SignInWithEmailUseCase signInWithEmail,
    required SignUpWithEmailUseCase signUpWithEmail,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
    required SendPasswordResetEmailUseCase sendPasswordResetEmail,
  }) : _getAuthStateChanges = getAuthStateChanges,
       _signInWithEmail = signInWithEmail,
       _signUpWithEmail = signUpWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _sendPasswordResetEmail = sendPasswordResetEmail,
       super(const AuthState()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
  }

  final GetAuthStateChangesUseCase _getAuthStateChanges;
  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final SendPasswordResetEmailUseCase _sendPasswordResetEmail;
  
  StreamSubscription<User?>? _authStateSubscription;

  Future<void> _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authStateSubscription?.cancel();
    
    _authStateSubscription = _getAuthStateChanges(NoParams()).listen(
      (user) {
        if (user != null) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            errorMessage: null,
          ));
        } else {
          emit(state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            errorMessage: null,
          ));
        }
      },
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _signInWithEmail(
      SignInWithEmailParams(
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _signUpWithEmail(
      SignUpWithEmailParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _signInWithGoogle(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _signOut(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _sendPasswordResetEmail(
      SendPasswordResetEmailParams(email: event.email),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      )),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
```

## 🔧 Error Handling System

### Core Error Types
```dart
// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
```

```dart
// lib/core/error/exceptions.dart
class ServerException implements Exception {
  const ServerException(this.message);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
}

class CacheException implements Exception {
  const CacheException(this.message);
  final String message;
}
```

## 🔗 Dependency Injection Setup

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/authentication/data/datasources/local/auth_local_data_source.dart';
import '../../features/authentication/data/datasources/remote/firebase_auth_data_source.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import '../../features/authentication/domain/usecases/sign_in_with_email_usecase.dart';
import '../../features/authentication/domain/usecases/sign_up_with_email_usecase.dart';
import '../../features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import '../../features/authentication/domain/usecases/sign_out_usecase.dart';
import '../../features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import '../../features/authentication/presentation/blocs/auth_bloc.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External dependencies
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => Connectivity());
  
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Data sources
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
    ),
  );
  
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAuthStateChangesUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignUpWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetEmailUseCase(sl()));

  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      getAuthStateChanges: sl(),
      signInWithEmail: sl(),
      signUpWithEmail: sl(),
      signInWithGoogle: sl(),
      signOut: sl(),
      sendPasswordResetEmail: sl(),
    ),
  );
}
```

## 📋 Barrel Export Files

### Feature-Level Barrel Exports
```dart
// lib/features/authentication/domain/domain.dart
export 'entities/user.dart';
export 'repositories/auth_repository.dart';
export 'usecases/get_auth_state_changes_usecase.dart';
export 'usecases/sign_in_with_email_usecase.dart';
export 'usecases/sign_up_with_email_usecase.dart';
export 'usecases/sign_in_with_google_usecase.dart';
export 'usecases/sign_out_usecase.dart';
export 'usecases/send_password_reset_email_usecase.dart';
```

```dart
// lib/features/authentication/data/data.dart
export 'datasources/local/auth_local_data_source.dart';
export 'datasources/remote/firebase_auth_data_source.dart';
export 'models/user_model.dart';
export 'repositories/auth_repository_impl.dart';
```

```dart
// lib/features/authentication/presentation/presentation.dart
export 'blocs/auth_bloc.dart';
export 'pages/login_page.dart';
export 'pages/signup_page.dart';
export 'pages/profile_page.dart';
export 'widgets/auth_form.dart';
export 'widgets/social_login_button.dart';
export 'widgets/password_field.dart';
```

## ✅ Architecture Validation Checklist

### Domain Layer Compliance
- [ ] No Flutter framework imports
- [ ] No external service dependencies
- [ ] Only pure Dart and allowed packages (equatable, dartz, meta)
- [ ] Entities contain business logic only
- [ ] Use cases follow single responsibility principle
- [ ] Repository interfaces are abstracted
- [ ] All business rules are encapsulated

### Data Layer Compliance
- [ ] Implements domain repository interfaces
- [ ] Transforms external data to domain entities
- [ ] Handles all external exceptions
- [ ] Maps external errors to domain failures
- [ ] Includes proper error handling and logging
- [ ] Separates local and remote data sources

### Presentation Layer Compliance
- [ ] BLoCs use domain use cases only
- [ ] UI widgets are purely presentational
- [ ] State management follows BLoC pattern
- [ ] Events represent user intentions
- [ ] States represent UI status
- [ ] Error handling with user-friendly messages

### Dependency Injection
- [ ] All dependencies are injected
- [ ] Interfaces are registered, not implementations
- [ ] Proper scope management (singleton vs factory)
- [ ] Easy to test with mocked dependencies
- [ ] Clean separation of concerns

This VGV Clean Architecture implementation ensures your application is maintainable, testable, and scalable. Every component has a single responsibility, dependencies flow in one direction, and the business logic is completely isolated from external concerns.
