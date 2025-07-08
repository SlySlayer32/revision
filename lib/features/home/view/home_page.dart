import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/navigation/route_factory.dart' as app_routes;
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/feature_flag_service.dart';
import 'package:revision/core/services/onboarding_service.dart';
import 'package:revision/core/services/security_notification_service.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';

/// The main page shown to authenticated users
class HomePage extends StatefulWidget {
  /// Creates a new [HomePage]
  const HomePage({super.key});

  /// Creates a [Route] for this page
  static Route<void> route() {
    return app_routes.RouteFactory.createRoute<void>(
      builder: (_) => const HomePage(),
      routeName: RouteNames.home,
    );
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AnalyticsService _analytics = GetIt.instance<AnalyticsService>();
  final FeatureFlagService _featureFlags = GetIt.instance<FeatureFlagService>();
  final OnboardingService _onboardingService = GetIt.instance<OnboardingService>();
  final SecurityNotificationService _securityService = GetIt.instance<SecurityNotificationService>();

  @override
  void initState() {
    super.initState();
    _initializeHomePage();
  }

  Future<void> _initializeHomePage() async {
    // Track page view
    await _analytics.trackPageView('home');
    
    // Show onboarding if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _onboardingService.showOnboardingIfNeeded(context);
      await _securityService.checkSecurityNotifications(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision'),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await _analytics.trackAction('settings_opened');
              // Navigate to settings page
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _analytics.trackAction('logout_requested');
              context.read<AuthenticationBloc>().add(
                const AuthenticationLogoutRequested(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome section
            _buildWelcomeSection(),
            
            // Main features section
            _buildMainFeaturesSection(),
            
            // Debug tools section (only shown in development/staging)
            if (_featureFlags.showDebugTools) _buildDebugToolsSection(),
            
            // Quick actions section
            _buildQuickActionsSection(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Revision!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered image editing made simple',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await _analytics.trackAction('get_started_clicked');
              // Navigate to image selection
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Get Started'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Main Features',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.content_cut,
                  title: 'Object Removal',
                  description: 'Remove unwanted objects from your photos',
                  onTap: () async {
                    await _analytics.trackFeatureUsage('object_removal');
                    // Navigate to object removal feature
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.palette,
                  title: 'Color Editing',
                  description: 'Change colors and enhance your images',
                  onTap: () async {
                    await _analytics.trackFeatureUsage('color_editing');
                    // Navigate to color editing feature
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.auto_fix_high,
                  title: 'AI Enhancement',
                  description: 'Automatically enhance image quality',
                  onTap: () async {
                    await _analytics.trackFeatureUsage('ai_enhancement');
                    // Navigate to AI enhancement feature
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.history,
                  title: 'Edit History',
                  description: 'View and manage your edit history',
                  onTap: () async {
                    await _analytics.trackFeatureUsage('edit_history');
                    // Navigate to edit history
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugToolsSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Debug Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _analytics.trackAction('debug_environment_info');
                  _showEnvironmentInfo();
                },
                icon: const Icon(Icons.info),
                label: const Text('Environment Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _analytics.trackAction('debug_feature_flags');
                  _showFeatureFlagsInfo();
                },
                icon: const Icon(Icons.flag),
                label: const Text('Feature Flags'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _analytics.trackAction('debug_test_gemini');
                  _testGeminiAPI();
                },
                icon: const Icon(Icons.psychology),
                label: const Text('Test Gemini API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _analytics.trackAction('quick_edit_clicked');
                    // Navigate to quick edit
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Quick Edit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _analytics.trackAction('tutorial_clicked');
                    // Show tutorial
                  },
                  icon: const Icon(Icons.help),
                  label: const Text('Tutorial'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEnvironmentInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Environment Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Environment: ${_featureFlags.getAllFlags()['environment']}'),
              Text('Debug Mode: ${_featureFlags.getAllFlags()['isDevelopment']}'),
              Text('Production: ${_featureFlags.getAllFlags()['isProduction']}'),
              Text('Analytics: ${_featureFlags.getAllFlags()['enableAnalytics']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeatureFlagsInfo() {
    final flags = _featureFlags.getAllFlags();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Flags'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: flags.entries.map((entry) {
              return Text('${entry.key}: ${entry.value}');
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _testGeminiAPI() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing Gemini API connection...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
