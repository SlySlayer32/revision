import 'package:flutter/material.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/presentation/widgets/system_instructions_panel.dart';
import 'package:revision/features/ai_processing/domain/entities/image_marker.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/utils/annotation_converter.dart';
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
  final TextEditingController _promptController = TextEditingController();
  ProcessingType _selectedType = ProcessingType.enhance;
  QualityLevel _selectedQuality = QualityLevel.standard;
  PerformancePriority _selectedPriority = PerformancePriority.balanced;
  String? _promptSystemInstructions;
  String? _editSystemInstructions;
  @override
  void initState() {
    super.initState();

    // Pre-populate prompt if we have annotation data
    if (widget.annotatedImage != null &&
        widget.annotatedImage!.hasAnnotations) {
      _promptController.text =
          AnnotationConverter.generatePromptFromAnnotations(
        widget.annotatedImage!.annotations,
        _promptController.text,
      );
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
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
                    controller: _promptController,
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
                    value: _selectedType,
                    items: ProcessingType.values,
                    onChanged: (value) =>
                        setState(() => _selectedType = value!),
                    itemBuilder: _getProcessingTypeLabel,
                  ),

                  const SizedBox(height: 16),

                  // Quality level
                  _buildDropdown<QualityLevel>(
                    label: 'Quality Level',
                    value: _selectedQuality,
                    items: QualityLevel.values,
                    onChanged: (value) =>
                        setState(() => _selectedQuality = value!),
                    itemBuilder: _getQualityLevelLabel,
                  ),

                  const SizedBox(height: 16),

                  // Performance priority
                  _buildDropdown<PerformancePriority>(
                    label: 'Priority',
                    value: _selectedPriority,
                    items: PerformancePriority.values,
                    onChanged: (value) =>
                        setState(() => _selectedPriority = value!),
                    itemBuilder: _getPerformancePriorityLabel,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // System Instructions Panel
          SystemInstructionsPanel(
            onPromptSystemInstructionsChanged: (instructions) {
              setState(() {
                _promptSystemInstructions = instructions;
              });
            },
            onEditSystemInstructionsChanged: (instructions) {
              setState(() {
                _editSystemInstructions = instructions;
              });
            },
            initialPromptSystemInstructions: _promptSystemInstructions,
            initialEditSystemInstructions: _editSystemInstructions,
          ),

          const SizedBox(height: 24),

          // Start processing button
          ElevatedButton.icon(
            onPressed:
                _promptController.text.trim().isEmpty ? null : _startProcessing,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Start AI Processing'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
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

  void _startProcessing() {
    // Convert annotations to markers if available
    final markers =
        widget.annotatedImage != null && widget.annotatedImage!.hasAnnotations
            ? AnnotationConverter.annotationsToMarkers(widget.annotatedImage!.annotations)
            : <ImageMarker>[];

    final context = ProcessingContext(
      processingType: _selectedType,
      qualityLevel: _selectedQuality,
      performancePriority: _selectedPriority,
      promptSystemInstructions: _promptSystemInstructions,
      editSystemInstructions: _editSystemInstructions,
      markers: markers,
    );

    widget.onStartProcessing(_promptController.text.trim(), context);
  }

  String _getProcessingTypeLabel(ProcessingType type) {
    return switch (type) {
      ProcessingType.enhance => 'Enhance',
      ProcessingType.artistic => 'Artistic Style',
      ProcessingType.restoration => 'Restore',
      ProcessingType.colorCorrection => 'Color Correction',
      ProcessingType.objectRemoval => 'Object Removal',
      ProcessingType.backgroundChange => 'Background Change',
      ProcessingType.faceEdit => 'Face Edit',
      ProcessingType.custom => 'Custom',
    };
  }

  String _getQualityLevelLabel(QualityLevel quality) {
    return switch (quality) {
      QualityLevel.draft => 'Draft (Fast)',
      QualityLevel.standard => 'Standard',
      QualityLevel.high => 'High Quality',
      QualityLevel.professional => 'Professional',
    };
  }

  String _getPerformancePriorityLabel(PerformancePriority priority) {
    return switch (priority) {
      PerformancePriority.speed => 'Speed',
      PerformancePriority.balanced => 'Balanced',
      PerformancePriority.quality => 'Quality',
    };
  }
}
