import 'package:flutter/material.dart';
import 'package:revision/core/debug/environment_debug_page.dart';
import 'package:revision/core/debug/launch_config_verification_page.dart';

/// Example of how to safely use debug pages with proper security controls
class SecureDebugExample extends StatelessWidget {
  const SecureDebugExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Debug Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Debug Page Usage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'This example shows how to safely use debug pages with proper security controls.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Example 1: Environment Debug Page
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Environment Debug Page',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shows environment detection, configuration (sanitized), and Firebase info (sanitized).',
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _navigateToDebugPage(context, 'environment'),
                      child: const Text('Open Environment Debug'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Example 2: Launch Config Verification Page
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Launch Config Verification Page',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verifies launch configuration and Firebase setup with sanitized data.',
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _navigateToDebugPage(context, 'launch'),
                      child: const Text('Open Launch Config Verification'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Security Notes
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Security Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Debug pages are automatically blocked in production'),
                    const Text('• Sensitive data is automatically sanitized'),
                    const Text('• All debug actions are logged for audit'),
                    const Text('• Access is controlled by environment detection'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDebugPage(BuildContext context, String type) {
    Widget? debugPage;
    
    switch (type) {
      case 'environment':
        debugPage = EnvironmentDebugPage.createIfAllowed();
        break;
      case 'launch':
        debugPage = LaunchConfigVerificationPage.createIfAllowed();
        break;
    }
    
    if (debugPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => debugPage!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug page is not available in this environment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}