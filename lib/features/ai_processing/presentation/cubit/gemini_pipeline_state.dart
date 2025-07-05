import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';

enum GeminiPipelineStatus {
  initial,
  processing,
  success,
  error,
  cancelled,
}

class GeminiPipelineState extends Equatable {
  const GeminiPipelineState({
    this.status = GeminiPipelineStatus.initial,
    this.processingResult,
    this.errorMessage,
    this.progressMessage,
  });

  final GeminiPipelineStatus status;
  final ProcessingResult? processingResult;
  final String? errorMessage;
  final String? progressMessage;

  GeminiPipelineState copyWith({
    GeminiPipelineStatus? status,
    ProcessingResult? processingResult,
    String? errorMessage,
    String? progressMessage,
  }) {
    return GeminiPipelineState(
      status: status ?? this.status,
      processingResult: processingResult ?? this.processingResult,
      errorMessage: errorMessage ?? this.errorMessage,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, processingResult, errorMessage, progressMessage];
}
