import 'package:flutter/material.dart';
import 'package:revision/features/ai_processing/domain/entities/image_marker.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/services/processing_context_builder.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/utils/annotation_converter.dart';

/// Controller for managing processing controls state
///
/// Separates state management logic from UI widgets following
/// VGV Clean Architecture principles for better testability.
class ProcessingControlsController extends ChangeNotifier {
  ProcessingControlsController({
    required this.onStartProcessing,
    this.annotatedImage,
  });

  final void Function(String prompt, ProcessingContext context)
  onStartProcessing;
  final AnnotatedImage? annotatedImage;

  final promptController = TextEditingController();

  // Private state variables
  ProcessingType _selectedType = ProcessingType.enhance;
  QualityLevel _selectedQuality = QualityLevel.standard;
  PerformancePriority _selectedPriority = PerformancePriority.balanced;
  String? _promptSystemInstructions;
  String? _editSystemInstructions;

  // Public getters
  ProcessingType get selectedType => _selectedType;
  QualityLevel get selectedQuality => _selectedQuality;
  PerformancePriority get selectedPriority => _selectedPriority;
  String? get promptSystemInstructions => _promptSystemInstructions;
  String? get editSystemInstructions => _editSystemInstructions;

  void initialize() {
    if (annotatedImage != null && annotatedImage!.hasAnnotations) {
      promptController.text = AnnotationConverter.generatePromptFromAnnotations(
        annotatedImage!.annotations,
        promptController.text,
      );
    }
  }

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  // Setters with validation and notification
  set selectedType(ProcessingType type) {
    if (_selectedType != type) {
      _selectedType = type;
      notifyListeners();
    }
  }

  set selectedQuality(QualityLevel quality) {
    if (_selectedQuality != quality) {
      _selectedQuality = quality;
      notifyListeners();
    }
  }

  set selectedPriority(PerformancePriority priority) {
    if (_selectedPriority != priority) {
      _selectedPriority = priority;
      notifyListeners();
    }
  }

  set promptSystemInstructions(String? instructions) {
    if (_promptSystemInstructions != instructions) {
      _promptSystemInstructions = instructions;
      notifyListeners();
    }
  }

  set editSystemInstructions(String? instructions) {
    if (_editSystemInstructions != instructions) {
      _editSystemInstructions = instructions;
      notifyListeners();
    }
  }

  /// Updates processing type based on available markers
  ///
  /// Automatically adjusts processing type when markers change
  void updateTypeForMarkers(List<ImageMarker> markers) {
    final recommendedType = ProcessingContextBuilder.getRecommendedType(
      markers,
    );
    if (_selectedType != recommendedType) {
      selectedType = recommendedType;
    }
  }

  /// Validates current settings combination
  ///
  /// Returns true if the current settings are valid
  bool isValidCombination(List<ImageMarker> markers) {
    return ProcessingContextBuilder.isValidCombination(
      type: _selectedType,
      quality: _selectedQuality,
      priority: _selectedPriority,
      markers: markers,
    );
  }

  /// Builds processing context from current state
  ///
  /// Creates a validated ProcessingContext with current settings
  ProcessingContext buildContext(List<ImageMarker> markers) {
    return ProcessingContextBuilder.build(
      type: _selectedType,
      quality: _selectedQuality,
      priority: _selectedPriority,
      markers: markers,
      promptInstructions: _promptSystemInstructions,
      editInstructions: _editSystemInstructions,
    );
  }

  /// Resets all settings to defaults
  void reset() {
    _selectedType = ProcessingType.enhance;
    _selectedQuality = QualityLevel.standard;
    _selectedPriority = PerformancePriority.balanced;
    _promptSystemInstructions = null;
    _editSystemInstructions = null;
    notifyListeners();
  }

  /// Gets validation message for current settings
  ///
  /// Returns null if valid, error message if invalid
  String? getValidationMessage(List<ImageMarker> markers) {
    if (!isValidCombination(markers)) {
      if (_selectedType == ProcessingType.objectRemoval && markers.isEmpty) {
        return 'Object removal requires marking objects in the image first';
      }
      if (_selectedType == ProcessingType.backgroundChange && markers.isEmpty) {
        return 'Background change requires marking areas in the image first';
      }
      if (_selectedQuality == QualityLevel.professional &&
          _selectedPriority == PerformancePriority.speed) {
        return 'Professional quality is not available with speed priority - consider balanced priority';
      }
    }
    return null;
  }

  void startProcessing() {
    final List<ImageMarker> markers =
        annotatedImage != null && annotatedImage!.hasAnnotations
        ? AnnotationConverter.annotationsToMarkers(annotatedImage!.annotations)
        : <ImageMarker>[];

    final context = ProcessingContextBuilder.build(
      type: _selectedType,
      quality: _selectedQuality,
      priority: _selectedPriority,
      markers: markers,
      promptInstructions: _promptSystemInstructions,
      editInstructions: _editSystemInstructions,
    );

    onStartProcessing(promptController.text.trim(), context);
  }
}
