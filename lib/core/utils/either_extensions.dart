import 'package:dartz/dartz.dart';

/// Extensions on Either for added functionality
extension EitherX<L, R> on Either<L, R> {
  /// Gets the right value if this is a Right, otherwise returns null
  R? get rightOrNull => fold((_) => null, (r) => r);

  /// Gets the left value if this is a Left, otherwise returns null
  L? get leftOrNull => fold((l) => l, (_) => null);

  /// Returns true if this is a Right
  bool get isRight => fold((_) => false, (_) => true);

  /// Returns true if this is a Left
  bool get isLeft => fold((_) => true, (_) => false);

  /// Pattern matches on Either. Similar to fold but with void functions.
  void when({
    required void Function(L left) left,
    required void Function(R right) right,
  }) {
    fold(left, right);
  }

  /// Maps the right value with the given function
  Either<L, T> mapRight<T>(T Function(R right) f) {
    return map(f);
  }

  /// Maps the left value with the given function
  Either<T, R> mapLeft<T>(T Function(L left) f) {
    return leftMap(f);
  }

  /// Transforms a Right value into a new Either
  Either<L, T> flatMapRight<T>(Either<L, T> Function(R right) f) {
    return flatMap(f);
  }

  /// Transforms a Left value into a new Either
  Either<T, R> flatMapLeft<T>(Either<T, R> Function(L left) f) {
    return fold(
      (l) => f(l),
      right,
    );
  }
}
