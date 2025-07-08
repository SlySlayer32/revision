import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/feature_flag_service.dart';

/// Onboarding service that manages user onboarding flow
///
/// This service handles the onboarding process for new users,
/// including welcome screens, feature introductions, and setup guides.
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._();
  factory OnboardingService() => _instance;
  OnboardingService._();

  final AnalyticsService _analytics = AnalyticsService();
  final FeatureFlagService _featureFlags = FeatureFlagService();

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      // In a real implementation, this would check user preferences or server state
      // For now, we'll simulate based on feature flags
      return !_featureFlags.enableOnboarding;
    } catch (e) {
      log('❌ Failed to check onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      // In a real implementation, this would save to user preferences or server
      await _analytics.trackOnboardingCompleted('full_onboarding');
      log('✅ Onboarding completed');
    } catch (e) {
      log('❌ Failed to complete onboarding: $e');
    }
  }

  /// Show onboarding if needed
  Future<void> showOnboardingIfNeeded(BuildContext context) async {
    if (!context.mounted || !_featureFlags.enableOnboarding) return;

    try {
      final hasCompleted = await hasCompletedOnboarding();
      if (!hasCompleted) {
        await _showOnboardingFlow(context);
      }
    } catch (e) {
      log('❌ Failed to show onboarding: $e');
      await _analytics.trackError('onboarding_show_failed', context: e.toString());
    }
  }

  /// Show the onboarding flow
  Future<void> _showOnboardingFlow(BuildContext context) async {
    if (!context.mounted) return;

    await _analytics.trackAction('onboarding_started');

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const OnboardingFlow(),
        settings: const RouteSettings(name: '/onboarding'),
      ),
    );
  }
}

/// Onboarding flow widget
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  final AnalyticsService _analytics = AnalyticsService();
  
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _analytics.trackPageView('onboarding_page_0');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    await _onboardingService.completeOnboarding();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _analytics.trackPageView('onboarding_page_$index');
                },
                children: const [
                  OnboardingPage(
                    title: 'Welcome to Revision',
                    subtitle: 'AI-powered image editing made simple',
                    description: 'Transform your photos with intelligent editing that seamlessly removes objects and enhances your images.',
                    icon: Icons.auto_awesome,
                    color: Colors.blue,
                  ),
                  OnboardingPage(
                    title: 'Smart Object Removal',
                    subtitle: 'Remove unwanted objects effortlessly',
                    description: 'Our AI technology intelligently identifies and removes objects from your photos, making it look like they were never there.',
                    icon: Icons.content_cut,
                    color: Colors.green,
                  ),
                  OnboardingPage(
                    title: 'Get Started',
                    subtitle: 'Ready to create amazing edits?',
                    description: 'Start by selecting an image and let our AI help you create the perfect edit. Your creativity, enhanced by AI.',
                    icon: Icons.rocket_launch,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  TextButton(
                    onPressed: _currentPage > 0 ? _previousPage : null,
                    child: const Text('Back'),
                  ),
                  
                  // Skip button
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Skip'),
                  ),
                  
                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage < _totalPages - 1 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual onboarding page
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(64),
            ),
            child: Icon(
              icon,
              size: 64,
              color: color,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}