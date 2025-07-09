/// Tracks all security-sensitive operations for audit logging.
class SecurityAuditService {
  final List<String> _events = [];

  void logEvent(String eventType, {String? context, String? hash}) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp][$eventType]${context != null ? ' $context' : ''}${hash != null ? ' [hash:$hash]' : ''}';
    _events.add(entry);
    // In production, send to secure log storage
  }

  List<String> get events => List.unmodifiable(_events);
}
