import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../../core/error/exceptions.dart';
import '../../models/user_model.dart';

/// Abstract interface for Firestore user data operations
abstract class FirestoreUserDataSource {
  /// Create a new user profile in Firestore
  Future<void> createUserProfile(UserModel user);
  
  /// Get user profile by user ID
  Future<UserModel?> getUserProfile(String userId);
  
  /// Update user profile
  Future<void> updateUserProfile(UserModel user);
  
  /// Delete user profile
  Future<void> deleteUserProfile(String userId);
  
  /// Update user preferences
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences);
  
  /// Get user by email
  Future<UserModel?> getUserByEmail(String email);
  
  /// Check if user profile exists
  Future<bool> userProfileExists(String userId);
}

/// Firestore implementation of user data source
class FirestoreUserDataSourceImpl implements FirestoreUserDataSource {
  FirestoreUserDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  
  /// Users collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  @override
  Future<void> createUserProfile(UserModel user) async {
    try {
      log('Creating user profile for user: ${user.id}');
      
      await _usersCollection.doc(user.id).set(user.toFirestore());
      
      log('✅ User profile created successfully');
    } on FirebaseException catch (e) {
      log('❌ Firebase error creating user profile: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Failed to create user profile');
    } catch (e) {
      log('❌ Unexpected error creating user profile: $e');
      throw ServerException('Failed to create user profile');
    }
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      log('Getting user profile for user: $userId');
      
      final doc = await _usersCollection.doc(userId).get();
      
      if (!doc.exists) {
        log('User profile not found for user: $userId');
        return null;
      }
      
      final user = UserModel.fromFirestore(doc);
      log('✅ User profile retrieved successfully');
      return user;
    } on FirebaseException catch (e) {
      log('❌ Firebase error getting user profile: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Failed to get user profile');
    } catch (e) {
      log('❌ Unexpected error getting user profile: $e');
      throw ServerException('Failed to get user profile');
    }
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    try {
      log('Updating user profile for user: ${user.id}');
      
      await _usersCollection.doc(user.id).update(user.toFirestore());
      
      log('✅ User profile updated successfully');
    } on FirebaseException catch (e) {
      log('❌ Firebase error updating user profile: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Failed to update user profile');
    } catch (e) {
      log('❌ Unexpected error updating user profile: $e');
      throw ServerException('Failed to update user profile');
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      log('Deleting user profile for user: $userId');
      
      await _usersCollection.doc(userId).delete();
      
      log('✅ User profile deleted successfully');
    } on FirebaseException catch (e) {
      log('❌ Firebase error deleting user profile: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Failed to delete user profile');
    } catch (e) {
      log('❌ Unexpected error deleting user profile: $e');
      throw ServerException('Failed to delete user profile');
    }
  }

  @override
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      log('Updating user preferences for user: $userId');
      
      await _usersCollection.doc(userId).update({
        'preferences': preferences,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      log('✅ User preferences updated successfully');
    } on FirebaseException catch (e) {
      log('❌ Firebase error updating user preferences: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Failed to update user preferences');
    } catch (e) {
      log('❌ Unexpected error updating user preferences: $e');
      throw ServerException('Failed to update user preferences');
    }
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      log('Getting user by email: $email');
      
      final query = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        log('User not found with email: $email');
        return null;
      }
      
      final user = UserModel.fromFirestore(query.docs.first);
      log('✅ User retrieved by email successfully');
      return user;
    } on FirebaseException catch (e) {
      log('❌ Firebase error getting user by email: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Failed to get user by email');
    } catch (e) {
      log('❌ Unexpected error getting user by email: $e');
      throw ServerException('Failed to get user by email');
    }
  }

  @override
  Future<bool> userProfileExists(String userId) async {
    try {
      log('Checking if user profile exists for user: $userId');
      
      final doc = await _usersCollection.doc(userId).get();
      final exists = doc.exists;
      
      log('User profile exists: $exists');
      return exists;
    } on FirebaseException catch (e) {
      log('❌ Firebase error checking user profile existence: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Failed to check user profile existence');
    } catch (e) {
      log('❌ Unexpected error checking user profile existence: $e');
      throw ServerException('Failed to check user profile existence');
    }
  }
}
