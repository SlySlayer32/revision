import 'package:flutter/material.dart';
import 'package:revision/core/navigation/safe_navigation.dart';
import 'package:revision/core/navigation/route_names.dart';

/// Example integration of the enhanced SafeNavigation system
class SafeNavigationExample extends StatefulWidget {
  const SafeNavigationExample({Key? key}) : super(key: key);

  @override
  State<SafeNavigationExample> createState() => _SafeNavigationExampleState();
}

class _SafeNavigationExampleState extends State<SafeNavigationExample> {
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _stateStats;
  final TextEditingController _deepLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final analytics = SafeNavigation.getAnalytics();
    final stateStats = await SafeNavigation.getStateStatistics();
    
    if (mounted) {
      setState(() {
        _analytics = analytics;
        _stateStats = stateStats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Navigation Demo'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation Examples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Navigation Examples',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _navigateToRoute(RouteNames.dashboard),
                          child: const Text('Dashboard'),
                        ),
                        ElevatedButton(
                          onPressed: () => _navigateToRoute(RouteNames.aiProcessing),
                          child: const Text('AI Processing'),
                        ),
                        ElevatedButton(
                          onPressed: () => _navigateToRoute('/invalid-route'),
                          child: const Text('Invalid Route'),
                        ),
                        ElevatedButton(
                          onPressed: () => _navigateWithArguments(),
                          child: const Text('With Arguments'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Deep Link Testing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deep Link Testing',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _deepLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Deep Link URL',
                        hintText: 'https://revision.app/dashboard?tab=ai',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _handleDeepLink,
                          child: const Text('Test Deep Link'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _testPredefinedDeepLink(
                            'https://revision.app/dashboard?tab=ai',
                          ),
                          child: const Text('Valid Link'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _testPredefinedDeepLink(
                            'https://malicious.com/dashboard?script=alert(1)',
                          ),
                          child: const Text('Malicious Link'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Analytics Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Navigation Analytics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_analytics != null) ...[
                      _buildAnalyticsRow('Total Events', _analytics!['total_events']),
                      _buildAnalyticsRow('Successful Navigations', _analytics!['successful_navigations']),
                      _buildAnalyticsRow('Failed Navigations', _analytics!['failed_navigations']),
                      _buildAnalyticsRow('Deep Link Attempts', _analytics!['deep_link_attempts']),
                      _buildAnalyticsRow('Success Rate', '${_analytics!['success_rate'].toStringAsFixed(1)}%'),
                    ] else
                      const Text('Loading analytics...'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Refresh Analytics'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // State Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Navigation State',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_stateStats != null) ...[
                      _buildAnalyticsRow('State Exists', _stateStats!['exists']),
                      if (_stateStats!['exists'] == true) ...[
                        _buildAnalyticsRow('Current Route', _stateStats!['current_route']),
                        _buildAnalyticsRow('Stack Depth', _stateStats!['stack_depth']),
                        _buildAnalyticsRow('Has Arguments', _stateStats!['has_arguments']),
                      ],
                    ] else
                      const Text('Loading state info...'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Refresh State'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _clearState,
                          child: const Text('Clear State'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _restoreState,
                          child: const Text('Restore State'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToRoute(String route) async {
    await SafeNavigation.pushNamed(context, route);
    _loadData(); // Refresh analytics
  }

  Future<void> _navigateWithArguments() async {
    await SafeNavigation.pushNamed(
      context,
      RouteNames.aiProcessing,
      arguments: {
        'selectedImage': 'demo_image.jpg',
        'processingType': 'segmentation',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _loadData(); // Refresh analytics
  }

  Future<void> _handleDeepLink() async {
    final deepLink = _deepLinkController.text.trim();
    if (deepLink.isNotEmpty) {
      await SafeNavigation.handleDeepLink(context, deepLink);
      _loadData(); // Refresh analytics
    }
  }

  Future<void> _testPredefinedDeepLink(String deepLink) async {
    _deepLinkController.text = deepLink;
    await SafeNavigation.handleDeepLink(context, deepLink);
    _loadData(); // Refresh analytics
  }

  Future<void> _clearState() async {
    await SafeNavigation.clearNavigationState();
    _loadData(); // Refresh state info
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation state cleared')),
      );
    }
  }

  Future<void> _restoreState() async {
    await SafeNavigation.restoreNavigationState(context);
    _loadData(); // Refresh state info
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation state restored')),
      );
    }
  }

  @override
  void dispose() {
    _deepLinkController.dispose();
    super.dispose();
  }
}

/// Integration example for main app
class SafeNavigationIntegrationExample {
  /// Example of how to integrate SafeNavigation into your main app
  static Future<void> setupSafeNavigation() async {
    // Initialize the SafeNavigation system
    await SafeNavigation.initialize();
    
    // Configure logger for your environment
    // (This is done automatically, but you can customize it)
  }
  
  /// Example of handling app deep links
  static Future<void> handleAppDeepLink(String deepLink) async {
    // In your app's deep link handler
    // This would typically be called from your app's URL handler
    
    // Use a builder context or navigate to a temporary page first
    // then handle the deep link
    
    // Example usage in a stateful widget:
    // await SafeNavigation.handleDeepLink(context, deepLink);
  }
  
  /// Example of restoring navigation state on app startup
  static Future<void> restoreNavigationOnStartup(BuildContext context) async {
    // Call this in your app's initialization
    await SafeNavigation.restoreNavigationState(context);
  }
  
  /// Example of clearing navigation state on logout
  static Future<void> handleLogout() async {
    // Clear navigation state when user logs out
    await SafeNavigation.clearNavigationState();
    
    // Then navigate to login screen
    // await SafeNavigation.pushNamed(context, RouteNames.login);
  }
}