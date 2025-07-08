import 'package:flutter/material.dart';

/// Widget for configuring system instructions for AI models.
///
/// This allows developers to quickly modify prompts for rapid development
/// and prompt engineering without changing code.
class SystemInstructionsPanel extends StatefulWidget {
  const SystemInstructionsPanel({
    required this.onPromptSystemInstructionsChanged,
    required this.onEditSystemInstructionsChanged,
    this.initialPromptSystemInstructions,
    this.initialEditSystemInstructions,
    super.key,
  });

  final ValueChanged<String?> onPromptSystemInstructionsChanged;
  final ValueChanged<String?> onEditSystemInstructionsChanged;
  final String? initialPromptSystemInstructions;
  final String? initialEditSystemInstructions;

  @override
  State<SystemInstructionsPanel> createState() =>
      _SystemInstructionsPanelState();
}

class _SystemInstructionsPanelState extends State<SystemInstructionsPanel> {
  late TextEditingController _promptController;
  late TextEditingController _editController;
  bool _isExpanded = false;

  static const String _defaultPromptInstructions =
      '''You are an expert image analysis AI that creates detailed prompts for image editing.

Your task is to analyze the uploaded image and the user's requested changes, then create a clear, specific prompt for an image editing AI.

Guidelines:
- Be specific about colors, styles, objects, and spatial relationships
- Include technical details like lighting, composition, and style
- Maintain the original image's essence while incorporating requested changes
- Output only the editing prompt, no explanations

Example format: "Edit this [description of image] by [specific changes requested], maintaining [key aspects to preserve], with [style/technical specifications]"''';

  static const String _defaultEditInstructions =
      '''You are a professional image editing AI that creates high-quality edited images.

Your task is to apply the requested changes to the provided image with precision and artistic quality.

Guidelines:
- Maintain natural lighting and shadows
- Preserve image quality and resolution
- Ensure seamless integration of edits
- Apply changes realistically and artistically
- Maintain consistent style throughout the image

Focus on quality, realism, and artistic coherence in all edits.''';

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text:
          widget.initialPromptSystemInstructions ?? _defaultPromptInstructions,
    );
    _editController = TextEditingController(
      text: widget.initialEditSystemInstructions ?? _defaultEditInstructions,
    );

    _promptController.addListener(() {
      widget.onPromptSystemInstructionsChanged(
        _promptController.text.trim().isEmpty ? null : _promptController.text,
      );
    });

    _editController.addListener(() {
      widget.onEditSystemInstructionsChanged(
        _editController.text.trim().isEmpty ? null : _editController.text,
      );
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Header with expand/collapse button
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_applications,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Advanced: System Instructions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Customize AI behavior for rapid prompt engineering during development.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Prompt Generation Instructions
                  _buildInstructionField(
                    title: 'Prompt Generation System Instructions',
                    subtitle:
                        'Instructions for the AI that analyzes images and creates editing prompts',
                    controller: _promptController,
                    onReset: () =>
                        _promptController.text = _defaultPromptInstructions,
                  ),

                  const SizedBox(height: 16),

                  // Image Editing Instructions
                  _buildInstructionField(
                    title: 'Image Editing System Instructions',
                    subtitle:
                        'Instructions for the AI that performs the actual image editing',
                    controller: _editController,
                    onReset: () =>
                        _editController.text = _defaultEditInstructions,
                  ),

                  const SizedBox(height: 16),

                  // Quick actions
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset All'),
                      ),
                      TextButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionField({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required VoidCallback onReset,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt, size: 18),
              tooltip: 'Reset to default',
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 8,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter system instructions...',
            contentPadding: const EdgeInsets.all(12),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  void _resetToDefaults() {
    setState(() {
      _promptController.text = _defaultPromptInstructions;
      _editController.text = _defaultEditInstructions;
    });
  }

  void _clearAll() {
    setState(() {
      _promptController.clear();
      _editController.clear();
    });
  }
}
