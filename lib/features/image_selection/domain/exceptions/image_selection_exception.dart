import 'package:equatable/equatable.dart';

/// Base exception for image selection operations
sealed class ImageSelectionException extends Equatable implements Exception {
  const ImageSelectionException(this.message, this.code);

  const factory ImageSelectionException.permissionDenied(String message) =
      PermissionDeniedException;
  const factory ImageSelectionException.fileNotFound(String message) =
      FileNotFoundException;
  const factory ImageSelectionException.fileTooLarge(String message) =
      FileTooLargeException;
  const factory ImageSelectionException.invalidFormat(String message) =
      InvalidFormatException;
  const factory ImageSelectionException.cameraUnavailable(String message) =
      CameraUnavailableException;
  const factory ImageSelectionException.cancelled(String message) =
      CancelledException;
  const factory ImageSelectionException.unknown(String message) =
      UnknownException;

  final String message;
  final String code;

  @override
  List<Object> get props => [message, code];

  @override
  String toString() => 'ImageSelectionException: $message ($code)';
}

final class PermissionDeniedException extends ImageSelectionException {
  const PermissionDeniedException(String message)
    : super(message, 'permission_denied');
}

final class FileNotFoundException extends ImageSelectionException {
  const FileNotFoundException(String message)
    : super(message, 'file_not_found');
}

final class FileTooLargeException extends ImageSelectionException {
  const FileTooLargeException(String message)
    : super(message, 'file_too_large');
}

final class InvalidFormatException extends ImageSelectionException {
  const InvalidFormatException(String message)
    : super(message, 'invalid_format');
}

final class CameraUnavailableException extends ImageSelectionException {
  const CameraUnavailableException(String message)
    : super(message, 'camera_unavailable');
}

final class CancelledException extends ImageSelectionException {
  const CancelledException(String message) : super(message, 'cancelled');
}

final class UnknownException extends ImageSelectionException {
  const UnknownException(String message) : super(message, 'unknown');
}
