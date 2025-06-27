import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/error/exceptions.dart';
import '../../models/ai_processing_job_model.dart';

abstract class AIProcessingFirestoreDataSource {
  Future<AIProcessingJobModel> createProcessingJob(AIProcessingJobModel job);
  Future<AIProcessingJobModel> getProcessingJob(String userId, String jobId);
  Future<List<AIProcessingJobModel>> getUserProcessingJobs(String userId);
  Future<void> updateProcessingJob(AIProcessingJobModel job);
  Future<void> deleteProcessingJob(String userId, String jobId);
  Stream<AIProcessingJobModel> watchProcessingJob(String userId, String jobId);
  Stream<List<AIProcessingJobModel>> watchUserProcessingJobs(String userId);
}

class AIProcessingFirestoreDataSourceImpl implements AIProcessingFirestoreDataSource {
  AIProcessingFirestoreDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _getUserProcessingCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('ai_processing');

  @override
  Future<AIProcessingJobModel> createProcessingJob(AIProcessingJobModel job) async {
    try {
      final docRef = _getUserProcessingCollection(job.userId).doc();
      final jobWithId = AIProcessingJobModel(
        id: docRef.id,
        userId: job.userId,
        imageId: job.imageId,
        type: job.type,
        status: job.status,
        prompt: job.prompt,
        createdAt: job.createdAt,
        updatedAt: job.updatedAt,
        result: job.result,
        errorMessage: job.errorMessage,
        processingTimeMs: job.processingTimeMs,
        metadata: job.metadata,
      );
      
      await docRef.set(jobWithId.toFirestore());
      return jobWithId;
    } on FirebaseException catch (e) {
      throw ServerException('Failed to create processing job: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to create processing job: $e');
    }
  }

  @override
  Future<AIProcessingJobModel> getProcessingJob(String userId, String jobId) async {
    try {
      final doc = await _getUserProcessingCollection(userId).doc(jobId).get();
      
      if (!doc.exists || doc.data() == null) {
        throw const CacheException('Processing job not found');
      }

      return AIProcessingJobModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get processing job: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get processing job: $e');
    }
  }

  @override
  Future<List<AIProcessingJobModel>> getUserProcessingJobs(String userId) async {
    try {
      final querySnapshot = await _getUserProcessingCollection(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AIProcessingJobModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get user processing jobs: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get user processing jobs: $e');
    }
  }

  @override
  Future<void> updateProcessingJob(AIProcessingJobModel job) async {
    try {
      await _getUserProcessingCollection(job.userId)
          .doc(job.id)
          .update(job.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException('Failed to update processing job: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update processing job: $e');
    }
  }

  @override
  Future<void> deleteProcessingJob(String userId, String jobId) async {
    try {
      await _getUserProcessingCollection(userId).doc(jobId).delete();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to delete processing job: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to delete processing job: $e');
    }
  }

  @override
  Stream<AIProcessingJobModel> watchProcessingJob(String userId, String jobId) {
    try {
      return _getUserProcessingCollection(userId)
          .doc(jobId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) {
          throw const CacheException('Processing job not found');
        }
        return AIProcessingJobModel.fromFirestore(doc);
      });
    } on FirebaseException catch (e) {
      throw ServerException('Failed to watch processing job: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to watch processing job: $e');
    }
  }

  @override
  Stream<List<AIProcessingJobModel>> watchUserProcessingJobs(String userId) {
    try {
      return _getUserProcessingCollection(userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => AIProcessingJobModel.fromFirestore(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw ServerException('Failed to watch user processing jobs: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to watch user processing jobs: $e');
    }
  }
}
