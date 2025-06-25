/// Utility class for formatting duration objects into human-readable strings.
class DurationFormatter {
  DurationFormatter._();

  /// Formats a duration into a human-readable time remaining string.
  ///
  /// Examples:
  /// - 90 seconds -> "1m 30s"
  /// - 45 seconds -> "45s"
  /// - 0 seconds -> "0s"
  static String formatTimeRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formats a duration into a verbose string with hours, minutes, and seconds.
  ///
  /// Examples:
  /// - 3665 seconds -> "1h 1m 5s"
  /// - 125 seconds -> "2m 5s"
  /// - 30 seconds -> "30s"
  static String formatVerbose(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formats a duration into a compact string for UI display.
  ///
  /// Examples:
  /// - 3665 seconds -> "1:01:05"
  /// - 125 seconds -> "2:05"
  /// - 30 seconds -> "0:30"
  static String formatCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(1, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}
