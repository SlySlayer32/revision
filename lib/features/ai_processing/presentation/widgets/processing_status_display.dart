import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_state.dart';

class ProcessingStatusDisplay extends StatelessWidget {
  const ProcessingStatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeminiPipelineCubit, GeminiPipelineState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${state.status.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (state.status == GeminiPipelineStatus.processing) ...[
              const LinearProgressIndicator(),
              if (state.progressMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(state.progressMessage!),
                ),
            ] else if (state.status == GeminiPipelineStatus.error)
              Text(
                state.errorMessage ?? 'An unknown error occurred.',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        );
      },
    );
  }
}
