import 'dart:async';

/// A token that can be used to cancel long-running operations
class CancellationToken {
  CancellationToken() : _completer = Completer<void>();

  final Completer<void> _completer;
  String? _reason;
  DateTime? _cancelledAt;

  /// Whether this token has been cancelled
  bool get isCancelled => _completer.isCompleted;

  /// The reason for cancellation, if any
  String? get reason => _reason;

  /// When the token was cancelled
  DateTime? get cancelledAt => _cancelledAt;

  /// Future that completes when the token is cancelled
  Future<void> get future => _completer.future;

  /// Cancels the token with an optional reason
  void cancel([String? reason]) {
    if (!_completer.isCompleted) {
      _reason = reason ?? 'Operation cancelled';
      _cancelledAt = DateTime.now();
      _completer.complete();
    }
  }

  /// Throws if the token has been cancelled
  void throwIfCancelled() {
    if (isCancelled) {
      throw OperationCancelledException(_reason ?? 'Operation cancelled');
    }
  }

  /// Creates a new token that will be cancelled after the given duration
  static CancellationToken timeout(Duration duration) {
    final token = CancellationToken();
    Timer(duration, () => token.cancel('Operation timed out'));
    return token;
  }

  /// Creates a new token that will be cancelled when any of the given tokens are cancelled
  static CancellationToken any(List<CancellationToken> tokens) {
    final token = CancellationToken();
    
    for (final t in tokens) {
      if (t.isCancelled) {
        token.cancel(t.reason);
        break;
      } else {
        t.future.then((_) {
          if (!token.isCancelled) {
            token.cancel(t.reason);
          }
        });
      }
    }
    
    return token;
  }
}

/// Exception thrown when an operation is cancelled
class OperationCancelledException implements Exception {
  const OperationCancelledException(this.message);
  
  final String message;
  
  @override
  String toString() => 'OperationCancelledException: $message';
}

/// A cancellation token source that can create and control cancellation tokens
class CancellationTokenSource {
  CancellationTokenSource() : _token = CancellationToken();

  CancellationToken _token;

  /// The current cancellation token
  CancellationToken get token => _token;

  /// Whether the token has been cancelled
  bool get isCancelled => _token.isCancelled;

  /// Cancels the current token
  void cancel([String? reason]) {
    _token.cancel(reason);
  }

  /// Creates a new token, replacing the current one
  void reset() {
    _token = CancellationToken();
  }

  /// Cancels the current token and creates a new one
  void cancelAndReset([String? reason]) {
    _token.cancel(reason);
    _token = CancellationToken();
  }
}