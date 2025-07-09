import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_state.dart';
import 'package:revision/features/ai_processing/domain/entities/enhanced_processing_progress.dart';

class ProcessingStatusDisplay extends StatelessWidget {
  const ProcessingStatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeminiPipelineCubit, GeminiPipelineState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(context, state),
                const SizedBox(height: 12),
                if (state.isProcessing) ...[
                  _buildProgressIndicator(context, state),
                  const SizedBox(height: 8),
                  _buildProgressDetails(context, state),
                  if (state.isCancellable) ...[
                    const SizedBox(height: 16),
                    _buildCancelButton(context, state),
                  ],
                ] else if (state.status == GeminiPipelineStatus.error) ...[
                  _buildErrorDisplay(context, state),
                ] else if (state.status == GeminiPipelineStatus.cancelled) ...[
                  _buildCancelledDisplay(context, state),
                ] else if (state.status == GeminiPipelineStatus.success) ...[
                  _buildSuccessDisplay(context, state),
                ],
                if (state.processingDuration != null) ...[
                  const SizedBox(height: 8),
                  _buildDurationDisplay(context, state.processingDuration!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(BuildContext context, GeminiPipelineState state) {
    final theme = Theme.of(context);
    final statusText = state.status.name.toUpperCase();
    final statusColor = _getStatusColor(theme, state.status);
    final statusIcon = _getStatusIcon(state.status);

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (state.requestId != null) ...[
          Text(
            'ID: ${state.requestId!.substring(0, 8)}...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context, GeminiPipelineState state) {
    final progress = state.detailedProgress;
    if (progress == null) {
      return const LinearProgressIndicator();
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress.progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.progressPercentage}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (progress.estimatedTimeRemaining != null)
              Text(
                '~${_formatDuration(progress.estimatedTimeRemaining!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressDetails(BuildContext context, GeminiPipelineState state) {
    final progress = state.detailedProgress;
    if (progress == null) {
      return Text(
        state.progressMessage ?? 'Processing...',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              progress.stage.icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              progress.stage.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (progress.message != null) ...[
          const SizedBox(height: 4),
          Text(
            progress.message!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (progress.totalSteps > 1) ...[
          const SizedBox(height: 4),
          Text(
            'Step ${progress.currentStepIndex + 1} of ${progress.totalSteps}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, GeminiPipelineState state) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<GeminiPipelineCubit>().cancelProcessing();
        },
        icon: const Icon(Icons.cancel),
        label: const Text('Cancel Processing'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(BuildContext context, GeminiPipelineState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage ?? 'An unknown error occurred.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledDisplay(BuildContext context, GeminiPipelineState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cancel,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.cancellationToken?.reason ?? 'Processing was cancelled.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDisplay(BuildContext context, GeminiPipelineState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Processing completed successfully!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationDisplay(BuildContext context, Duration duration) {
    return Text(
      'Duration: ${_formatDuration(duration)}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, GeminiPipelineStatus status) {
    switch (status) {
      case GeminiPipelineStatus.initial:
        return theme.colorScheme.onSurfaceVariant;
      case GeminiPipelineStatus.processing:
        return theme.colorScheme.primary;
      case GeminiPipelineStatus.success:
        return theme.colorScheme.primary;
      case GeminiPipelineStatus.error:
        return theme.colorScheme.error;
      case GeminiPipelineStatus.cancelled:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(GeminiPipelineStatus status) {
    switch (status) {
      case GeminiPipelineStatus.initial:
        return Icons.radio_button_unchecked;
      case GeminiPipelineStatus.processing:
        return Icons.autorenew;
      case GeminiPipelineStatus.success:
        return Icons.check_circle;
      case GeminiPipelineStatus.error:
        return Icons.error;
      case GeminiPipelineStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
