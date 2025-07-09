import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/entities/enhanced_processing_progress.dart';
import 'package:revision/features/ai_processing/domain/entities/cancellation_token.dart';

enum GeminiPipelineStatus { initial, processing, success, error, cancelled }

class GeminiPipelineState extends Equatable {
  const GeminiPipelineState({
    this.status = GeminiPipelineStatus.initial,
    this.processingResult,
    this.errorMessage,
    this.progressMessage,
    this.detailedProgress,
    this.cancellationToken,
    this.requestId,
    this.startTime,
    this.endTime,
    this.canCancel = false,
  });

  final GeminiPipelineStatus status;
  final ProcessingResult? processingResult;
  final String? errorMessage;
  final String? progressMessage;
  final ProcessingProgress? detailedProgress;
  final CancellationToken? cancellationToken;
  final String? requestId;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool canCancel;

  /// Gets the processing duration if available
  Duration? get processingDuration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// Whether the processing is in progress
  bool get isProcessing => status == GeminiPipelineStatus.processing;

  /// Whether the processing can be cancelled
  bool get isCancellable => canCancel && 
      status == GeminiPipelineStatus.processing && 
      detailedProgress?.canCancel == true;

  /// Whether the processing is complete
  bool get isComplete => status == GeminiPipelineStatus.success ||
      status == GeminiPipelineStatus.error ||
      status == GeminiPipelineStatus.cancelled;

  GeminiPipelineState copyWith({
    GeminiPipelineStatus? status,
    ProcessingResult? processingResult,
    String? errorMessage,
    String? progressMessage,
    ProcessingProgress? detailedProgress,
    CancellationToken? cancellationToken,
    String? requestId,
    DateTime? startTime,
    DateTime? endTime,
    bool? canCancel,
  }) {
    return GeminiPipelineState(
      status: status ?? this.status,
      processingResult: processingResult ?? this.processingResult,
      errorMessage: errorMessage ?? this.errorMessage,
      progressMessage: progressMessage ?? this.progressMessage,
      detailedProgress: detailedProgress ?? this.detailedProgress,
      cancellationToken: cancellationToken ?? this.cancellationToken,
      requestId: requestId ?? this.requestId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      canCancel: canCancel ?? this.canCancel,
    );
  }

  @override
  List<Object?> get props => [
    status,
    processingResult,
    errorMessage,
    progressMessage,
    detailedProgress,
    cancellationToken,
    requestId,
    startTime,
    endTime,
    canCancel,
  ];
}
