// Firebase Auth Emulator Test User Creation Script
// Creates test users in the Firebase Auth emulator for integration testing

import 'dart:convert';

import 'package:http/http.dart' as http;

class TestUserCreator {
  static const String emulatorHost = 'localhost';
  static const String authPort = '9099';
  static const String baseUrl = 'http://$emulatorHost:$authPort';
  static const String adminBaseUrl =
      '$baseUrl/identitytoolkit.googleapis.com/v1';

  static Future<void> main() async {
    print('🔥 Creating Test Users in Firebase Auth Emulator');
    print('=' * 55);

    final testUsers = [
      {
        'email': 'test.user@example.com',
        'password': 'password123',
        'displayName': 'Test User',
        'isAdmin': false,
      },
      {
        'email': 'admin.user@example.com',
        'password': 'admin123',
        'displayName': 'Admin User',
        'isAdmin': true,
      },
      {
        'email': 'integration.test@example.com',
        'password': 'integration123',
        'displayName': 'Integration Test User',
        'isAdmin': false,
      },
    ];

    for (final userData in testUsers) {
      await _createUser(userData);
    }

    print('\n✅ All test users created successfully!');
    print('🎯 Ready for integration testing');
  }

  static Future<void> _createUser(Map<String, dynamic> userData) async {
    print('\n👤 Creating user: ${userData['email']}');

    try {
      final customClaims = {
        'admin': userData['isAdmin'],
        'createdBy': 'test-script',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$adminBaseUrl/projects/demo-project/accounts'),
        headers: {
          'Authorization': 'Bearer owner',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': userData['email'],
          'password': userData['password'],
          'displayName': userData['displayName'],
          'emailVerified': true,
          'disabled': false,
          'customAttributes': json.encode(customClaims),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final uid = responseData['localId'];

        print('✅ Created: ${userData['email']}');
        print('   UID: $uid');
        print('   Display Name: ${userData['displayName']}');
        print('   Admin: ${userData['isAdmin']}');
      } else {
        print(
          '❌ Failed to create ${userData['email']}: ${response.statusCode}',
        );
        print('   Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error creating ${userData['email']}: $e');
    }
  }
}

void main() async {
  await TestUserCreator.main();
}
