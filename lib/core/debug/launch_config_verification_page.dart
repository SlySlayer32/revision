import 'package:flutter/material.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/firebase_options.dart';

/// A quick verification page for launch configuration
class LaunchConfigVerificationPage extends StatelessWidget {
  const LaunchConfigVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Firebase AI Configured: ${EnvConfig.isFirebaseAIConfigured ? 'Yes' : 'No'}'),
            const Text('API keys are managed by Firebase Console'),
            if (EnvConfig.isFirebaseAIConfigured) ...[
              const Text('✅ Firebase AI Logic is properly configured'),
              const SizedBox(height: 4),
              const Text(
                'Using Firebase-managed API keys (recommended)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    final debugInfo = EnvironmentDetector.getDebugInfo();
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
            Text('Is Web: ${debugInfo['isWeb']}'),
            Text('Debug Mode: ${debugInfo['isDebugMode']}'),
            Text('Compile-time Env: ${debugInfo['compileTimeEnv']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseCard() {
    final firebaseDebug = DefaultFirebaseOptions.getDebugInfo();
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
            Text('Project ID: ${firebaseDebug['projectId']}'),
            Text('Environment: ${firebaseDebug['environment']}'),
            Text('Platform: ${firebaseDebug['platform']}'),
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
                        fontWeight: FontWeight.bold, color: Colors.green),
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
