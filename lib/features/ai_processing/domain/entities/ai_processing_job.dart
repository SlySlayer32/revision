import 'package:equatable/equatable.dart';

/// AI processing job types
enum AIProcessingType {
  objectDetection,
  imageAnalysis,
  backgroundRemoval,
  styleTransfer,
  imageGeneration,
  maskGeneration,
}

/// AI processing status
enum AIProcessingStatus { pending, processing, completed, failed }

/// AI processing job entity
class AIProcessingJob extends Equatable {
  const AIProcessingJob({
    required this.id,
    required this.userId,
    required this.imageId,
    required this.type,
    required this.status,
    required this.prompt,
    required this.createdAt,
    required this.updatedAt,
    this.result,
    this.error,
    this.metadata,
    this.processingTimeMs,
  });

  final String id;
  final String userId;
  final String imageId;
  final AIProcessingType type;
  final AIProcessingStatus status;
  final String prompt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? result;
  final String? error;
  final Map<String, dynamic>? metadata;
  final int? processingTimeMs;

  AIProcessingJob copyWith({
    String? id,
    String? userId,
    String? imageId,
    AIProcessingType? type,
    AIProcessingStatus? status,
    String? prompt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? result,
    String? error,
    Map<String, dynamic>? metadata,
    int? processingTimeMs,
  }) {
    return AIProcessingJob(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageId: imageId ?? this.imageId,
      type: type ?? this.type,
      status: status ?? this.status,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      result: result ?? this.result,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    imageId,
    type,
    status,
    prompt,
    createdAt,
    updatedAt,
    result,
    error,
    metadata,
    processingTimeMs,
  ];
}
