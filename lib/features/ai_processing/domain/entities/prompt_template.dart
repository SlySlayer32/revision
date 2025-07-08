import 'package:equatable/equatable.dart';

/// Represents an AI prompt template for specific image processing types
class PromptTemplate extends Equatable {
  const PromptTemplate({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.userPromptTemplate,
    required this.processingType,
    required this.qualityInstructions,
    this.examples = const [],
    this.constraints = const [],
  });

  final String id;
  final String name;
  final String systemPrompt;
  final String userPromptTemplate;
  final String processingType;
  final String qualityInstructions;
  final List<String> examples;
  final List<String> constraints;

  @override
  List<Object?> get props => [
    id,
    name,
    systemPrompt,
    userPromptTemplate,
    processingType,
    qualityInstructions,
    examples,
    constraints,
  ];
}

/// Result of prompt validation
class ValidationResult extends Equatable {
  const ValidationResult({required this.isValid, this.issues = const []});

  final bool isValid;
  final List<ValidationIssue> issues;

  @override
  List<Object?> get props => [isValid, issues];
}

/// Individual validation issue
class ValidationIssue extends Equatable {
  const ValidationIssue({
    required this.type,
    required this.message,
    this.suggestion,
  });

  final ValidationIssueType type;
  final String message;
  final String? suggestion;

  @override
  List<Object?> get props => [type, message, suggestion];
}

enum ValidationIssueType { error, warning, info }
