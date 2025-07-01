/// Comprehensive AI Pipeline Test Suite
///
/// This file runs all AI pipeline related tests to ensure the Firebase AI
/// integration is working correctly and can catch configuration issues early.
///
/// Usage: flutter test test/ai_pipeline_test_suite.dart
///
/// This test suite covers:
/// - GeminiAIService functionality and error handling
/// - GetIt dependency injection setup
/// - AI pipeline integration flows
/// - Error scenarios and edge cases
/// - Fallback behavior and recovery

import 'package:flutter_test/flutter_test.dart';

// Import all AI pipeline test files
import 'core/services/gemini_ai_service_test.dart' as gemini_service_tests;
import 'core/di/service_locator_test.dart' as service_locator_tests;
import 'integration/ai_pipeline_integration_test.dart' as integration_tests;
import 'core/services/ai_error_scenarios_test.dart' as error_scenario_tests;

void main() {
  group('🤖 AI Pipeline Test Suite', () {
    group('🧠 GeminiAIService Tests', () {
      gemini_service_tests.main();
    });

    group('🔧 Service Locator Tests', () {
      service_locator_tests.main();
    });

    group('🔄 Integration Tests', () {
      integration_tests.main();
    });

    group('⚠️  Error Scenario Tests', () {
      error_scenario_tests.main();
    });
  });
}
