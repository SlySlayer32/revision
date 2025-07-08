#!/usr/bin/env dart

import 'dart:io';

/// Optimized test runner for VGV Firebase project
///
/// Runs tests in optimal order for fast feedback:
/// 1. Fast unit tests (domain + presentation)
/// 2. Integration tests with emulators
/// 3. Widget tests
/// 4. Full coverage report
void main(List<String> args) async {
  final runner = TestRunner();

  if (args.contains('--help')) {
    runner.printHelp();
    return;
  }

  try {
    await runner.run(args);
  } catch (e) {
    print('❌ Test run failed: $e');
    exit(1);
  }
}

class TestRunner {
  /// Run tests with optimized strategy
  Future<void> run(List<String> args) async {
    final stopwatch = Stopwatch()..start();

    print('🚀 Starting optimized test execution...\n');

    // Parse arguments
    final fastOnly = args.contains('--fast');
    final skipIntegration = args.contains('--skip-integration');
    final coverage = args.contains('--coverage') || args.contains('-c');

    try {
      // Phase 1: Fast Unit Tests (10-15 seconds)
      await _runUnitTests(coverage: coverage);

      if (!fastOnly) {
        // Phase 2: Integration Tests with Emulators (30-60 seconds)
        if (!skipIntegration) {
          await _runIntegrationTests();
        }

        // Phase 3: Widget Tests (15-30 seconds)
        await _runWidgetTests();
      }

      // Phase 4: Generate Coverage Report
      if (coverage && !fastOnly) {
        await _generateCoverageReport();
      }

      stopwatch.stop();
      final duration = stopwatch.elapsed;

      print('\n✅ All tests completed successfully!');
      print('⏱️  Total time: ${_formatDuration(duration)}');
    } catch (e) {
      stopwatch.stop();
      print('\n❌ Tests failed after ${_formatDuration(stopwatch.elapsed)}');
      rethrow;
    }
  }

  /// Run fast unit tests (domain + presentation layers)
  Future<void> _runUnitTests({bool coverage = false}) async {
    print('📋 Phase 1: Running unit tests...');
    final stopwatch = Stopwatch()..start();

    final args = [
      'test',
      // Unit test directories
      'test/features/*/domain/',
      'test/features/*/presentation/blocs/',
      'test/core/',
      // Options
      '--concurrency=6',
      '--reporter=expanded',
    ];

    if (coverage) {
      args.add('--coverage');
    }

    final result = await Process.run('flutter', args);

    stopwatch.stop();

    if (result.exitCode != 0) {
      print('❌ Unit tests failed:');
      print(result.stdout);
      print(result.stderr);
      throw const TestFailureException('Unit tests failed');
    }

    print('✅ Unit tests passed (${_formatDuration(stopwatch.elapsed)})');
    print(
      '   ${_countTestFiles(['test/features/*/domain/', 'test/features/*/presentation/blocs/', 'test/core/'])} test files executed\n',
    );
  }

  /// Run integration tests with Firebase emulators
  Future<void> _runIntegrationTests() async {
    print('🔥 Phase 2: Running integration tests...');
    final stopwatch = Stopwatch()..start();

    // Check if Firebase CLI is available
    if (!await _checkFirebaseCLI()) {
      print('⚠️  Firebase CLI not found, skipping integration tests');
      return;
    }

    // Start emulators
    print('   Starting Firebase emulators...');
    final emulatorProcess = await _startEmulators();

    try {
      // Wait for emulators to be ready
      await _waitForEmulators();

      // Run integration tests
      final result = await Process.run('flutter', [
        'test',
        'test/integration/',
        '--concurrency=2', // Lower concurrency for emulator tests
        '--reporter=expanded',
        '--timeout=120s', // Longer timeout for emulator tests
      ]);

      if (result.exitCode != 0) {
        print('❌ Integration tests failed:');
        print(result.stdout);
        print(result.stderr);
        throw const TestFailureException('Integration tests failed');
      }

      stopwatch.stop();
      print(
        '✅ Integration tests passed (${_formatDuration(stopwatch.elapsed)})',
      );
      print(
        '   ${_countTestFiles(['test/integration/'])} integration test files executed\n',
      );
    } finally {
      // Always stop emulators
      emulatorProcess?.kill();
      await _stopEmulators();
    }
  }

  /// Run widget tests
  Future<void> _runWidgetTests() async {
    print('🎨 Phase 3: Running widget tests...');
    final stopwatch = Stopwatch()..start();

    final result = await Process.run('flutter', [
      'test',
      'test/features/*/presentation/pages/',
      'test/features/*/presentation/widgets/',
      'test/app/',
      '--concurrency=4',
      '--reporter=expanded',
    ]);

    stopwatch.stop();

    if (result.exitCode != 0) {
      print('❌ Widget tests failed:');
      print(result.stdout);
      print(result.stderr);
      throw const TestFailureException('Widget tests failed');
    }

    print('✅ Widget tests passed (${_formatDuration(stopwatch.elapsed)})');
    print(
      '   ${_countTestFiles(['test/features/*/presentation/pages/', 'test/features/*/presentation/widgets/', 'test/app/'])} widget test files executed\n',
    );
  }

