/// A class that represents the result of an operation that can either succeed
/// or fail.
sealed class Result<T> {
  const Result();

  /// Executes the appropriate callback based on whether this is a [Success]
  /// or [Failure]
  void when({
    required void Function(T value) success,
    required void Function(Exception exception) failure,
  }) {
    switch (this) {
      case Success<T>(data: final value):
        success(value);
      case Failure<T>(exception: final exception):
        failure(exception);
    }
  }

  /// Returns the result of the successful callback if this is a [Success],
  /// otherwise returns the result of the failure callback
  R fold<R>({
    required R Function(T value) success,
    required R Function(Exception exception) failure,
  }) {
    return switch (this) {
      Success<T>(data: final value) => success(value),
      Failure<T>(exception: final exception) => failure(exception),
    };
  }

  /// Returns the value if this is a [Success], otherwise returns null
  T? get valueOrNull => switch (this) {
        Success<T>(data: final value) => value,
        Failure<T>() => null,
      };

  /// Returns the exception if this is a [Failure], otherwise returns null
  Exception? get exceptionOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(exception: final exception) => exception,
      };

  /// Returns true if this is a [Success], otherwise returns false
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a [Failure], otherwise returns false
  bool get isFailure => this is Failure<T>;

  /// Maps the value if this is a [Success], otherwise returns this
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(data: final value) => Success(transform(value)),
      Failure<T>(exception: final exception) => Failure<R>(exception),
    };
  }

  /// Maps the exception if this is a [Failure], otherwise returns this
  Result<T> mapError(Exception Function(Exception exception) transform) {
    return switch (this) {
      Success<T>() => this,
      Failure<T>(exception: final exception) =>
        Failure<T>(transform(exception)),
    };
  }

  /// Flat maps the value if this is a [Success], otherwise returns this
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success<T>(data: final value) => transform(value),
      Failure<T>(exception: final exception) => Failure<R>(exception),
    };
  }
}

/// Represents a successful operation with data of type [T].
final class Success<T> extends Result<T> {
  /// Creates a new [Success] with the provided [data].
  const Success(this.data);

  /// The data returned by the successful operation.
  final T data;

  /// The value (alias for data for backward compatibility)
  T get value => data;
}

/// Represents a failed operation with an [Exception].
final class Failure<T> extends Result<T> {
  /// Creates a new [Failure] with the provided [exception].
  const Failure(this.exception);

  /// The exception that caused the operation to fail.
  final Exception exception;
}
