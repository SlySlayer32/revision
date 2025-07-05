---
applyTo: '"'
---
# Gemini API Integration Instructions for Copilot

## Overview
This file provides comprehensive instructions for integrating Google's Gemini API REST endpoints into the Revision Flutter application. Follow these patterns for consistent, secure, and maintainable API integration.

## Core Requirements

### 1. API Client Setup
- Use `http` or `dio` package for HTTP requests
- Implement singleton pattern for API client
- Configure base URL: `https://generativelanguage.googleapis.com/v1beta/`
- Always include proper headers with Content-Type and API key authentication
- Implement request/response interceptors for logging and error handling

### 2. Authentication Pattern
```dart
// Always use environment-based API key management
class GeminiApiClient {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/';
  final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-goog-api-key': _apiKey,
  };
}
```

### 3. Environment Configuration
- Add API keys to environment variables, never hardcode
- Use different keys for development, staging, and production flavors
- Validate API key presence at app startup
- Implement fallback behavior when API key is missing

## API Endpoints Implementation

### 1. Text Generation Endpoint
- Endpoint: `POST /models/gemini-pro:generateContent`
- Always validate input text length and content
- Implement proper request body structure with parts array
- Handle streaming and non-streaming responses appropriately

### 2. Vision Endpoint (Text + Image)
- Endpoint: `POST /models/gemini-pro-vision:generateContent`
- Support base64 image encoding
- Validate image format (JPEG, PNG, WebP, HEIC, HEIF)
- Implement image size limits and compression
- Handle multipart content structure correctly

### 3. Model Information
- Endpoint: `GET /models`
- Cache model information locally
- Implement model capability checking
- Use appropriate model for specific tasks

## Error Handling Patterns

### 1. HTTP Status Code Handling
```dart
// Implement comprehensive error mapping
switch (response.statusCode) {
  case 200:
    return _parseSuccessResponse(response);
  case 400:
    throw GeminiValidationException(_extractErrorMessage(response));
  case 401:
    throw GeminiAuthenticationException('Invalid API key');
  case 403:
    throw GeminiPermissionException('API access denied');
  case 429:
    throw GeminiRateLimitException('Rate limit exceeded', _getRetryAfter(response));
  case 500:
  case 502:
  case 503:
    throw GeminiServerException('Server error, retry recommended');
  default:
    throw GeminiUnknownException('Unexpected error: ${response.statusCode}');
}
```

### 2. Custom Exception Classes
- Create specific exception types for different error scenarios
- Include retry logic for transient errors (429, 5xx)
- Implement exponential backoff for rate limiting
- Provide user-friendly error messages

### 3. Network Error Handling
- Handle connection timeouts (set to 30 seconds)
- Implement offline detection and queuing
- Provide graceful degradation when API is unavailable
- Cache responses when appropriate for offline access

## Request/Response Models

### 1. Request Models
```dart
// Use immutable data classes with proper validation
@immutable
class GeminiGenerateRequest {
  final List<GeminiContent> contents;
  final GeminiGenerationConfig? generationConfig;
  final List<GeminiSafetySetting>? safetySettings;
  
  // Always include validation in constructors
  const GeminiGenerateRequest({
    required this.contents,
    this.generationConfig,
    this.safetySettings,
  }) : assert(contents.length > 0, 'Contents cannot be empty');
}
```

### 2. Response Models
- Implement proper JSON serialization/deserialization
- Handle optional fields gracefully
- Include safety ratings and finish reasons
- Parse candidate responses with proper null safety

## Security Best Practices

### 1. API Key Management
- Never commit API keys to version control
- Use Flutter's `--dart-define` for environment variables
- Implement key rotation capability
- Monitor API key usage and set up alerts

### 2. Content Safety
- Always implement safety settings for content generation
- Validate and sanitize user inputs before API calls
- Handle blocked content responses appropriately
- Implement content filtering for sensitive applications

### 3. Data Privacy
- Never log sensitive user data or API responses
- Implement proper data retention policies
- Use HTTPS for all API communications
- Consider implementing request signing for additional security

## Performance Optimization

### 1. Request Optimization
- Implement request batching where possible
- Use appropriate timeout values (30s for generation, 10s for info)
- Implement request deduplication for identical queries
- Cache frequently requested model information

### 2. Response Handling
- Stream large responses when supported
- Implement proper memory management for large responses
- Use background processing for non-critical requests
- Implement response compression when available

### 3. Rate Limiting
- Implement client-side rate limiting to prevent API quota exhaustion
- Use exponential backoff with jitter for retries
- Monitor and alert on rate limit approaches
- Implement request queuing for high-traffic scenarios

## Testing Patterns

### 1. Unit Testing
- Mock all HTTP requests using `mockito` or similar
- Test all error scenarios and edge cases
- Validate request serialization and response parsing
- Test retry logic and exponential backoff

### 2. Integration Testing
- Use test API keys in separate Google Cloud project
- Implement end-to-end API flow testing
- Test with various content types and sizes
- Validate error handling with real API responses

### 3. Performance Testing
- Test API response times under various loads
- Validate memory usage with large responses
- Test timeout handling and recovery
- Monitor API quota usage during testing

## Monitoring and Logging

### 1. Request Logging
- Log API request metadata (not content for privacy)
- Include request IDs for tracing
- Monitor response times and success rates
- Implement structured logging with proper levels

### 2. Error Monitoring
- Integrate with crash reporting (Firebase Crashlytics)
- Track API error rates and patterns
- Set up alerts for unusual error spikes
- Monitor quota usage and approaching limits

### 3. Performance Metrics
- Track API response times by endpoint
- Monitor success/failure rates
- Implement custom metrics for business logic
- Use analytics to understand usage patterns

## Code Organization

### 1. File Structure
```
lib/
├── services/
│   ├── gemini/
│   │   ├── gemini_api_client.dart
│   │   ├── gemini_service.dart
│   │   ├── models/
│   │   │   ├── request_models.dart
│   │   │   └── response_models.dart
│   │   └── exceptions/
│   │       └── gemini_exceptions.dart
```

### 2. Dependency Injection
- Register API client as singleton in service locator
- Use dependency injection for testability
- Implement interface-based design for easy mocking
- Follow the existing project's DI patterns

### 3. State Management Integration
- Integrate with existing state management solution (BLoC/Riverpod)
- Implement proper loading states for API calls
- Handle API responses in appropriate state classes
- Maintain separation of concerns between API and UI layers

## Validation Checklist

- [ ] API key is loaded from environment variables
- [ ] All HTTP status codes are handled appropriately
- [ ] Custom exceptions are implemented for different error types
- [ ] Request and response models include proper validation
- [ ] Retry logic with exponential backoff is implemented
- [ ] Safety settings are configured for content generation
- [ ] Timeout values are set appropriately
- [ ] Logging excludes sensitive data
- [ ] Unit tests cover all error scenarios
- [ ] Integration tests validate end-to-end flows
- [ ] Performance monitoring is implemented
- [ ] Code follows project architecture patterns

## Example Implementation Reference

Always structure API calls following this pattern:
1. Validate input parameters
2. Build request model with proper serialization
3. Execute HTTP request with error handling
4. Parse response with null safety
5. Handle business logic errors appropriately
6. Return typed response or throw specific exception
7. Log relevant metadata for monitoring

This ensures consistent, maintainable, and robust API integration across the Revision application.
