import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ai_processing_job.dart';

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
    super.errorMessage,
    super.processingTimeMs,
    super.metadata,
  });

  factory AIProcessingJobModel.fromEntity(AIProcessingJob entity) {
    return AIProcessingJobModel(
      id: entity.id,
      userId: entity.userId,
      imageId: entity.imageId,
      type: entity.type,
      status: entity.status,
      prompt: entity.prompt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      result: entity.result,
      errorMessage: entity.errorMessage,
      processingTimeMs: entity.processingTimeMs,
      metadata: entity.metadata,
    );
  }

  factory AIProcessingJobModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AIProcessingJobModel(
      id: doc.id,
      userId: data['userId'] as String,
      imageId: data['imageId'] as String,
      type: _parseProcessingType(data['type'] as String),
      status: _parseProcessingStatus(data['status'] as String),
      prompt: data['prompt'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      result: data['result'] as String?,
      errorMessage: data['errorMessage'] as String?,
      processingTimeMs: data['processingTimeMs'] as int?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageId': imageId,
      'type': _processingTypeToString(type),
      'status': _processingStatusToString(status),
      'prompt': prompt,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (result != null) 'result': result,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (processingTimeMs != null) 'processingTimeMs': processingTimeMs,
      if (metadata != null) 'metadata': metadata,
    };
  }

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
      default:
        throw ArgumentError('Unknown processing type: $type');
    }
  }

  static String _processingTypeToString(AIProcessingType type) {
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

  static String _processingStatusToString(AIProcessingStatus status) {
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
