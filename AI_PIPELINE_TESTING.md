# AI Pipeline Testing Guide

This document outlines the comprehensive testing strategy for the Firebase AI pipeline to prevent and catch configuration issues before they impact the application.

## Overview

We've created a comprehensive test suite that validates the entire AI pipeline, from service initialization to error handling. This allows you to catch AI pipeline errors during development rather than discovering them when running the app.

## Test Files Created

### 1. Core Service Tests

#### `test/core/services/gemini_ai_service_test.dart`
- **Purpose**: Tests the core GeminiAIService functionality
- **Coverage**:
  - Service initialization (successful and failed)
  - Model access (analysis and image generation models)
  - Text and image processing workflows
  - Error handling and fallback responses
  - Configuration management
  - Safety checks and content filtering

#### `test/core/services/ai_error_scenarios_test.dart`
- **Purpose**: Comprehensive error scenario testing
- **Coverage**:
  - Firebase AI not enabled errors
  - API key configuration issues
  - Network connectivity problems
  - Model availability issues
  - Quota and rate limiting errors
  - Invalid image format handling
  - Memory pressure scenarios
  - Recovery and retry mechanisms

### 2. Dependency Injection Tests

#### `test/core/di/service_locator_test.dart`
- **Purpose**: Validates GetIt service registration and dependency injection
- **Coverage**:
  - Service registration validation
  - GenerativeModel instance registration (with named instances)
  - Dependency resolution chains
  - Factory vs singleton behavior verification
  - Error handling for missing registrations
  - Service cleanup and reset functionality

### 3. Integration Tests

#### `test/integration/ai_pipeline_integration_test.dart`
- **Purpose**: End-to-end AI pipeline flow validation
- **Coverage**:
  - Complete service initialization flow
  - Cross-service communication
  - Pipeline error propagation
  - Performance under load
  - Resource management
  - Fallback behavior validation

### 4. Test Suite Runner

#### `test/ai_pipeline_test_suite.dart`
- **Purpose**: Runs all AI pipeline tests in organized groups
- **Usage**: Single entry point for all AI-related tests

## Running the Tests

### Run All AI Pipeline Tests
```bash
flutter test test/ai_pipeline_test_suite.dart
```

### Run Individual Test Groups
```bash
# Service tests only
flutter test test/core/services/

# Dependency injection tests
flutter test test/core/di/

# Integration tests
flutter test test/integration/

# Error scenario tests
flutter test test/core/services/ai_error_scenarios_test.dart
```

### Run with Coverage
```bash
flutter test --coverage test/ai_pipeline_test_suite.dart
```

## What These Tests Catch

### 1. Configuration Issues
- ✅ Firebase AI Logic not enabled in Firebase Console
- ✅ Missing or invalid API keys
- ✅ Incorrect model names or configurations
- ✅ Remote Config setup problems

### 2. Service Registration Issues
- ✅ Missing GetIt registrations for GenerativeModel instances
- ✅ Circular dependency problems
- ✅ Incorrect dependency injection setup
- ✅ Service initialization order issues

### 3. Runtime Errors
- ✅ Model access before initialization
- ✅ Network connectivity problems
- ✅ API quota and rate limiting
- ✅ Invalid image data handling
- ✅ Timeout scenarios

### 4. Error Recovery
- ✅ Fallback response behavior
- ✅ Service recovery after failures
- ✅ Graceful degradation
- ✅ Memory management under stress

## Key Benefits

### 1. Early Detection
- Catch configuration issues during development
- Validate setup before deployment
- Prevent runtime crashes in production

### 2. Comprehensive Coverage
- Test all critical paths through the AI pipeline
- Validate error handling and edge cases
- Ensure fallback mechanisms work correctly

### 3. Development Confidence
- Know immediately if changes break the AI pipeline
- Validate new configurations before applying them
- Test error scenarios without impacting real services

### 4. Documentation
- Tests serve as living documentation of expected behavior
- Clear examples of how services should be used
- Error scenarios and expected responses documented

## Common Issues These Tests Detect

### Firebase AI Setup Issues
```bash
# Test will fail with helpful message pointing to:
StateError: Gemini analysis model not initialized. 
Please check Firebase AI setup.
Go to: https://console.firebase.google.com/project/revision-464202/ailogic
```

### GetIt Registration Issues
```bash
# Test will catch:
GetIt: Object/factory with type GenerativeModel is not registered inside GetIt
```

### Model Configuration Issues
```bash
# Test will detect:
- Invalid model names
- Incorrect generation parameters
- Missing system instructions
- Wrong response modalities
```

### Network and API Issues
```bash
# Test will validate handling of:
- Connection timeouts
- Rate limiting
- Quota exceeded
- Service unavailable
```

## Test Data and Mocks

The tests use comprehensive mocking to:
- Avoid actual Firebase API calls during testing
- Simulate various error conditions
- Test fallback behaviors
- Validate service interactions

### Mock Setup
- `MockFirebaseAIRemoteConfigService`: Simulates remote config behavior
- `MockGenerativeModel`: Mocks AI model responses
- `MockGenerateContentResponse`: Simulates API responses
- Test helpers for common scenarios

## Continuous Integration

These tests are designed to be run in CI/CD pipelines to:
- Validate pull requests before merging
- Catch regressions in AI pipeline functionality
- Ensure consistent behavior across environments
- Document expected behavior for new developers

## Updating Tests

When adding new AI features:
1. Add corresponding test cases to the relevant test files
2. Update error scenario tests for new failure modes
3. Add integration tests for new service interactions
4. Update this documentation

When modifying AI configuration:
1. Update mock configurations in test setup
2. Validate that tests still pass with new configurations
3. Add tests for new configuration options

## Troubleshooting Test Failures

### Service Initialization Failures
- Check mock setup in test files
- Verify that all required dependencies are mocked
- Ensure proper async/await handling

### GetIt Registration Failures
- Verify service registration order in setupServiceLocator()
- Check for missing dependencies
- Ensure proper cleanup between tests

### Mock Behavior Issues
- Review mock setup in setUp() methods
- Verify that mock methods return expected types
- Check for proper when().thenReturn() configurations

This comprehensive testing approach ensures that you can catch and address AI pipeline issues during development, preventing them from impacting your users when they run the application.
