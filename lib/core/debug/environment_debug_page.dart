import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/debug/debug_info_sanitizer.dart';
import 'package:revision/firebase_options.dart';

/// A debug page to display environment detection information
/// This page is only available in development and staging environments
class EnvironmentDebugPage extends StatelessWidget {
  const EnvironmentDebugPage({super.key});

  /// Factory method to create debug page with proper access control
  static Widget? createIfAllowed() {
    // Production build guard: This page should never be accessible in production
    if (EnvironmentDetector.isProduction) {
      return null;
    }

    // Debug mode guard: Additional protection for release builds
    if (kReleaseMode && !kDebugMode) {
      return null;
    }

    return const EnvironmentDebugPage();
  }

  @override
  Widget build(BuildContext context) {
    // Production build guard: This page should never be accessible in production
    if (EnvironmentDetector.isProduction) {
      return _buildProductionBlockedPage();
    }

    // Debug mode guard: Additional protection for release builds
    if (kReleaseMode && !kDebugMode) {
      return _buildProductionBlockedPage();
    }

    // Log debug page access for audit purposes
    _logDebugPageAccess();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Debug'),
        backgroundColor: _getEnvironmentColor(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityWarningCard(),
            const SizedBox(height: 16),
            _buildEnvironmentCard(),
            const SizedBox(height: 16),
            _buildConfigCard(),
            const SizedBox(height: 16),
            _buildFirebaseCard(),
            const SizedBox(height: 16),
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Color _getEnvironmentColor() {
    switch (EnvironmentDetector.currentEnvironment) {
      case AppEnvironment.development:
        return Colors.green;
      case AppEnvironment.staging:
        return Colors.orange;
      case AppEnvironment.production:
        return Colors.red;
    }
  }

  /// Builds a page shown when debug access is blocked in production
  Widget _buildProductionBlockedPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Restricted'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Debug Features Not Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Debug pages are not available in production builds for security reasons.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logs debug page access for audit purposes
  void _logDebugPageAccess() {
    DebugInfoSanitizer.logDebugPageAccess('EnvironmentDebugPage');
  }

  /// Builds a security warning card
  Widget _buildSecurityWarningCard() {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Security Warning',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This debug page contains sensitive information and is only available in non-production environments.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌍 Environment Detection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getEnvironmentColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Environment: ${EnvironmentDetector.environmentString}',
            ),
            Text('Is Development: ${EnvironmentDetector.isDevelopment}'),
            Text('Is Staging: ${EnvironmentDetector.isStaging}'),
            Text('Is Production: ${EnvironmentDetector.isProduction}'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    final debugInfo = EnvConfig.getDebugInfo();
    // Sanitize sensitive information
    final sanitizedDebugInfo = DebugInfoSanitizer.sanitizeDebugInfo(debugInfo);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Firebase AI Configured: ${EnvConfig.isFirebaseAIConfigured}'),
            Text(
              'Firebase AI: ${EnvConfig.isFirebaseAIConfigured ? 'Configured' : 'Not Configured'}',
            ),
            const SizedBox(height: 8),
            const Text(
              'Debug Info (Sanitized):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sanitizedDebugInfo.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseCard() {
    final firebaseDebugInfo = DefaultFirebaseOptions.getDebugInfo();
    // Sanitize sensitive Firebase information
    final sanitizedFirebaseInfo = DebugInfoSanitizer.sanitizeFirebaseInfo(firebaseDebugInfo);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔥 Firebase Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Project ID: ${sanitizedFirebaseInfo['projectId']}'),
            Text('App ID: ${sanitizedFirebaseInfo['appId']}'),
            Text('Platform: ${sanitizedFirebaseInfo['platform']}'),
            Text('Is Web: ${sanitizedFirebaseInfo['isWeb']}'),
            const SizedBox(height: 8),
            const Text(
              'Firebase Debug Info (Sanitized):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sanitizedFirebaseInfo.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔄 Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Log the debug action for audit purposes
                DebugInfoSanitizer.logDebugAction('Environment Detection Refresh');
                EnvironmentDetector.refresh();
                // Force rebuild by calling setState if this was a StatefulWidget
                // For now, user needs to navigate away and back
              },
              child: const Text('Refresh Environment Detection'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: To see changes, navigate away and back to this page.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

}
