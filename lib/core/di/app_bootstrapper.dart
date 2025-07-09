import 'package:flutter/foundation.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/di/enhanced_service_locator.dart';
import 'package:revision/core/services/error_monitoring/production_error_monitor_v2.dart';
import 'package:revision/core/services/error_monitoring/error_monitoring_config.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

/// Example of how to integrate the enhanced service locator with the main app
class AppBootstrapper {
  static bool _isInitialized = false;

  /// Initialize the app with enhanced service locator
  static Future<void> initializeApp() async {
    if (_isInitialized) return;

    final logger = EnhancedLogger();
    
    try {
      logger.info('Starting app initialization', operation: 'APP_BOOTSTRAP');

      // Step 1: Initialize error monitoring
      ProductionErrorMonitorV2.initialize(
        config: kDebugMode 
            ? const TestErrorMonitoringConfig() 
            : const DefaultErrorMonitoringConfig(),
        logger: logger,
      );

      // Step 2: Setup service locator with validation
      await setupServiceLocator();
      await EnhancedServiceLocator.initialize(getIt: getIt, logger: logger);
      final initResult = await EnhancedServiceLocator.instance.initializeWithValidation();


      // Step 3: Verify system health
      if (!initResult.isSuccessful) {
        logger.warning(
          'System health check failed during initialization',
          operation: 'APP_BOOTSTRAP',
          context: initResult.getSummary(),
        );
        
        // Could show a warning to user or attempt recovery
        await _attemptSystemRecovery();
      }

      // Step 4: Log successful initialization
      logger.info(
        'App initialization completed successfully',
        operation: 'APP_BOOTSTRAP',
        context: {
          'system_health_score': initResult.healthReport?.overallHealthScore,
          'is_healthy': initResult.healthReport?.isHealthy,
          'services_count': initResult.validationResult?.validationResults.length,
        },
      );

      _isInitialized = true;
    } catch (e, stackTrace) {
      logger.error(
        'App initialization failed: $e',
        operation: 'APP_BOOTSTRAP',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Record critical failure
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'AppBootstrapper.initializeApp',
        metadata: {'initialization_failed': true},
      );
      
      rethrow;
    }
  }

  /// Attempt to recover from system health issues
  static Future<void> _attemptSystemRecovery() async {
    final logger = EnhancedLogger();
    
    try {
      logger.info('Attempting system recovery', operation: 'SYSTEM_RECOVERY');
      
      // Get list of failing services
      final failingServices = EnhancedServiceLocator.instance.getStatistics()['failing_services'] as List<String>;
      
      if (failingServices.isEmpty) {
        logger.info('No failing services found', operation: 'SYSTEM_RECOVERY');
        return;
      }
      
      // Attempt recovery for each failing service
      for (final serviceType in failingServices) {
        logger.info(
          'Attempting recovery for service: ${serviceType.toString()}',
          operation: 'SYSTEM_RECOVERY',
        );
        
        // Note: In a real implementation, you would need to map Type to concrete recovery
        // For now, we'll just log the attempt
      }
      
      // Re-check system health after recovery attempts
      final healthReport = await EnhancedServiceLocator.instance.getSystemHealth();
      
      if (healthReport.isHealthy) {
        logger.info(
          'System recovery successful',
          operation: 'SYSTEM_RECOVERY',
          context: {'new_health_score': healthReport.overallHealthScore},
        );
      } else {
        logger.warning(
          'System recovery partially successful',
          operation: 'SYSTEM_RECOVERY',
          context: {
            'health_score': healthReport.overallHealthScore,
            'unhealthy_services': healthReport.unhealthyServices.length,
          },
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        'System recovery failed: $e',
        operation: 'SYSTEM_RECOVERY',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Shutdown the app gracefully
  static Future<void> shutdownApp() async {
    if (!_isInitialized) return;

    final logger = EnhancedLogger();
    
    try {
      logger.info('Starting app shutdown', operation: 'APP_SHUTDOWN');
      
      // Shutdown service locator
      shutdownServiceLocator();
      
      // Clear initialization flag
      _isInitialized = false;
      
      logger.info('App shutdown completed', operation: 'APP_SHUTDOWN');
    } catch (e, stackTrace) {
      logger.error(
        'App shutdown failed: $e',
        operation: 'APP_SHUTDOWN',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if the app is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Get current app health status
  static Future<AppHealthStatus> getAppHealthStatus() async {
    if (!_isInitialized) {
      return AppHealthStatus(
        isHealthy: false,
        healthScore: 0,
        message: 'App not initialized',
        timestamp: DateTime.now(),
      );
    }

    try {
      final healthReport = await EnhancedServiceLocator.instance.getSystemHealth();
      
      return AppHealthStatus(
        isHealthy: healthReport.isHealthy,
        healthScore: healthReport.overallHealthScore,
        message: healthReport.isHealthy 
            ? 'All systems operational' 
            : 'Some services are experiencing issues',
        serviceCount: healthReport.serviceResults.length,
        unhealthyServiceCount: healthReport.unhealthyServices.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return AppHealthStatus(
        isHealthy: false,
        healthScore: 0,
        message: 'Health check failed: $e',
        timestamp: DateTime.now(),
      );
    }
  }
}

/// App health status information
class AppHealthStatus {
  const AppHealthStatus({
    required this.isHealthy,
    required this.healthScore,
    required this.message,
    required this.timestamp,
    this.serviceCount = 0,
    this.unhealthyServiceCount = 0,
  });

  final bool isHealthy;
  final int healthScore;
  final String message;
  final int serviceCount;
  final int unhealthyServiceCount;
  final DateTime timestamp;

  /// Convert to map for logging/debugging
  Map<String, dynamic> toMap() {
    return {
      'is_healthy': isHealthy,
      'health_score': healthScore,
      'message': message,
      'service_count': serviceCount,
      'unhealthy_service_count': unhealthyServiceCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Example of how to use the app bootstrapper in main.dart
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize app with enhanced service locator
///   await AppBootstrapper.initializeApp();
///   
///   // Run the app
///   runApp(MyApp());
/// }
/// 
/// class MyApp extends StatefulWidget {
///   @override
///   _MyAppState createState() => _MyAppState();
/// }
/// 
/// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addObserver(this);
///   }
/// 
///   @override
///   void dispose() {
///     WidgetsBinding.instance.removeObserver(this);
///     AppBootstrapper.shutdownApp();
///     super.dispose();
///   }
/// 
///   @override
///   void didChangeAppLifecycleState(AppLifecycleState state) {
///     super.didChangeAppLifecycleState(state);
///     
///     if (state == AppLifecycleState.detached) {
///       AppBootstrapper.shutdownApp();
///     }
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       title: 'Revision App',
///       home: FutureBuilder<AppHealthStatus>(
///         future: AppBootstrapper.getAppHealthStatus(),
///         builder: (context, snapshot) {
///           if (snapshot.hasData) {
///             final status = snapshot.data!;
///             if (status.isHealthy) {
///               return HomePage();
///             } else {
///               return ServiceUnavailablePage(status: status);
///             }
///           }
///           return LoadingPage();
///         },
///       ),
///     );
///   }
/// }
/// ```
