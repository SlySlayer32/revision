import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/debug/debug_info_sanitizer.dart';
import 'package:revision/firebase_options.dart';

/// A quick verification page for launch configuration
/// This page is only available in development and staging environments
class LaunchConfigVerificationPage extends StatelessWidget {
  const LaunchConfigVerificationPage({super.key});

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

    return const LaunchConfigVerificationPage();
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
    DebugInfoSanitizer.logDebugPageAccess('LaunchConfigVerificationPage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Launch Config Verification'),
        backgroundColor: _getStatusColor(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityWarningCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildApiKeyCard(),
            const SizedBox(height: 16),
            _buildEnvironmentCard(),
            const SizedBox(height: 16),
            _buildFirebaseCard(),
            const SizedBox(height: 24),
            _buildLaunchInstructionsCard(),
          ],
        ),
      ),
    );
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

  Color _getStatusColor() {
    if (EnvConfig.isFirebaseAIConfigured && EnvironmentDetector.isDevelopment) {
      return Colors.green;
    } else if (EnvConfig.isFirebaseAIConfigured) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildStatusCard() {
    final isConfigured = EnvConfig.isFirebaseAIConfigured;
    final environment = EnvironmentDetector.environmentString;

    return Card(
      color: _getStatusColor().withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConfigured ? Icons.check_circle : Icons.error,
                  color: _getStatusColor(),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Launch Configuration Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Status: ${isConfigured ? '✅ Ready' : '❌ Not Configured'}'),
            Text('Environment: $environment'),
            if (!isConfigured) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ API Key not configured. Use VS Code launch configs or set environment variable.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔑 Firebase AI Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Firebase AI Configured: ${EnvConfig.isFirebaseAIConfigured ? 'Yes' : 'No'}',
            ),
            const Text('API keys are managed by Firebase Console'),
            if (EnvConfig.isFirebaseAIConfigured) ...[
              const Text('✅ Firebase AI Logic is properly configured'),
              const SizedBox(height: 4),
              const Text(
                'Using Firebase-managed API keys (recommended)',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    final debugInfo = EnvironmentDetector.getDebugInfo();
    // Sanitize sensitive information
    final sanitizedDebugInfo = DebugInfoSanitizer.sanitizeDebugInfo(debugInfo);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌍 Environment Detection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Current: ${EnvironmentDetector.environmentString}'),
            Text('Is Web: ${sanitizedDebugInfo['isWeb']}'),
            Text('Debug Mode: ${sanitizedDebugInfo['isDebugMode']}'),
            Text('Compile-time Env: ${sanitizedDebugInfo['compileTimeEnv']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseCard() {
    final firebaseDebug = DefaultFirebaseOptions.getDebugInfo();
    // Sanitize sensitive Firebase information
    final sanitizedFirebaseInfo = DebugInfoSanitizer.sanitizeFirebaseInfo(firebaseDebug);
    
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
            Text('Environment: ${sanitizedFirebaseInfo['environment']}'),
            Text('Platform: ${sanitizedFirebaseInfo['platform']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLaunchInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 VS Code Launch Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Available launch configurations:'),
            const SizedBox(height: 4),
            const Text('• 🔧 Development - Main development config'),
            const Text('• 🌐 Development Web - Web development (updated)'),
            const Text('• 🌐 Staging Web - Web staging environment'),
            const Text('• 🌐 Production Web - Web production environment'),
            const Text('• 📱 Development Android - Android development'),
            const Text('• 🍎 Development iOS - iOS development'),
            const Text('• 🧪 Development + Debug Tools - With extra debugging'),
            const Text('• 🟡 Staging - Staging environment'),
            const Text('• 🔴 Production - Production environment'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Web Configuration Fixed!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('• Removed deprecated --web-renderer flag'),
                  Text('• Uses modern Flutter web defaults (CanvasKit)'),
                  Text('• Added staging and production web configs'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Press F5 or Ctrl+F5 in VS Code to select a configuration!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
