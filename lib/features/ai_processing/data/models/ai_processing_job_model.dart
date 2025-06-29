import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ai_processing_job.dart';

/// Firestore data model for AI processing job
class AIProcessingJobModel extends AIProcessingJob {
  const AIProcessingJobModel({
    required super.id,
    required super.userId,
    required super.imageId,
    required super.type,
    required super.status,
    required super.prompt,
    required super.createdAt,
    required super.updatedAt,
    super.result,
    super.error,
    super.metadata,
    super.processingTimeMs,
  });

  /// Convert from Firestore DocumentSnapshot
  factory AIProcessingJobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AIProcessingJobModel(
      id: doc.id,
      userId: data['userId'] as String,
      imageId: data['imageId'] as String,
      type: _parseProcessingType(data['type'] as String),
      status: _parseProcessingStatus(data['status'] as String),
      prompt: data['prompt'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      result: data['result'] as Map<String, dynamic>?,
      error: data['error'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      processingTimeMs: data['processingTimeMs'] as int?,
    );
  }

  /// Convert from Domain entity
  factory AIProcessingJobModel.fromEntity(AIProcessingJob job) {
    return AIProcessingJobModel(
      id: job.id,
      userId: job.userId,
      imageId: job.imageId,
      type: job.type,
      status: job.status,
      prompt: job.prompt,
      createdAt: job.createdAt,
      updatedAt: job.updatedAt,
      result: job.result,
      error: job.error,
      metadata: job.metadata,
      processingTimeMs: job.processingTimeMs,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageId': imageId,
      'type': _typeToString(type),
      'status': _statusToString(status),
      'prompt': prompt,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'result': result,
      'error': error,
      'metadata': metadata,
      'processingTimeMs': processingTimeMs,
    };
  }

  /// Convert to Domain entity
  AIProcessingJob toEntity() {
    return AIProcessingJob(
      id: id,
      userId: userId,
      imageId: imageId,
      type: type,
      status: status,
      prompt: prompt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      result: result,
      error: error,
      metadata: metadata,
      processingTimeMs: processingTimeMs,
    );
  }

  // Helper methods for enum conversion
  static AIProcessingType _parseProcessingType(String type) {
    switch (type) {
      case 'object_detection':
        return AIProcessingType.objectDetection;
      case 'image_analysis':
        return AIProcessingType.imageAnalysis;
      case 'background_removal':
        return AIProcessingType.backgroundRemoval;
      case 'style_transfer':
        return AIProcessingType.styleTransfer;
      case 'image_generation':
        return AIProcessingType.imageGeneration;
      case 'mask_generation':
        return AIProcessingType.maskGeneration;
      default:
        throw ArgumentError('Unknown processing type: $type');
    }
  }

  static AIProcessingStatus _parseProcessingStatus(String status) {
    switch (status) {
      case 'pending':
        return AIProcessingStatus.pending;
      case 'processing':
        return AIProcessingStatus.processing;
      case 'completed':
        return AIProcessingStatus.completed;
      case 'failed':
        return AIProcessingStatus.failed;
      default:
        throw ArgumentError('Unknown processing status: $status');
    }
  }

  static String _typeToString(AIProcessingType type) {
    switch (type) {
      case AIProcessingType.objectDetection:
        return 'object_detection';
      case AIProcessingType.imageAnalysis:
        return 'image_analysis';
      case AIProcessingType.backgroundRemoval:
        return 'background_removal';
      case AIProcessingType.styleTransfer:
        return 'style_transfer';
      case AIProcessingType.imageGeneration:
        return 'image_generation';
      case AIProcessingType.maskGeneration:
        return 'mask_generation';
    }
  }

  static String _statusToString(AIProcessingStatus status) {
    switch (status) {
      case AIProcessingStatus.pending:
        return 'pending';
      case AIProcessingStatus.processing:
        return 'processing';
      case AIProcessingStatus.completed:
        return 'completed';
      case AIProcessingStatus.failed:
        return 'failed';
    }
  }
}
