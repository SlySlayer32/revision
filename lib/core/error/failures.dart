import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() =>
      'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code]);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure(super.message, [super.code]);
}

class AIProcessingFailure extends Failure {
  const AIProcessingFailure(super.message, [super.code]);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}

class DeviceFailure extends Failure {
  const DeviceFailure(super.message, [super.code]);
}

class ImageSelectionFailure extends Failure {
  const ImageSelectionFailure(super.message, [super.code]);
}

class CameraAccessFailure extends Failure {
  const CameraAccessFailure(super.message, [super.code]);
}

class GalleryAccessFailure extends Failure {
  const GalleryAccessFailure(super.message, [super.code]);
}
