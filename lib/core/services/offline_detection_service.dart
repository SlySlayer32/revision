import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:revision/core/services/logging_service.dart';

/// Offline detection service for monitoring network connectivity
class OfflineDetectionService {
  const OfflineDetectionService._();

  static const OfflineDetectionService _instance = OfflineDetectionService._();
  static OfflineDetectionService get instance => _instance;

  static bool _isOnline = true;
  static bool _isInitialized = false;
  static Timer? _connectivityTimer;
  static final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  /// Initialize the offline detection service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kDebugMode) {
      LoggingService.instance.debug('OfflineDetection: Initializing...');
    }
    
    try {
      // Check initial connectivity
      await _checkConnectivity();
      
      // Start periodic connectivity checks
      _startPeriodicChecks();
      
      _isInitialized = true;
      LoggingService.instance.info('OfflineDetection: Initialized successfully');
    } catch (e) {
      LoggingService.instance.error(
        'OfflineDetection: Failed to initialize', 
        error: e,
      );
    }
  }

  /// Start periodic connectivity checks
  static void _startPeriodicChecks() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5), 
      (_) => _checkConnectivity(),
    );
  }

  /// Check network connectivity
  static Future<void> _checkConnectivity() async {
    try {
      bool isConnected = false;
      
      if (kIsWeb) {
        // For web, we'll assume online unless proven otherwise
        isConnected = true;
      } else {
        // For mobile/desktop, try to connect to a reliable host
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
      
      if (isConnected != _isOnline) {
        _isOnline = isConnected;
        _connectivityController.add(_isOnline);
        
        LoggingService.instance.info(
          'OfflineDetection: Connectivity changed - ${_isOnline ? 'Online' : 'Offline'}',
        );
      }
    } catch (e) {
      if (_isOnline) {
        _isOnline = false;
        _connectivityController.add(_isOnline);
        LoggingService.instance.warning(
          'OfflineDetection: Connection lost',
          error: e,
        );
      }
    }
  }

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Get current offline status
  bool get isOffline => !_isOnline;

  /// Get connectivity status stream
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Force connectivity check
  Future<void> forceCheck() async {
    await _checkConnectivity();
  }

  /// Dispose of resources
  static void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
    _isInitialized = false;
  }

  /// Get connectivity info for analytics
  Map<String, dynamic> getConnectivityInfo() {
    return {
      'isOnline': _isOnline,
      'isOffline': !_isOnline,
      'lastChecked': DateTime.now().toIso8601String(),
    };
  }
}