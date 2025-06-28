import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/constants/firebase_constants.dart';

void main() {
  group('FirebaseConstants', () {
    group('Project Configuration', () {
      test('should have valid project ID', () {
        expect(FirebaseConstants.projectId, equals('revision-fc66c'));
        expect(FirebaseConstants.projectId, isNotEmpty);
      });

      test('should return correct bundle ID for development', () {
        // This test assumes we can set the environment
        // In a real test, you might need to mock the Environment
        expect(FirebaseConstants.bundleId, isNotEmpty);
        expect(FirebaseConstants.bundleId, contains('com.sly.revision'));
      });

      test('should have valid auth configuration', () {
        expect(
          FirebaseConstants.authDomain,
          equals('revision-fc66c.firebaseapp.com'),
        );
        expect(FirebaseConstants.authDomain, contains('.firebaseapp.com'));
        expect(FirebaseConstants.authEmulatorHost, equals('127.0.0.1'));
        expect(FirebaseConstants.authEmulatorPort, equals(9099));
      });

      test('should have valid Firestore configuration', () {
        expect(FirebaseConstants.firestoreDatabase, equals('(default)'));
        expect(FirebaseConstants.firestoreEmulatorHost, equals('localhost'));
        expect(FirebaseConstants.firestoreEmulatorPort, equals(8080));
      });

      test('should have valid storage configuration', () {
        expect(
          FirebaseConstants.storageBucket,
          equals('revision-fc66c.appspot.com'),
        );
        expect(FirebaseConstants.storageBucket, contains('.appspot.com'));
        expect(FirebaseConstants.storageEmulatorHost, equals('localhost'));
        expect(FirebaseConstants.storageEmulatorPort, equals(9199));
      });
    });

    group('AI Processing Configuration', () {
      test('should have latest model names', () {
        expect(FirebaseConstants.geminiModel, equals('gemini-2.5-flash'));
        expect(
          FirebaseConstants.imagenModel,
          equals('imagen-3.0-generate-001'),
        );
        expect(FirebaseConstants.defaultModel, equals('gemini-1.5-flash'));
      });

      test('should have complete available models map', () {
        expect(FirebaseConstants.availableModels, isNotEmpty);
        expect(
          FirebaseConstants.availableModels,
          containsPair('gemini-1.5-flash', 'Fast general-purpose model'),
        );
        expect(
          FirebaseConstants.availableModels,
          containsPair(
            'gemini-1.5-pro',
            'High-quality model for complex tasks',
          ),
        );
        expect(
          FirebaseConstants.availableModels,
          containsPair(
            'gemini-2.0-flash-exp',
            'Latest experimental flash model',
          ),
        );
        expect(
          FirebaseConstants.availableModels,
          containsPair(
            'imagen-3.0-generate-001',
            'Advanced image generation model',
          ),
        );
      });
    });

    group('AI Processing Limits', () {
      test('should have reasonable timeout values', () {
        expect(FirebaseConstants.aiRequestTimeout.inSeconds, equals(60));
        expect(FirebaseConstants.aiRequestTimeout.inSeconds, greaterThan(0));
        expect(
          FirebaseConstants.aiRequestTimeout.inSeconds,
          lessThanOrEqualTo(120),
        );
      });

      test('should have appropriate retry configuration', () {
        expect(FirebaseConstants.maxRetryAttempts, equals(3));
        expect(FirebaseConstants.maxRetryAttempts, greaterThan(0));
        expect(FirebaseConstants.maxRetryAttempts, lessThanOrEqualTo(5));

        expect(FirebaseConstants.retryDelay.inSeconds, equals(2));
        expect(FirebaseConstants.retryDelay.inSeconds, greaterThan(0));
      });

      test('should have sensible image processing limits', () {
        expect(FirebaseConstants.maxImageSize, equals(4096));
        expect(
          FirebaseConstants.maxImageSize,
          greaterThan(1024),
        ); // At least 1K
        expect(
          FirebaseConstants.maxImageSize,
          lessThanOrEqualTo(8192),
        ); // Not more than 8K

        expect(FirebaseConstants.maxFileSizeMB, equals(10));
        expect(FirebaseConstants.maxFileSizeMB, greaterThan(0));
        expect(
          FirebaseConstants.maxFileSizeMB,
          lessThanOrEqualTo(50),
        ); // Reasonable upper bound
      });

      test('should support common image formats', () {
        expect(FirebaseConstants.supportedFormats, contains('jpg'));
        expect(FirebaseConstants.supportedFormats, contains('jpeg'));
        expect(FirebaseConstants.supportedFormats, contains('png'));
        expect(FirebaseConstants.supportedFormats, contains('heic'));
        expect(FirebaseConstants.supportedFormats.length, equals(4));
      });
    });

    group('Concurrent Request Limits', () {
      test('should have appropriate concurrency limits', () {
        expect(FirebaseConstants.maxConcurrentRequests, equals(3));
        expect(FirebaseConstants.maxConcurrentRequests, greaterThan(0));
        expect(FirebaseConstants.maxConcurrentRequests, lessThanOrEqualTo(10));
      });

      test('should have reasonable queue timeout', () {
        expect(FirebaseConstants.requestQueueTimeout.inMinutes, equals(5));
        expect(FirebaseConstants.requestQueueTimeout.inMinutes, greaterThan(0));
        expect(
          FirebaseConstants.requestQueueTimeout.inMinutes,
          lessThanOrEqualTo(15),
        );
      });
    });

    group('Firebase Functions Configuration', () {
      test('should have valid functions region', () {
        expect(FirebaseConstants.functionsRegion, equals('us-central1'));
        expect(FirebaseConstants.functionsRegion, isNotEmpty);
        expect(FirebaseConstants.functionsRegion, contains('us-central1'));
      });
    });

    group('Emulator Configuration', () {
      test('should have valid emulator settings', () {
        expect(FirebaseConstants.useAuthEmulator, isA<bool>());
        expect(FirebaseConstants.useFirestoreEmulator, isA<bool>());
        expect(FirebaseConstants.useStorageEmulator, isA<bool>());
      });

      test('should have valid emulator hosts and ports', () {
        expect(FirebaseConstants.authEmulatorHost, isNotEmpty);
        expect(FirebaseConstants.authEmulatorPort, greaterThan(1000));
        expect(FirebaseConstants.authEmulatorPort, lessThan(65536));

        expect(FirebaseConstants.firestoreEmulatorHost, isNotEmpty);
        expect(FirebaseConstants.firestoreEmulatorPort, greaterThan(1000));
        expect(FirebaseConstants.firestoreEmulatorPort, lessThan(65536));

        expect(FirebaseConstants.storageEmulatorHost, isNotEmpty);
        expect(FirebaseConstants.storageEmulatorPort, greaterThan(1000));
        expect(FirebaseConstants.storageEmulatorPort, lessThan(65536));
      });

      test('should have unique emulator ports', () {
        final ports = {
          FirebaseConstants.authEmulatorPort,
          FirebaseConstants.firestoreEmulatorPort,
          FirebaseConstants.storageEmulatorPort,
        };
        expect(ports.length, equals(3)); // All ports should be unique
      });
    });

    group('Bundle ID Generation', () {
      test('should generate correct bundle IDs for different environments', () {
        // Note: This test might need to be adjusted based on how Environment.current is set
        final bundleId = FirebaseConstants.bundleId;
        expect(bundleId, startsWith('com.sly.revision'));
        expect(bundleId, isNotEmpty);
      });
    });

    group('Constants Validation', () {
      test('should have consistent naming patterns', () {
        expect(FirebaseConstants.geminiModel, startsWith('gemini-'));
        expect(FirebaseConstants.imagenModel, startsWith('imagen-'));
        expect(FirebaseConstants.defaultModel, startsWith('gemini-'));
      });

      test('should have valid duration objects', () {
        expect(FirebaseConstants.aiRequestTimeout, isA<Duration>());
        expect(FirebaseConstants.retryDelay, isA<Duration>());
        expect(FirebaseConstants.requestQueueTimeout, isA<Duration>());
      });

      test('should have valid numeric constants', () {
        expect(FirebaseConstants.maxRetryAttempts, isA<int>());
        expect(FirebaseConstants.maxImageSize, isA<int>());
        expect(FirebaseConstants.maxFileSizeMB, isA<int>());
        expect(FirebaseConstants.maxConcurrentRequests, isA<int>());

        expect(FirebaseConstants.authEmulatorPort, isA<int>());
        expect(FirebaseConstants.firestoreEmulatorPort, isA<int>());
        expect(FirebaseConstants.storageEmulatorPort, isA<int>());
      });

      test('should have valid string constants', () {
        expect(FirebaseConstants.projectId, isA<String>());
        expect(FirebaseConstants.authDomain, isA<String>());
        expect(FirebaseConstants.firestoreDatabase, isA<String>());
        expect(FirebaseConstants.storageBucket, isA<String>());
        expect(FirebaseConstants.vertexAiLocation, isA<String>());
        expect(FirebaseConstants.functionsRegion, isA<String>());

        expect(FirebaseConstants.geminiModel, isA<String>());
        expect(FirebaseConstants.imagenModel, isA<String>());
        expect(FirebaseConstants.defaultModel, isA<String>());
      });

      test('should have valid boolean constants', () {
        expect(FirebaseConstants.useAuthEmulator, isA<bool>());
        expect(FirebaseConstants.useFirestoreEmulator, isA<bool>());
        expect(FirebaseConstants.useStorageEmulator, isA<bool>());
      });

      test('should have valid list constants', () {
        expect(FirebaseConstants.supportedFormats, isA<List<String>>());
        expect(FirebaseConstants.supportedFormats, isNotEmpty);
        expect(
          FirebaseConstants.supportedFormats
              .every((format) => format.isNotEmpty),
          isTrue,
        );
      });

      test('should have valid map constants', () {
        expect(FirebaseConstants.availableModels, isA<Map<String, String>>());
        expect(FirebaseConstants.availableModels, isNotEmpty);
        expect(
          FirebaseConstants.availableModels.keys.every((key) => key.isNotEmpty),
          isTrue,
        );
        expect(
          FirebaseConstants.availableModels.values
              .every((value) => value.isNotEmpty),
          isTrue,
        );
      });
    });

    group('Domain and URL Validation', () {
      test('should have properly formatted domain names', () {
        expect(
          FirebaseConstants.authDomain,
          matches(RegExp(r'^[a-zA-Z0-9-]+\.firebaseapp\.com$')),
        );
        expect(
          FirebaseConstants.storageBucket,
          matches(RegExp(r'^[a-zA-Z0-9-]+\.appspot\.com$')),
        );
      });

      test('should have consistent project naming', () {
        expect(
          FirebaseConstants.authDomain,
          contains(FirebaseConstants.projectId),
        );
        expect(
          FirebaseConstants.storageBucket,
          contains(FirebaseConstants.projectId),
        );
      });
    });

    group('Model Configuration Validation', () {
      test('should have valid model version formats', () {
        expect(
          FirebaseConstants.geminiModel,
          matches(RegExp(r'^gemini-\d+\.\d+.*')),
        );
        expect(
          FirebaseConstants.imagenModel,
          matches(RegExp(r'^imagen-\d+\.\d+.*')),
        );
      });

      test('should use latest model versions', () {
        // Ensure we're using recent model versions
        expect(
          FirebaseConstants.geminiModel,
          contains('2.5'),
        ); // Latest Gemini version (2.5-flash)
        expect(
          FirebaseConstants.imagenModel,
          contains('3.0'),
        ); // Latest Imagen version
      });
    });

    group('Performance Constraints', () {
      test('should have reasonable performance limits', () {
        // Timeout should be long enough for AI processing but not too long
        expect(
          FirebaseConstants.aiRequestTimeout.inSeconds,
          inInclusiveRange(30, 120),
        );

        // Retry attempts should be reasonable
        expect(FirebaseConstants.maxRetryAttempts, inInclusiveRange(1, 5));

        // Retry delay should be meaningful but not too long
        expect(FirebaseConstants.retryDelay.inSeconds, inInclusiveRange(1, 10));

        // Image size should handle high-resolution images but have limits
        expect(FirebaseConstants.maxImageSize, inInclusiveRange(2048, 8192));

        // File size should be reasonable for mobile uploads
        expect(FirebaseConstants.maxFileSizeMB, inInclusiveRange(5, 50));
      });
    });
  });
}
