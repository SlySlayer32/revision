import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/error/exceptions.dart';
import '../../models/user_profile_model.dart';

abstract class UserProfileFirestoreDataSource {
  Future<UserProfileModel> getUserProfile(String userId);
  Future<void> createUserProfile(UserProfileModel userProfile);
  Future<void> updateUserProfile(UserProfileModel userProfile);
  Future<void> deleteUserProfile(String userId);
  Stream<UserProfileModel> watchUserProfile(String userId);
}

class UserProfileFirestoreDataSourceImpl
    implements UserProfileFirestoreDataSource {
  UserProfileFirestoreDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final doc = await _users.doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        throw const CacheException('User profile not found');
      }

      return UserProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get user profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get user profile: $e');
    }
  }

  @override
  Future<void> createUserProfile(UserProfileModel userProfile) async {
    try {
      await _users.doc(userProfile.id).set(userProfile.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException('Failed to create user profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to create user profile: $e');
    }
  }

  @override
  Future<void> updateUserProfile(UserProfileModel userProfile) async {
    try {
      await _users.doc(userProfile.id).update(userProfile.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException('Failed to update user profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update user profile: $e');
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _users.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to delete user profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to delete user profile: $e');
    }
  }

  @override
  Stream<UserProfileModel> watchUserProfile(String userId) {
    try {
      return _users.doc(userId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          throw const CacheException('User profile not found');
        }
        return UserProfileModel.fromFirestore(doc);
      });
    } on FirebaseException catch (e) {
      throw ServerException('Failed to watch user profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to watch user profile: $e');
    }
  }
}
