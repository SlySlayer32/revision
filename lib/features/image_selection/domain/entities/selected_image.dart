import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';

/// Represents a selected image with metadata and validation capabilities.
///
/// This entity encapsulates all the information about an image selected
/// by the user, including file details, validation methods, and metadata.
class SelectedImage extends Equatable {
  /// Creates a [SelectedImage] instance.
  const SelectedImage({
    this.path,
    this.bytes,
    required this.name,
    required this.sizeInBytes,
    required this.source,
  }) : assert(
         path != null || bytes != null,
         'Either path or bytes must be provided',
       );

  /// The file path of the selected image (mobile only)
  final String? path;

  /// The raw bytes of the image (web)
  final Uint8List? bytes;

  /// The name of the image file
  final String name;

  /// Size of the image file in bytes
  final int sizeInBytes;

  /// Source where the image was selected from
  final ImageSource source;

  /// Gets File object for the image
  File? get file => path != null ? File(path!) : null;

  /// Size in megabytes for easier display
  double get sizeInMB => sizeInBytes / (1024 * 1024);

  /// Check if file is large (over 10MB)
  bool get isLargeFile => sizeInMB > 10;

  /// Check if the image format is valid
  bool get isValidFormat {
    final extension = name.toLowerCase().split('.').last;
    const validFormats = ['jpg', 'jpeg', 'png', 'heic', 'webp'];
    return validFormats.contains(extension);
  }

  /// Check if image is valid (size and format)
  bool get isValid =>
      isValidFormat && sizeInBytes <= (50 * 1024 * 1024); // 50MB limit

  /// Create copy with updated fields
  SelectedImage copyWith({
    String? path,
    Uint8List? bytes,
    String? name,
    int? sizeInBytes,
    ImageSource? source,
  }) {
    return SelectedImage(
      path: path ?? this.path,
      bytes: bytes ?? this.bytes,
      name: name ?? this.name,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [path, bytes, name, sizeInBytes, source];

  @override
  String toString() {
    return 'SelectedImage('
        'path: $path, '
        'bytes: ${bytes?.lengthInBytes}, '
        'name: $name, '
        'sizeInMB: ${sizeInMB.toStringAsFixed(2)}, '
        'source: $source'
        ')';
  }
}
