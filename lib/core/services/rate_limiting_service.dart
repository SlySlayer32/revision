import 'dart:collection';
import 'dart:async';

/// Implements per-operation rate limiting with configurable windows.
class RateLimitingService {
  final int maxRequests;
  final Duration window;
  final _requestTimestamps = HashMap<String, List<DateTime>>();

  RateLimitingService({required this.maxRequests, required this.window});

  /// Returns true if the operation is allowed, false if rate limit exceeded.
  bool allow(String operation) {
    final now = DateTime.now();
    final timestamps = _requestTimestamps.putIfAbsent(operation, () => []);
    timestamps.removeWhere((t) => now.difference(t) > window);
    if (timestamps.length >= maxRequests) {
      return false;
    }
    timestamps.add(now);
    return true;
  }
}
