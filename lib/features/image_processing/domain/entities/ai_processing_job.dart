import 'package:equatable/equatable.dart';

/// Domain entity representing an AI processing job
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
    this.errorMessage,
    this.processingTimeMs,
    this.metadata,
  });

  final String id;
  final String userId;
  final String imageId;
  final AIProcessingType type;
  final AIProcessingStatus status;
  final String prompt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? result;
  final String? errorMessage;
  final int? processingTimeMs;
  final Map<String, dynamic>? metadata;

  AIProcessingJob copyWith({
    String? id,
    String? userId,
    String? imageId,
    AIProcessingType? type,
    AIProcessingStatus? status,
    String? prompt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? result,
    String? errorMessage,
    int? processingTimeMs,
    Map<String, dynamic>? metadata,
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
      errorMessage: errorMessage ?? this.errorMessage,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      metadata: metadata ?? this.metadata,
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
    errorMessage,
    processingTimeMs,
    metadata,
  ];
}

enum AIProcessingType {
  objectDetection,
  imageAnalysis,
  backgroundRemoval,
  styleTransfer,
  imageGeneration,
}

enum AIProcessingStatus { pending, processing, completed, failed }
