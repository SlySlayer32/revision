import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:revision/core/services/secure_api_key_manager.dart';
import 'package:revision/core/services/secure_logger.dart';

/// Secure request handler for API calls
class SecureRequestHandler {
  static const String _userAgent = 'RevisionApp/1.0.0';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Make a secure HTTP POST request with proper headers and validation
  static Future<http.Response> makeSecureRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    required String operation,
    Duration? timeout,
    Map<String, String>? additionalHeaders,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Get secure API key
      final apiKey = SecureAPIKeyManager.getSecureApiKey();
      if (apiKey == null) {
        throw SecurityException('API key not available');
      }

      // Build secure headers
      final headers = _buildSecureHeaders(apiKey, additionalHeaders);
      
      // Create request signature
      final signature = _generateRequestSignature(endpoint, body, apiKey);
      
      // Add request metadata
      final secureBody = _addRequestMetadata(body, signature);
      
      // Log request start
      SecureLogger.logApiOperation(
        operation,
        method: 'POST',
        endpoint: endpoint,
        requestSizeBytes: jsonEncode(secureBody).length,
      );

      // Make the request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(secureBody),
      ).timeout(timeout ?? _defaultTimeout);

      stopwatch.stop();

      // Log response
      SecureLogger.logApiOperation(
        operation,
        method: 'POST',
        endpoint: endpoint,
        statusCode: response.statusCode,
        requestSizeBytes: jsonEncode(secureBody).length,
        responseSizeBytes: response.body.length,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      // Log audit event for API call
      SecureLogger.logAuditEvent(
        'API request completed',
        operation: operation,
        details: {
          'statusCode': response.statusCode,
          'duration': stopwatch.elapsedMilliseconds,
          'requestHash': _hashRequest(secureBody),
        },
      );

      return response;
    } catch (e) {
      stopwatch.stop();
      
      SecureLogger.logError(
        'Secure request failed',
        operation: operation,
        error: e,
        context: {
          'endpoint': _sanitizeUrl(endpoint),
          'duration': stopwatch.elapsedMilliseconds,
        },
      );
      
      rethrow;
    }
  }

  /// Build secure headers for API requests
  static Map<String, String> _buildSecureHeaders(
    String apiKey,
    Map<String, String>? additionalHeaders,
  ) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
      'Accept': 'application/json',
      'X-Request-ID': _generateRequestId(),
      'X-Client-Version': '1.0.0',
      'X-Timestamp': DateTime.now().toIso8601String(),
    };

    // Add additional headers if provided
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Generate request signature for verification
  static String _generateRequestSignature(
    String endpoint,
    Map<String, dynamic> body,
    String apiKey,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bodyStr = jsonEncode(body);
    final dataToSign = '$endpoint$bodyStr$timestamp';
    
    // Use HMAC for signing
    final key = utf8.encode(apiKey.substring(0, 32)); // Use first 32 chars as key
    final bytes = utf8.encode(dataToSign);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    
    return '$timestamp.${digest.toString().substring(0, 16)}';
  }

  /// Add request metadata for security
  static Map<String, dynamic> _addRequestMetadata(
    Map<String, dynamic> body,
    String signature,
  ) {
    return {
      ...body,
      '_metadata': {
        'requestId': _generateRequestId(),
        'timestamp': DateTime.now().toIso8601String(),
        'signature': signature,
        'version': '1.0',
      },
    };
  }

  /// Generate unique request ID
  static String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 1000000;
    return 'req_${timestamp}_$random';
  }

  /// Hash request for audit logging
  static String _hashRequest(Map<String, dynamic> body) {
    final bodyStr = jsonEncode(body);
    final bytes = utf8.encode(bodyStr);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Validate response integrity
  static bool validateResponse(http.Response response) {
    // Check status code
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    // Check content type
    final contentType = response.headers['content-type'];
    if (contentType == null || !contentType.contains('application/json')) {
      return false;
    }

    // Check for minimum response size
    if (response.body.length < 10) {
      return false;
    }

    return true;
  }

  /// Sanitize response for logging
  static String sanitizeResponse(String response) {
    try {
      final data = jsonDecode(response);
      if (data is Map<String, dynamic>) {
        return jsonEncode(_sanitizeResponseData(data));
      }
      return response;
    } catch (e) {
      return 'Invalid JSON response';
    }
  }

  /// Sanitize response data to remove sensitive information
  static Map<String, dynamic> _sanitizeResponseData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      
      // Hide sensitive fields
      if (key.contains('key') || key.contains('token') || key.contains('secret')) {
        sanitized[entry.key] = 'HIDDEN';
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = _sanitizeResponseData(entry.value as Map<String, dynamic>);
      } else if (entry.value is List) {
        sanitized[entry.key] = (entry.value as List).map((item) {
          if (item is Map<String, dynamic>) {
            return _sanitizeResponseData(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }
}