  /// Generate coverage report
  Future<void> _generateCoverageReport() async {
    print('📊 Generating coverage report...');

    // Install lcov if not available
    if (!await _checkLcov()) {
      print('⚠️  lcov not found, skipping HTML coverage report');
      return;
    }

    final result = await Process.run('genhtml', [
      'coverage/lcov.info',
      '-o',
      'coverage/html',
    ]);

    if (result.exitCode == 0) {
      print('✅ Coverage report generated: coverage/html/index.html');
    } else {
      print('⚠️  Failed to generate HTML coverage report');
    }
  }

  /// Check if Firebase CLI is available
  Future<bool> _checkFirebaseCLI() async {
    try {
      final result = await Process.run('firebase', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if lcov is available
  Future<bool> _checkLcov() async {
    try {
      final result = await Process.run('genhtml', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Start Firebase emulators
  Future<Process?> _startEmulators() async {
    try {
      final process = await Process.start('firebase', [
        'emulators:start',
        '--only=auth',
      ], mode: ProcessStartMode.detached);
      return process;
    } catch (e) {
      print('⚠️  Failed to start emulators: $e');
      return null;
    }
  }

  /// Stop Firebase emulators
  Future<void> _stopEmulators() async {
    try {
      await Process.run('firebase', ['emulators:stop']);
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  /// Wait for emulators to be ready
  Future<void> _waitForEmulators() async {
    const maxAttempts = 30;

    for (var i = 0; i < maxAttempts; i++) {
      try {
        final result = await Process.run('curl', [
          '-s',
          'http://localhost:9099/emulator/v1/projects/demo-project/config',
        ]);

        if (result.exitCode == 0) {
          print('   ✅ Emulators ready');
          return;
        }
      } catch (e) {
        // Continue waiting
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    throw const TimeoutException('Emulators failed to start');
  }

  /// Count test files in given patterns
  int _countTestFiles(List<String> patterns) {
    var count = 0;
    for (final patternPath in patterns) {
      // Handle patterns like 'test/features/*/domain/'
      if (patternPath.contains('*')) {
        final parts = patternPath.split('*');
        final basePath = parts[0];
        final subPath = parts.length > 1 ? parts[1] : '';

        final baseDir = Directory(basePath);
        if (baseDir.existsSync()) {
          try {
            baseDir.listSync().forEach((entity) {
              if (entity is Directory) {
                final potentialPath = '${entity.path}$subPath';
                final targetDir = Directory(
                  potentialPath.replaceAll('//', '/'),
                ); // Normalize path
                if (targetDir.existsSync()) {
                  count += targetDir
                      .listSync(recursive: true)
                      .where((f) => f.path.endsWith('_test.dart'))
                      .length;
                }
              }
            });
          } catch (e) {
            // Silently ignore errors if a path segment doesn't exist,
            // as flutter test might handle non-existent paths gracefully.
            // print('Warning: Could not count files for pattern $patternPath: $e');
          }
        }
      } else {
        // Handle exact paths
        final dir = Directory(patternPath);
        if (dir.existsSync()) {
          try {
            count += dir
                .listSync(recursive: true)
                .where((f) => f.path.endsWith('_test.dart'))
                .length;
          } catch (e) {
            // print('Warning: Could not count files for path $patternPath: $e');
          }
        }
      }
    }
    return count;
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }

  /// Print help information
  void printHelp() {
    print('''
Optimized Test Runner for VGV Firebase Project

Usage: dart test_runner.dart [options]

Options:
  --fast              Run only fast unit tests
  --skip-integration  Skip integration tests with emulators
  --coverage, -c      Generate coverage report
  --help              Show this help message

Test Phases:
  1. Unit Tests       Fast tests with mocks (10-15s)
  2. Integration      Firebase emulator tests (30-60s)  
  3. Widget Tests     UI component tests (15-30s)
  4. Coverage         Generate HTML coverage report

Examples:
  dart test_runner.dart                    # Run all tests
  dart test_runner.dart --fast             # Quick feedback loop
  dart test_runner.dart --coverage         # Full run with coverage
  dart test_runner.dart --skip-integration # Skip emulator tests
''');
  }
}

class TestFailureException implements Exception {
  const TestFailureException(this.message);
  final String message;

  @override
  String toString() => 'TestFailureException: $message';
}

class TimeoutException implements Exception {
  const TimeoutException(this.message);
  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
