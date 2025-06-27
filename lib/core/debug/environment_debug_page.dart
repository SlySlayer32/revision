import 'package:flutter/material.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/firebase_options.dart';

/// A debug page to display environment detection information
class EnvironmentDebugPage extends StatelessWidget {
  const EnvironmentDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Current Environment: ${EnvironmentDetector.environmentString}'),
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
            Text('Firebase AI: ${EnvConfig.isFirebaseAIConfigured ? 'Configured' : 'Not Configured'}'),
            const SizedBox(height: 8),
            const Text('Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                debugInfo.toString(),
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
            Text('Project ID: ${firebaseDebugInfo['projectId']}'),
            Text('App ID: ${firebaseDebugInfo['appId']}'),
            Text('Platform: ${firebaseDebugInfo['platform']}'),
            Text('Is Web: ${firebaseDebugInfo['isWeb']}'),
            const SizedBox(height: 8),
            const Text('Firebase Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                firebaseDebugInfo.toString(),
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
