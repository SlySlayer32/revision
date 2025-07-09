import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:revision/core/services/logging_service.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/navigation/route_names.dart';

/// Deep linking service for handling app links and navigation
class DeepLinkingService {
  const DeepLinkingService._();

  static const DeepLinkingService _instance = DeepLinkingService._();
  static DeepLinkingService get instance => _instance;

  static bool _isInitialized = false;
  static final StreamController<DeepLinkData> _linkController = StreamController<DeepLinkData>.broadcast();

  /// Initialize the deep linking service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kDebugMode) {
      LoggingService.instance.debug('DeepLinking: Initializing...');
    }
    
    try {
      // Check for initial link (when app was launched from a link)
      await _getInitialLink();
      
      // Listen for incoming links (when app is already running)
      _listenForIncomingLinks();
      
      _isInitialized = true;
      LoggingService.instance.info('DeepLinking: Initialized successfully');
    } catch (e) {
      LoggingService.instance.error(
        'DeepLinking: Failed to initialize', 
        error: e,
      );
    }
  }

  /// Get the initial link when app was launched
  static Future<void> _getInitialLink() async {
    try {
      // For now, we'll simulate deep link handling
      // In a real app, you would use plugins like:
      // - app_links
      // - uni_links
      // - go_router for URL-based routing
      
      // Simulate checking for initial link
      // final initialLink = await getInitialLink();
      // if (initialLink != null) {
      //   _handleIncomingLink(initialLink);
      // }
      
      LoggingService.instance.debug('DeepLinking: Initial link checked');
    } catch (e) {
      LoggingService.instance.error('DeepLinking: Failed to get initial link', error: e);
    }
  }

  /// Listen for incoming links when app is running
  static void _listenForIncomingLinks() {
    try {
      // For now, we'll simulate link listening
      // In a real app, you would use:
      // linkStream.listen((String link) {
      //   _handleIncomingLink(link);
      // });
      
      LoggingService.instance.debug('DeepLinking: Link listener started');
    } catch (e) {
      LoggingService.instance.error('DeepLinking: Failed to start link listener', error: e);
    }
  }

  /// Handle incoming deep link
  static void _handleIncomingLink(String link) {
    try {
      final deepLinkData = _parseDeepLink(link);
      if (deepLinkData != null) {
        _linkController.add(deepLinkData);
        
        // Track deep link usage
        getIt<AnalyticsService>().trackAction(
          'deep_link_opened',
          parameters: {
            'link': link,
            'route': deepLinkData.route,
            'parameters': deepLinkData.parameters,
          },
        );
        
        LoggingService.instance.info('DeepLinking: Deep link handled: $link');
      }
    } catch (e) {
      LoggingService.instance.error('DeepLinking: Failed to handle link: $link', error: e);
    }
  }

  /// Parse deep link into structured data
  static DeepLinkData? _parseDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      final pathSegments = uri.pathSegments;
      
      String route = RouteNames.welcome; // Default route
      Map<String, dynamic> parameters = {};
      
      // Parse different link formats
      if (pathSegments.isNotEmpty) {
        switch (pathSegments[0]) {
          case 'welcome':
            route = RouteNames.welcome;
            break;
          case 'login':
            route = RouteNames.login;
            break;
          case 'signup':
            route = RouteNames.signup;
            break;
          case 'dashboard':
            route = RouteNames.dashboard;
            break;
          case 'image-selection':
            route = RouteNames.imageSelection;
            break;
          case 'ai-processing':
            route = RouteNames.aiProcessing;
            break;
          default:
            route = RouteNames.welcome;
        }
      }
      
      // Add query parameters
      parameters.addAll(uri.queryParameters);
      
      return DeepLinkData(
        originalLink: link,
        route: route,
        parameters: parameters,
      );
    } catch (e) {
      LoggingService.instance.error('DeepLinking: Failed to parse link: $link', error: e);
      return null;
    }
  }

  /// Get deep link stream
  Stream<DeepLinkData> get linkStream => _linkController.stream;

  /// Create a deep link URL
  String createDeepLink(String route, {Map<String, String>? parameters}) {
    final baseUrl = 'https://revision.app'; // Your app's URL scheme
    final uri = Uri.parse('$baseUrl$route');
    
    if (parameters != null && parameters.isNotEmpty) {
      return uri.replace(queryParameters: parameters).toString();
    }
    
    return uri.toString();
  }

  /// Handle programmatic navigation via deep link
  Future<void> handleDeepLink(String link) async {
    _handleIncomingLink(link);
  }

  /// Dispose of resources
  static void dispose() {
    _linkController.close();
    _isInitialized = false;
  }
}

/// Data class for deep link information
class DeepLinkData {
  final String originalLink;
  final String route;
  final Map<String, dynamic> parameters;

  const DeepLinkData({
    required this.originalLink,
    required this.route,
    required this.parameters,
  });

  @override
  String toString() {
    return 'DeepLinkData(originalLink: $originalLink, route: $route, parameters: $parameters)';
  }
}
