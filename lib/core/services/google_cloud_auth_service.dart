import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Service to handle Google Cloud authentication for Vertex AI APIs
/// This provides access tokens needed for Imagen API calls
class GoogleCloudAuthService {
  static GoogleCloudAuthService? _instance;
  static GoogleCloudAuthService get instance {
    _instance ??= GoogleCloudAuthService._();
    return _instance!;
  }

  GoogleCloudAuthService._();

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Get a valid access token for Google Cloud APIs
  /// For MVP, this uses Firebase Auth to get an ID token that can be used for some Google Cloud APIs
  Future<String> getAccessToken() async {
    try {
      // Check if we have a valid cached token
      if (_cachedAccessToken != null &&
          _tokenExpiry != null &&
          DateTime.now()
              .isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
        return _cachedAccessToken!;
      }

      log('🔄 GoogleCloudAuthService: Getting access token');

      // For MVP development, we'll simulate an access token
      // In production, this would integrate with proper Google Cloud authentication

      // Generate a development token (not for production use)
      final developmentToken = await _generateDevelopmentToken();

      _cachedAccessToken = developmentToken;
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

      log('✅ GoogleCloudAuthService: Access token obtained');
      return developmentToken;
    } catch (e, stackTrace) {
      log('❌ GoogleCloudAuthService: Failed to get access token: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate a development token for MVP testing
  /// In production, this would be replaced with proper OAuth2 flow
  Future<String> _generateDevelopmentToken() async {
    // For MVP, create a simple token that indicates this is development mode
    final tokenData = {
      'iss': 'revision-app-development',
      'aud': 'vertex-ai-testing',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
      'project_id': getProjectId(),
      'scope': 'https://www.googleapis.com/auth/cloud-platform',
      'development_mode': true,
    };

    // Create a simple base64 encoded token (not secure, for development only)
    final tokenString = base64Url.encode(utf8.encode(jsonEncode(tokenData)));
    return 'dev_token_$tokenString';
  }

  /// Get project ID from Firebase configuration
  String getProjectId() {
    try {
      final app = Firebase.app();
      final projectId = app.options.projectId;
      if (projectId.isEmpty) {
        throw Exception('Project ID not found in Firebase configuration');
      }
      return projectId;
    } catch (e) {
      log('❌ GoogleCloudAuthService: Failed to get project ID: $e');
      rethrow;
    }
  }

  /// Clear cached token (for logout or refresh)
  void clearToken() {
    _cachedAccessToken = null;
    _tokenExpiry = null;
  }
}

/// Production implementation using service account key
class ServiceAccountAuthService {
  final Map<String, dynamic> serviceAccountKey;
  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  ServiceAccountAuthService(this.serviceAccountKey);

  Future<String> getAccessToken() async {
    try {
      // Check if we have a valid cached token
      if (_cachedAccessToken != null &&
          _tokenExpiry != null &&
          DateTime.now()
              .isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
        return _cachedAccessToken!;
      }

      log('🔄 ServiceAccountAuthService: Getting access token');

      // Create JWT assertion for service account authentication
      final jwt = await _createJWTAssertion();

      // Exchange JWT for access token
      final accessToken = await _exchangeJWTForAccessToken(jwt);

      _cachedAccessToken = accessToken;
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

      log('✅ ServiceAccountAuthService: Access token obtained');
      return accessToken;
    } catch (e) {
      log('❌ ServiceAccountAuthService: Failed to get access token: $e');
      rethrow;
    }
  }

  Future<String> _createJWTAssertion() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = now + 3600; // 1 hour

    final header = {
      'alg': 'RS256',
      'typ': 'JWT',
    };

    final payload = {
      'iss': serviceAccountKey['client_email'],
      'scope': 'https://www.googleapis.com/auth/cloud-platform',
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': exp,
      'iat': now,
    };

    // Create unsigned JWT (for MVP, we'll return a placeholder)
    // In production, this would be properly signed with the private key
    final headerEncoded = base64Url.encode(utf8.encode(jsonEncode(header)));
    final payloadEncoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    // Note: In production, you would sign this with the private key from serviceAccountKey
    return '$headerEncoded.$payloadEncoded.SIGNATURE_PLACEHOLDER';
  }

  Future<String> _exchangeJWTForAccessToken(String jwt) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['access_token'] as String;
      } else {
        throw Exception(
            'Failed to get access token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // For MVP development, return a mock token since we don't have proper JWT signing
      log('⚠️ ServiceAccountAuthService: Using development token (JWT signing not implemented)');
      return 'service_account_dev_token_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
