import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Security utilities for production applications
class SecurityUtils {
  SecurityUtils._();

  /// Validates that an email address format is secure
  static bool isValidEmail(String email) {
    if (email.isEmpty || email.length > 254) return false;
    
    // More strict email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    
    return emailRegex.hasMatch(email);
  }

  /// Validates password strength
  static PasswordStrength validatePasswordStrength(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }
    
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasDigit = password.contains(RegExp(r'\d'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int score = 0;
    if (hasLower) score++;
    if (hasUpper) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    if (password.length >= 12) score++;
    
    if (score >= 5) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /// Sanitizes user input to prevent common injection attacks
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>'), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*='), '')
        .trim();
  }

  /// Generates a secure random string
  static String generateSecureRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Hashes sensitive data (one-way)
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Creates a secure token with timestamp
  static String createSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = generateSecureRandomString(32);
    final combined = '$timestamp:$randomPart';
    return base64Url.encode(utf8.encode(combined));
  }

  /// Validates that a URL is safe (basic check)
  static bool isSafeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Only allow https in production
      if (!kDebugMode && uri.scheme != 'https') {
        return false;
      }
      
      // Allow http only in debug mode
      if (kDebugMode && !['http', 'https'].contains(uri.scheme)) {
        return false;
      }
      
      // Block suspicious patterns
      final suspiciousPatterns = [
        'javascript:',
        'data:',
        'vbscript:',
        'file:',
        'ftp:',
      ];
      
      final lowerUrl = url.toLowerCase();
      for (final pattern in suspiciousPatterns) {
        if (lowerUrl.contains(pattern)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Masks sensitive information for logging
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars * 2) {
      return '*' * data.length;
    }
    
    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final middle = '*' * (data.length - (visibleChars * 2));
    
    return '$start$middle$end';
  }

  /// Validates file upload safety
  static bool isSafeFileUpload(String filename, List<int> bytes) {
    // Check file extension
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = filename.toLowerCase().substring(filename.lastIndexOf('.'));
    
    if (!allowedExtensions.contains(extension)) {
      return false;
    }
    
    // Check file size (max 10MB)
    if (bytes.length > 10 * 1024 * 1024) {
      return false;
    }
    
    // Basic magic number check for images
    if (bytes.length >= 4) {
      final header = bytes.take(4).toList();
      
      // JPEG magic numbers
      if (header[0] == 0xFF && header[1] == 0xD8) return true;
      
      // PNG magic number
      if (header[0] == 0x89 && header[1] == 0x50 && 
          header[2] == 0x4E && header[3] == 0x47) return true;
      
      // GIF magic numbers
      if (header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46) return true;
      
      // WebP magic number (RIFF)
      if (header[0] == 0x52 && header[1] == 0x49 && 
          header[2] == 0x46 && header[3] == 0x46) return true;
    }
    
    return false;
  }

  /// Rate limiting helper
  static bool isRateLimited(String identifier, {int maxRequests = 10, Duration window = const Duration(minutes: 1)}) {
    // This is a simple in-memory rate limiter
    // In production, you might want to use Redis or similar
    return _SimpleRateLimiter.instance.isLimited(identifier, maxRequests, window);
  }

  /// Validates API request headers for security
  static bool validateRequestHeaders(Map<String, String> headers) {
    // Check for required security headers
    final userAgent = headers['user-agent'] ?? '';
    if (userAgent.isEmpty || userAgent.length > 512) {
      return false;
    }
    
    // Block suspicious user agents
    final suspiciousAgents = ['bot', 'spider', 'crawler', 'scraper'];
    final lowerUserAgent = userAgent.toLowerCase();
    for (final agent in suspiciousAgents) {
      if (lowerUserAgent.contains(agent)) {
        return false;
      }
    }
    
    return true;
  }
}

/// Password strength enumeration
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Simple in-memory rate limiter
class _SimpleRateLimiter {
  static final _SimpleRateLimiter instance = _SimpleRateLimiter._();
  _SimpleRateLimiter._();
  
  final Map<String, List<DateTime>> _requests = {};
  
  bool isLimited(String identifier, int maxRequests, Duration window) {
    final now = DateTime.now();
    final requests = _requests.putIfAbsent(identifier, () => []);
    
    // Remove old requests outside the window
    requests.removeWhere((time) => now.difference(time) > window);
    
    // Check if limit exceeded
    if (requests.length >= maxRequests) {
      return true;
    }
    
    // Add current request
    requests.add(now);
    return false;
  }
  
  void clearOldEntries() {
    final now = DateTime.now();
    _requests.removeWhere((key, requests) {
      requests.removeWhere((time) => now.difference(time) > const Duration(hours: 1));
      return requests.isEmpty;
    });
  }
}
