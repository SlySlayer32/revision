// Firebase Authentication Emulator Connectivity Test
// VGV-compliant integration test for Firebase Auth emulator connectivity
// Tests emulator connection and basic Firebase Auth operations

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Firebase Emulator Connectivity Tests', () {
    const authEmulatorHost = 'localhost';
    const authEmulatorPort = 9099;
    const projectId = 'revision-fc66c';

    test('Firebase Auth emulator should be running and accessible', () async {
      try {
        // Test emulator health endpoint
        final response = await http.get(
          Uri.parse('http://$authEmulatorHost:$authEmulatorPort'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        expect(response.statusCode, equals(200));
        // ignore: avoid_print
        print(
          '✅ Firebase Auth emulator is running on '
          '$authEmulatorHost:$authEmulatorPort',
        );
      } catch (e) {
        fail('❌ Firebase Auth emulator is not accessible: $e\n'
            '💡 Make sure emulators are running:\n'
            '   firebase emulators:start --only auth');
      }
    });

    test('Firebase Auth emulator project configuration should be correct',
        () async {
      try {
        // Test project-specific endpoint
        final response = await http.get(
          Uri.parse(
            'http://$authEmulatorHost:$authEmulatorPort/emulator/v1/projects/$projectId/config',
          ),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        expect(response.statusCode, equals(200));
        // The emulator config endpoint does not return the projectId in the body.
        // Only check for 200 status code.
        // ignore: avoid_print
        print(
          '✅ Firebase Auth emulator project configuration endpoint '
          'returned 200 for $projectId',
        );
      } catch (e) {
        fail('❌ Firebase Auth emulator project config failed: $e');
      }
    });

    test('Firebase Auth emulator should accept user creation requests',
        () async {
      try {
        // Test user creation endpoint (realistic payload)
        final response = await http
            .post(
              Uri.parse(
                'http://$authEmulatorHost:$authEmulatorPort/'
                'identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key',
              ),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: '{"email": "testuser@example.com", '
                  '"password": "password123", "returnSecureToken": true}',
            )
            .timeout(const Duration(seconds: 5));

        // We expect either 200 (OK) or 400 (Bad Request) - both indicate the
        // emulator is accessible
        expect([200, 400], contains(response.statusCode));

        // ignore: avoid_print
        print(
          '✅ Firebase Auth emulator user creation endpoint is accessible',
        );
      } catch (e) {
        fail('❌ Firebase Auth emulator user creation endpoint failed: $e');
      }
    });

    test('Platform-specific emulator host resolution should work', () async {
      // Test different host configurations that would be used by the app
      final hostsToTest = <String>[
        'localhost',
        '127.0.0.1',
      ];

      // Add Android emulator host if on Windows (where Android development typically happens)
      if (Platform.isWindows) {
        hostsToTest.add('10.0.2.2');
      }

      var anyHostWorking = false;
      var workingHost = '';

      for (final host in hostsToTest) {
        try {
          final response = await http.get(
            Uri.parse('http://$host:$authEmulatorPort'),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            anyHostWorking = true;
            workingHost = host; // ignore: avoid_print
            print(
              '✅ Firebase Auth emulator accessible via '
              '$host:$authEmulatorPort',
            );
            break;
          }
        } catch (e) {
          // ignore: avoid_print
          print(
            '⚠️ Firebase Auth emulator not accessible via '
            '$host:$authEmulatorPort',
          );
        }
      }
      expect(
        anyHostWorking,
        isTrue,
        reason: 'At least one host configuration should work for emulator '
            'connectivity',
      );
      expect(
        workingHost,
        isNotEmpty,
        reason: 'Should have found a working host configuration',
      );

      // ignore: avoid_print
      print(
        '🎯 Recommended emulator host for current platform: $workingHost',
      );
    });

    test('Firebase emulator should clear user data on demand', () async {
      try {
        // Test the clear users endpoint
        final response = await http.delete(
          Uri.parse(
            'http://$authEmulatorHost:$authEmulatorPort/emulator/v1/projects/'
            '$projectId/accounts',
          ),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        // Expect 200 (OK) - data cleared successfully
        expect(response.statusCode, equals(200));

        // ignore: avoid_print
        print('✅ Firebase Auth emulator data clearing works correctly');
      } catch (e) {
        fail('❌ Firebase Auth emulator data clearing failed: $e');
      }
    });
  });
}
