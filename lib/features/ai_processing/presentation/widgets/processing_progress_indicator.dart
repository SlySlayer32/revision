import 'package:flutter/material.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/utils/duration_formatter.dart';

/// Widget for displaying AI processing progress with visual feedback.
class ProcessingProgressIndicator extends StatelessWidget {
  const ProcessingProgressIndicator({
    required this.progress,
    super.key,
  });

  final ProcessingProgress progress;
  // Design constants
  static const double _progressCircleSize = 120.0;
  static const double _progressStrokeWidth = 8.0;
  static const double _containerPadding = 24.0;
  static const double _spacingLarge = 24.0;
  static const double _spacingMedium = 16.0;
  static const double _stageOpacity = 0.3;
  // Stage mappings for better performance
  static final Map<ProcessingStage, String> _stageLabels = {
    ProcessingStage.analyzing: 'Analyzing',
    ProcessingStage.promptEngineering: 'Optimizing',
    ProcessingStage.aiProcessing: 'Processing',
    ProcessingStage.postProcessing: 'Finalizing',
    ProcessingStage.completed: 'Complete',
  };

  @override
  Widget build(BuildContext context) {
    // Validate and clamp progress to prevent potential issues
    final clampedProgress = progress.progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(_containerPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress circle
          SizedBox(
            width: _progressCircleSize,
            height: _progressCircleSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: clampedProgress,
                  strokeWidth: _progressStrokeWidth,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: _stageOpacity),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStageColor(context, progress.stage),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(clampedProgress * 100).toInt()}%',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      _getStageLabel(progress.stage),
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: _spacingLarge),

          // Progress message
          if (progress.message != null)
            Text(
              progress.message!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: _spacingMedium),

          // Stage indicator
          _StageIndicator(currentStage: progress.stage),

          // Estimated time remaining
          if (progress.estimatedTimeRemaining != null)
            Padding(
              padding: const EdgeInsets.only(top: _spacingMedium),
              child: Text(
                'Time remaining: ${DurationFormatter.formatTimeRemaining(progress.estimatedTimeRemaining!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStageColor(BuildContext context, ProcessingStage stage) {
    return switch (stage) {
      ProcessingStage.analyzing => Colors.blue,
      ProcessingStage.promptEngineering => Colors.orange,
      ProcessingStage.aiProcessing => Theme.of(context).colorScheme.primary,
      ProcessingStage.postProcessing => Colors.green,
      ProcessingStage.completed => Theme.of(context).colorScheme.primary,
    };
  }

  String _getStageLabel(ProcessingStage stage) {
    return _stageLabels[stage] ?? 'Unknown';
  }
}

class _StageIndicator extends StatelessWidget {
  const _StageIndicator({required this.currentStage});

  final ProcessingStage currentStage;

  // Constants for stage indicator
  static const double _dotSize = 8.0;
  static const double _connectorWidth = 20.0;
  static const double _connectorHeight = 1.0;
  static const double _borderRadius = 20.0;
  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 12.0;
  static const double _connectorMargin = 4.0;
  static const double _opacity = 0.3;
  static const double _connectorOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final stages = ProcessingStage.values
        .where((stage) => stage != ProcessingStage.completed)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: stages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          final isActive = _getStageIndex(currentStage) >= index;

          return Row(
            children: [
              Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? _getStageColor(context, stage)
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: _opacity),
                ),
              ),
              if (index < stages.length - 1) ...[
                Container(
                  width: _connectorWidth,
                  height: _connectorHeight,
                  color: isActive
                      ? _getStageColor(context, stage)
                          .withOpacity(_connectorOpacity)
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(_opacity),
                  margin:
                      const EdgeInsets.symmetric(horizontal: _connectorMargin),
                ),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStageColor(BuildContext context, ProcessingStage stage) {
    return switch (stage) {
      ProcessingStage.analyzing => Colors.blue,
      ProcessingStage.promptEngineering => Colors.orange,
      ProcessingStage.aiProcessing => Theme.of(context).colorScheme.primary,
      ProcessingStage.postProcessing => Colors.green,
      ProcessingStage.completed => Theme.of(context).colorScheme.primary,
    };
  }

  int _getStageIndex(ProcessingStage stage) {
    return switch (stage) {
      ProcessingStage.analyzing => 0,
      ProcessingStage.promptEngineering => 1,
      ProcessingStage.aiProcessing => 2,
      ProcessingStage.postProcessing => 3,
      ProcessingStage.completed => 4,
    };
  }
}
