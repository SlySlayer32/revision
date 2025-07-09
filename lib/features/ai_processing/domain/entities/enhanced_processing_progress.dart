import 'package:equatable/equatable.dart';

/// Enhanced progress tracking for AI processing operations
class ProcessingProgress extends Equatable {
  const ProcessingProgress({
    required this.stage,
    required this.progress,
    this.message,
    this.estimatedTimeRemaining,
    this.currentStepIndex = 0,
    this.totalSteps = 1,
    this.canCancel = true,
    this.metadata = const {},
  });

  /// The current processing stage
  final ProcessingStage stage;
  
  /// Progress value between 0.0 and 1.0
  final double progress;
  
  /// Optional descriptive message
  final String? message;
  
  /// Estimated time remaining for completion
  final Duration? estimatedTimeRemaining;
  
  /// Current step index (0-based)
  final int currentStepIndex;
  
  /// Total number of steps
  final int totalSteps;
  
  /// Whether the operation can be cancelled at this stage
  final bool canCancel;
  
  /// Additional metadata for the progress
  final Map<String, dynamic> metadata;

  /// Creates a progress object for initialization
  factory ProcessingProgress.initializing({String? message}) {
    return ProcessingProgress(
      stage: ProcessingStage.initializing,
      progress: 0.0,
      message: message ?? 'Initializing...',
      canCancel: true,
    );
  }

  /// Creates a progress object for validation
  factory ProcessingProgress.validating({String? message}) {
    return ProcessingProgress(
      stage: ProcessingStage.validating,
      progress: 0.1,
      message: message ?? 'Validating image...',
      canCancel: true,
    );
  }

  /// Creates a progress object for preprocessing
  factory ProcessingProgress.preprocessing({
    required double progress,
    String? message,
    Duration? estimatedTimeRemaining,
  }) {
    return ProcessingProgress(
      stage: ProcessingStage.preprocessing,
      progress: 0.2 + (progress * 0.2), // 20% to 40% of total
      message: message ?? 'Preprocessing image...',
      estimatedTimeRemaining: estimatedTimeRemaining,
      canCancel: true,
    );
  }

  /// Creates a progress object for analysis
  factory ProcessingProgress.analyzing({
    required double progress,
    String? message,
    Duration? estimatedTimeRemaining,
  }) {
    return ProcessingProgress(
      stage: ProcessingStage.analyzing,
      progress: 0.4 + (progress * 0.3), // 40% to 70% of total
      message: message ?? 'Analyzing image...',
      estimatedTimeRemaining: estimatedTimeRemaining,
      canCancel: true,
    );
  }

  /// Creates a progress object for AI processing
  factory ProcessingProgress.processing({
    required double progress,
    String? message,
    Duration? estimatedTimeRemaining,
  }) {
    return ProcessingProgress(
      stage: ProcessingStage.processing,
      progress: 0.7 + (progress * 0.2), // 70% to 90% of total
      message: message ?? 'Processing with AI...',
      estimatedTimeRemaining: estimatedTimeRemaining,
      canCancel: false, // Can't cancel during actual AI processing
    );
  }

  /// Creates a progress object for post-processing
  factory ProcessingProgress.postProcessing({
    required double progress,
    String? message,
  }) {
    return ProcessingProgress(
      stage: ProcessingStage.postProcessing,
      progress: 0.9 + (progress * 0.1), // 90% to 100% of total
      message: message ?? 'Finalizing results...',
      canCancel: false,
    );
  }

  /// Creates a progress object for completion
  factory ProcessingProgress.completed({String? message}) {
    return ProcessingProgress(
      stage: ProcessingStage.completed,
      progress: 1.0,
      message: message ?? 'Processing completed',
      canCancel: false,
    );
  }

  /// Creates a progress object for cancellation
  factory ProcessingProgress.cancelled({String? message}) {
    return ProcessingProgress(
      stage: ProcessingStage.cancelled,
      progress: 0.0,
      message: message ?? 'Processing cancelled',
      canCancel: false,
    );
  }

  /// Creates a progress object for error state
  factory ProcessingProgress.error({String? message}) {
    return ProcessingProgress(
      stage: ProcessingStage.error,
      progress: 0.0,
      message: message ?? 'Processing failed',
      canCancel: false,
    );
  }

  /// Gets the progress as a percentage (0-100)
  int get progressPercentage => (progress * 100).round();

  /// Whether the processing is in an active state
  bool get isActive => stage == ProcessingStage.preprocessing ||
      stage == ProcessingStage.analyzing ||
      stage == ProcessingStage.processing ||
      stage == ProcessingStage.postProcessing;

  /// Whether the processing is complete (success or failure)
  bool get isComplete => stage == ProcessingStage.completed ||
      stage == ProcessingStage.cancelled ||
      stage == ProcessingStage.error;

  /// Creates a copy with updated values
  ProcessingProgress copyWith({
    ProcessingStage? stage,
    double? progress,
    String? message,
    Duration? estimatedTimeRemaining,
    int? currentStepIndex,
    int? totalSteps,
    bool? canCancel,
    Map<String, dynamic>? metadata,
  }) {
    return ProcessingProgress(
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
      canCancel: canCancel ?? this.canCancel,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    stage,
    progress,
    message,
    estimatedTimeRemaining,
    currentStepIndex,
    totalSteps,
    canCancel,
    metadata,
  ];
}

/// Enum representing different processing stages
enum ProcessingStage {
  initializing,
  validating,
  preprocessing,
  analyzing,
  processing,
  postProcessing,
  completed,
  cancelled,
  error,
}

/// Extension on ProcessingStage for display purposes
extension ProcessingStageX on ProcessingStage {
  String get displayName {
    switch (this) {
      case ProcessingStage.initializing:
        return 'Initializing';
      case ProcessingStage.validating:
        return 'Validating';
      case ProcessingStage.preprocessing:
        return 'Preprocessing';
      case ProcessingStage.analyzing:
        return 'Analyzing';
      case ProcessingStage.processing:
        return 'Processing';
      case ProcessingStage.postProcessing:
        return 'Post-processing';
      case ProcessingStage.completed:
        return 'Completed';
      case ProcessingStage.cancelled:
        return 'Cancelled';
      case ProcessingStage.error:
        return 'Error';
    }
  }

  /// Gets the icon associated with this stage
  String get icon {
    switch (this) {
      case ProcessingStage.initializing:
        return '🔄';
      case ProcessingStage.validating:
        return '✅';
      case ProcessingStage.preprocessing:
        return '🔧';
      case ProcessingStage.analyzing:
        return '🔍';
      case ProcessingStage.processing:
        return '🤖';
      case ProcessingStage.postProcessing:
        return '🎨';
      case ProcessingStage.completed:
        return '✅';
      case ProcessingStage.cancelled:
        return '❌';
      case ProcessingStage.error:
        return '⚠️';
    }
  }
}