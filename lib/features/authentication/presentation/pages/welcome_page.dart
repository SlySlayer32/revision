import 'package:flutter/material.dart';
import 'package:revision/core/navigation/route_factory.dart' as app_routes;
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/navigation/safe_navigation.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/app_info_service.dart';
import 'package:revision/core/services/deep_linking_service.dart';
import 'package:revision/core/services/offline_detection_service.dart';
import 'package:revision/features/authentication/presentation/pages/login_page.dart';
import 'package:revision/features/authentication/presentation/pages/signup_page.dart';

/// The initial page shown to unauthenticated users
class WelcomePage extends StatefulWidget {
  /// Creates a new [WelcomePage]
  const WelcomePage({super.key});

  /// Creates a [Route] for this page
  static Route<void> route() {
    return app_routes.RouteFactory.createRoute<void>(
      builder: (_) => const WelcomePage(),
      routeName: RouteNames.welcome,
    );
  }

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isOnline = true;
  bool _showAppInfo = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupListeners();
    _trackScreenView();
  }

  /// Initialize required services
  Future<void> _initializeServices() async {
    await AnalyticsService.initialize();
    await AppInfoService.initialize();
    await OfflineDetectionService.initialize();
    await DeepLinkingService.initialize();
  }

  /// Setup listeners for connectivity and deep links
  void _setupListeners() {
    // Listen to connectivity changes
    OfflineDetectionService.instance.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });

    // Listen to deep links
    DeepLinkingService.instance.linkStream.listen((deepLinkData) {
      if (mounted) {
        _handleDeepLink(deepLinkData);
      }
    });
  }

  /// Track screen view for analytics
  void _trackScreenView() {
    AnalyticsService.instance.trackScreenView(
      'welcome_page',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': AppInfoService.instance.fullVersion,
        'environment': AppInfoService.instance.environmentName,
      },
    );
  }

  /// Handle deep link navigation
  void _handleDeepLink(DeepLinkData deepLinkData) {
    if (deepLinkData.route != RouteNames.welcome) {
      SafeNavigation.pushNamed(context, deepLinkData.route);
    }
  }

  /// Handle login button press with analytics and safe navigation
  Future<void> _handleLoginPressed() async {
    // Track user action
    await AnalyticsService.instance.trackUserAction(
      'login_button_pressed',
      parameters: {
        'source': 'welcome_page',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Navigate safely
    if (mounted) {
      final result = await SafeNavigation.push(
        context,
        LoginPage.route(),
      );
      
      if (result != null) {
        await AnalyticsService.instance.trackNavigation(
          RouteNames.welcome,
          RouteNames.login,
        );
      }
    }
  }

  /// Handle signup button press with analytics and safe navigation
  Future<void> _handleSignupPressed() async {
    // Track user action
    await AnalyticsService.instance.trackUserAction(
      'signup_button_pressed',
      parameters: {
        'source': 'welcome_page',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Navigate safely
    if (mounted) {
      final result = await SafeNavigation.push(
        context,
        SignUpPage.route(),
      );
      
      if (result != null) {
        await AnalyticsService.instance.trackNavigation(
          RouteNames.welcome,
          RouteNames.signup,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Welcome to Revision App',
          child: const Text('Welcome'),
        ),
        actions: [
          // App info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'App Information',
            onPressed: () {
              setState(() {
                _showAppInfo = !_showAppInfo;
              });
            },
          ),
          // Offline indicator
          if (!_isOnline)
            Semantics(
              label: 'Offline mode - No internet connection',
              child: const Icon(
                Icons.wifi_off,
                color: Colors.red,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App info section
              if (_showAppInfo) _buildAppInfoSection(),
              
              // Offline banner
              if (!_isOnline) _buildOfflineBanner(),
              
              const Spacer(),
              
              // Welcome title
              Semantics(
                label: 'Welcome to Revision - AI-powered image editing app',
                child: const Text(
                  'Welcome to Revision',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // App description
              Semantics(
                label: 'App description: AI-powered image editing that seamlessly removes trees from gardens and changes wall colors - making it look like it was never edited',
                child: const Text(
                  'AI-powered image editing that seamlessly removes trees from gardens and changes wall colors - making it look like it was never edited',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              
              const Spacer(),
              
              // Login button
              Semantics(
                label: 'Login button - Navigate to login page',
                child: ElevatedButton(
                  onPressed: _handleLoginPressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Log In'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign up button
              Semantics(
                label: 'Sign up button - Navigate to registration page',
                child: OutlinedButton(
                  onPressed: _handleSignupPressed,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Build app info section
  Widget _buildAppInfoSection() {
    final appInfo = AppInfoService.instance;
    final securityWarnings = appInfo.securityWarnings;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Version: ${appInfo.fullVersion}'),
          Text('Environment: ${appInfo.environmentName.toUpperCase()}'),
          
          // Security warnings
          if (securityWarnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Security Warnings:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final warning in securityWarnings)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '• $warning',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Build offline banner
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are currently offline. Some features may not be available.',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
