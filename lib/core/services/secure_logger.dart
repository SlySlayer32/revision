import 'dart:developer';

/// SecureLogger automatically masks sensitive information in log messages.
class SecureLogger {
  static final _sensitivePatterns = [
    RegExp(r'AIza[0-9A-Za-z-_]{30,}'), // Google API keys
    RegExp(r'(?i)api[_-]?key\s*[:=]\s*([\w-]+)'),
    RegExp(r'(?i)token\s*[:=]\s*([\w-]+)'),
  ];

  /// Logs a message, masking sensitive data.
  static void log(String message) {
    String masked = message;
    for (final pattern in _sensitivePatterns) {
      masked = masked.replaceAllMapped(pattern, (m) {
        final match = m.group(0)!;
        return match.substring(0, 4) + '****' + match.substring(match.length - 4);
      });
    }
    logMessage(masked);
  }

  static void logMessage(String message) {
    log(message);
  }
}
