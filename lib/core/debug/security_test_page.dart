import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/debug/debug_info_sanitizer.dart';
import 'package:revision/core/debug/environment_debug_page.dart';
import 'package:revision/core/debug/launch_config_verification_page.dart';

/// Manual test page to verify security controls
class SecurityTestPage extends StatelessWidget {
  const SecurityTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Test Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Page Security Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Environment info
            _buildEnvironmentInfo(),
            const SizedBox(height: 16),
            
            // Debug page access tests
            _buildDebugPageTests(context),
            const SizedBox(height: 16),
            
            // Data sanitization tests
            _buildSanitizationTests(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Environment Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Current Environment: ${EnvironmentDetector.environmentString}'),
            Text('Is Production: ${EnvironmentDetector.isProduction}'),
            Text('Is Debug Mode: $kDebugMode'),
            Text('Is Release Mode: $kReleaseMode'),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugPageTests(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Debug Page Access Tests:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Test environment debug page
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final debugPage = EnvironmentDebugPage.createIfAllowed();
                      if (debugPage != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => debugPage),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debug page blocked (expected in production)')),
                        );
                      }
                    },
                    child: const Text('Test Environment Debug Page'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Test launch config page
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final launchPage = LaunchConfigVerificationPage.createIfAllowed();
                      if (launchPage != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => launchPage),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Launch config page blocked (expected in production)')),
                        );
                      }
                    },
                    child: const Text('Test Launch Config Page'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSanitizationTests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data Sanitization Tests:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Test sensitive data masking
            const Text('API Key Masking Test:'),
            Text('Original: api_key_123456789'),
            Text('Masked: ${DebugInfoSanitizer.maskSensitiveValue('api_key_123456789')}'),
            const SizedBox(height: 8),
            
            const Text('Short Value Masking Test:'),
            Text('Original: secret'),
            Text('Masked: ${DebugInfoSanitizer.maskSensitiveValue('secret')}'),
            const SizedBox(height: 8),
            
            const Text('Debug Info Sanitization Test:'),
            Text('Test Data: ${_getTestDebugInfo()}'),
            Text('Sanitized: ${DebugInfoSanitizer.sanitizeDebugInfo(_getTestDebugInfo())}'),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTestDebugInfo() {
    return {
      'api_key': 'test_key_123456789',
      'username': 'test_user',
      'secret_token': 'secret_token_abcdefghijk',
      'normal_config': 'public_value',
      'password': 'mypassword123',
    };
  }
}