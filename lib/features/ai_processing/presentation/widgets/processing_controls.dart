import 'package:flutter/material.dart';
import 'package:revision/features/ai_processing/presentation/constants/ui_constants.dart';
import 'package:revision/features/ai_processing/presentation/controllers/processing_controls_controller.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/presentation/widgets/system_instructions_panel.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Widget for controlling AI processing parameters and starting processing.
class ProcessingControls extends StatefulWidget {
  const ProcessingControls({
    required this.selectedImage,
    required this.onStartProcessing,
    this.annotatedImage,
    super.key,
  });

  final SelectedImage selectedImage;
  final AnnotatedImage? annotatedImage;
  final void Function(String prompt, ProcessingContext context)
      onStartProcessing;

  @override
  State<ProcessingControls> createState() => _ProcessingControlsState();
}

class _ProcessingControlsState extends State<ProcessingControls> {
  late final ProcessingControlsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProcessingControlsController(
      onStartProcessing: widget.onStartProcessing,
      annotatedImage: widget.annotatedImage,
    )..addListener(_rebuild);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prompt input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Describe your desired transformation:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller.promptController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g., "Make this image more vibrant with better contrast"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Processing options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processing Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Processing type
                  _buildDropdown<ProcessingType>(
                    label: 'Effect Type',
                    value: _controller.selectedType,
                    items: ProcessingType.values,
                    onChanged: (value) => _controller.selectedType = value!,
                    itemBuilder: (type) =>
                        ProcessingUIConstants.processingTypeLabels[type.name]!,
                  ),

                  const SizedBox(height: 16),

                  // Quality level
                  _buildDropdown<QualityLevel>(
                    label: 'Quality Level',
                    value: _controller.selectedQuality,
                    items: QualityLevel.values,
                    onChanged: (value) => _controller.selectedQuality = value!,
                    itemBuilder: (quality) =>
                        ProcessingUIConstants.qualityLevelLabels[quality.name]!,
                  ),

                  const SizedBox(height: 16),

                  // Performance priority
                  _buildDropdown<PerformancePriority>(
                    label: 'Priority',
                    value: _controller.selectedPriority,
                    items: PerformancePriority.values,
                    onChanged: (value) => _controller.selectedPriority = value!,
                    itemBuilder: (priority) => ProcessingUIConstants
                        .performancePriorityLabels[priority.name]!,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // System Instructions Panel
          SystemInstructionsPanel(
            onPromptSystemInstructionsChanged: (instructions) {
              _controller.promptSystemInstructions = instructions;
            },
            onEditSystemInstructionsChanged: (instructions) {
              _controller.editSystemInstructions = instructions;
            },
            initialPromptSystemInstructions:
                _controller.promptSystemInstructions,
            initialEditSystemInstructions: _controller.editSystemInstructions,
          ),

          const SizedBox(height: 24),

          // Start processing button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller.promptController,
            builder: (context, value, child) {
              return ElevatedButton.icon(
                onPressed: value.text.trim().isEmpty
                    ? null
                    : _controller.startProcessing,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Start AI Processing'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemBuilder(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}
