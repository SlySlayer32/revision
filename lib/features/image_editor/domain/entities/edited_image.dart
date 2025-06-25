import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Represents an image being edited with markers and processing status
class EditedImage extends Equatable {
  const EditedImage({
    required this.id,
    required this.originalImageData,
    required this.originalPath,
    required this.markers,
    required this.createdAt,
    this.processedImageData,
    this.processedPath,
    this.modifiedAt,
    this.processingStatus = ProcessingStatus.pending,
    this.aiPrompt,
  });

  final String id;
  final Uint8List originalImageData;
  final String originalPath;
  final List<ImageMarker> markers;
  final Uint8List? processedImageData;
  final String? processedPath;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final ProcessingStatus processingStatus;
  final String? aiPrompt;

  @override
  List<Object?> get props => [
        id,
        originalImageData,
        originalPath,
        markers,
        processedImageData,
        processedPath,
        createdAt,
        modifiedAt,
        processingStatus,
        aiPrompt,
      ];

  EditedImage copyWith({
    String? id,
    Uint8List? originalImageData,
    String? originalPath,
    List<ImageMarker>? markers,
    Uint8List? processedImageData,
    String? processedPath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    ProcessingStatus? processingStatus,
    String? aiPrompt,
  }) {
    return EditedImage(
      id: id ?? this.id,
      originalImageData: originalImageData ?? this.originalImageData,
      originalPath: originalPath ?? this.originalPath,
      markers: markers ?? this.markers,
      processedImageData: processedImageData ?? this.processedImageData,
      processedPath: processedPath ?? this.processedPath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      processingStatus: processingStatus ?? this.processingStatus,
      aiPrompt: aiPrompt ?? this.aiPrompt,
    );
  }
}

enum ProcessingStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Simple marker for MVP - can be expanded later
class ImageMarker extends Equatable {
  const ImageMarker({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    this.label,
  });

  final String id;
  final double x;
  final double y;
  final MarkerType type;
  final String? label;

  @override
  List<Object?> get props => [id, x, y, type, label];
}

enum MarkerType {
  userDefined,
  aiDetected,
}
