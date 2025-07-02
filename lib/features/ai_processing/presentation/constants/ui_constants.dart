/// UI Constants for AI Processing components
/// 
/// Centralizes all user-facing strings and UI configuration
/// for better maintainability and internationalization support.
abstract class ProcessingUIConstants {
  // Prompt input section
  static const String promptLabel = 'Describe your desired transformation:';
  static const String promptHint = 'e.g., "Make this image more vibrant with better contrast"';
  
  // Processing options section
  static const String optionsLabel = 'Processing Options';
  static const String effectTypeLabel = 'Effect Type';
  static const String qualityLevelLabel = 'Quality Level';
  static const String priorityLabel = 'Priority';
  
  // Button labels
  static const String startButtonLabel = 'Start AI Processing';
  static const String startButtonIcon = 'auto_fix_high';
  
  // Processing type labels
  static const Map<String, String> processingTypeLabels = {
    'enhance': 'Enhance',
    'artistic': 'Artistic Style',
    'restoration': 'Restore',
    'colorCorrection': 'Color Correction',
    'objectRemoval': 'Object Removal',
    'backgroundChange': 'Background Change',
    'faceEdit': 'Face Edit',
    'custom': 'Custom',
  };
  
  // Quality level labels
  static const Map<String, String> qualityLevelLabels = {
    'draft': 'Draft (Fast)',
    'standard': 'Standard',
    'high': 'High Quality',
    'professional': 'Professional',
  };
  
  // Performance priority labels
  static const Map<String, String> performancePriorityLabels = {
    'speed': 'Speed',
    'balanced': 'Balanced',
    'quality': 'Quality',
  };
  
  // Validation messages
  static const String objectRemovalRequiresMarkersMessage = 
      'Object removal requires marking objects in the image first';
  static const String backgroundChangeRequiresMarkersMessage = 
      'Background change requires marking areas in the image first';
  static const String professionalQualitySpeedPriorityMessage = 
      'Professional quality is not available with speed priority - consider balanced priority';
  
  // Padding and sizing
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 16.0;
  static const double fieldSpacing = 8.0;
  static const double dropdownContentPadding = 12.0;
  static const double dropdownVerticalPadding = 8.0;
  static const double buttonVerticalPadding = 16.0;
  static const double buttonTextSize = 16.0;
  static const int promptMaxLines = 3;
}

/// Processing-specific business constants
abstract class ProcessingBusinessConstants {
  // Default selections
  static const defaultProcessingType = 'enhance';
  static const defaultQualityLevel = 'standard';
  static const defaultPerformancePriority = 'balanced';
  
  // Processing constraints
  static const int maxPromptLength = 500;
  static const int maxSystemInstructionsLength = 1000;
  static const int maxMarkersForProcessing = 50;
  
  // Timeout configurations
  static const Duration promptValidationDelay = Duration(milliseconds: 300);
  static const Duration settingsChangeDelay = Duration(milliseconds: 100);
}
