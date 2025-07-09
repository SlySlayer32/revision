import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

/// Service for persisting navigation state across app restarts
class NavigationStatePersistence {
  static final NavigationStatePersistence _instance = NavigationStatePersistence._internal();
  factory NavigationStatePersistence() => _instance;
  NavigationStatePersistence._internal();

  final EnhancedLogger _logger = EnhancedLogger();
  static const String _stateFileName = 'navigation_state.json';
  static const Duration _maxStateAge = Duration(hours: 24);

  /// Saves the current navigation state
  Future<void> saveNavigationState(NavigationState state) async {
    try {
      final file = await _getStateFile();
      final stateData = {
        'current_route': state.currentRoute,
        'route_stack': state.routeStack,
        'arguments': state.arguments,
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1,
      };

      await file.writeAsString(jsonEncode(stateData));
      
      _logger.debug(
        'Navigation state saved',
        operation: 'NAVIGATION_PERSISTENCE',
        context: {
          'current_route': state.currentRoute,
          'stack_depth': state.routeStack.length,
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to save navigation state: $e',
        operation: 'NAVIGATION_PERSISTENCE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Loads the persisted navigation state
  Future<NavigationState?> loadNavigationState() async {
    try {
      final file = await _getStateFile();
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final stateData = jsonDecode(content) as Map<String, dynamic>;

      // Check if state is not too old
      final timestamp = DateTime.parse(stateData['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > _maxStateAge) {
        _logger.debug(
          'Navigation state too old, ignoring',
          operation: 'NAVIGATION_PERSISTENCE',
          context: {'age_hours': DateTime.now().difference(timestamp).inHours},
        );
        await clearNavigationState();
        return null;
      }

      // Validate state structure
      if (!_isValidStateStructure(stateData)) {
        _logger.warning(
          'Invalid navigation state structure, ignoring',
          operation: 'NAVIGATION_PERSISTENCE',
        );
        await clearNavigationState();
        return null;
      }

      final state = NavigationState(
        currentRoute: stateData['current_route'] as String,
        routeStack: List<String>.from(stateData['route_stack'] as List),
        arguments: stateData['arguments'] as Map<String, dynamic>?,
      );

      _logger.debug(
        'Navigation state loaded',
        operation: 'NAVIGATION_PERSISTENCE',
        context: {
          'current_route': state.currentRoute,
          'stack_depth': state.routeStack.length,
        },
      );

      return state;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load navigation state: $e',
        operation: 'NAVIGATION_PERSISTENCE',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clears the persisted navigation state
  Future<void> clearNavigationState() async {
    try {
      final file = await _getStateFile();
      if (await file.exists()) {
        await file.delete();
        _logger.debug(
          'Navigation state cleared',
          operation: 'NAVIGATION_PERSISTENCE',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to clear navigation state: $e',
        operation: 'NAVIGATION_PERSISTENCE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Updates the current route in the persisted state
  Future<void> updateCurrentRoute(String route, {Map<String, dynamic>? arguments}) async {
    try {
      final currentState = await loadNavigationState();
      if (currentState != null) {
        final updatedState = NavigationState(
          currentRoute: route,
          routeStack: [...currentState.routeStack, route],
          arguments: arguments,
        );
        await saveNavigationState(updatedState);
      } else {
        // Create new state if none exists
        final newState = NavigationState(
          currentRoute: route,
          routeStack: [route],
          arguments: arguments,
        );
        await saveNavigationState(newState);
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to update current route: $e',
        operation: 'NAVIGATION_PERSISTENCE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Adds a route to the navigation stack
  Future<void> pushRoute(String route, {Map<String, dynamic>? arguments}) async {
    try {
      final currentState = await loadNavigationState();
      final routeStack = currentState?.routeStack ?? [];
      
      final updatedState = NavigationState(
        currentRoute: route,
        routeStack: [...routeStack, route],
        arguments: arguments,
      );
      
      await saveNavigationState(updatedState);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to push route: $e',
        operation: 'NAVIGATION_PERSISTENCE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Removes the top route from the navigation stack
  Future<void> popRoute() async {
    try {
      final currentState = await loadNavigationState();
      if (currentState != null && currentState.routeStack.length > 1) {
        final newStack = List<String>.from(currentState.routeStack);
        newStack.removeLast();
        
        final updatedState = NavigationState(
          currentRoute: newStack.last,
          routeStack: newStack,
          arguments: null, // Clear arguments on pop
        );
        
        await saveNavigationState(updatedState);
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to pop route: $e',
        operation: 'NAVIGATION_PERSISTENCE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gets the state file
  Future<File> _getStateFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_stateFileName');
  }

  /// Validates the structure of loaded state data
  bool _isValidStateStructure(Map<String, dynamic> stateData) {
    return stateData.containsKey('current_route') &&
        stateData.containsKey('route_stack') &&
        stateData.containsKey('timestamp') &&
        stateData['current_route'] is String &&
        stateData['route_stack'] is List &&
        stateData['timestamp'] is String;
  }

  /// Gets navigation state statistics for debugging
  Future<Map<String, dynamic>> getStateStatistics() async {
    try {
      final file = await _getStateFile();
      if (!await file.exists()) {
        return {'exists': false};
      }

      final stat = await file.stat();
      final content = await file.readAsString();
      final stateData = jsonDecode(content) as Map<String, dynamic>;

      return {
        'exists': true,
        'size_bytes': stat.size,
        'last_modified': stat.modified.toIso8601String(),
        'state_timestamp': stateData['timestamp'],
        'current_route': stateData['current_route'],
        'stack_depth': (stateData['route_stack'] as List).length,
        'has_arguments': stateData.containsKey('arguments') && stateData['arguments'] != null,
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }
}

/// Represents the navigation state
class NavigationState {
  const NavigationState({
    required this.currentRoute,
    required this.routeStack,
    this.arguments,
  });

  final String currentRoute;
  final List<String> routeStack;
  final Map<String, dynamic>? arguments;

  @override
  String toString() {
    return 'NavigationState(currentRoute: $currentRoute, stackDepth: ${routeStack.length})';
  }
}