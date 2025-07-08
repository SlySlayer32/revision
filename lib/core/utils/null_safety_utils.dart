import 'package:flutter/foundation.dart';

/// Comprehensive null safety utilities for preventing unexpected null values
/// throughout the application.
class NullSafetyUtils {
  // Private constructor to prevent instantiation
  NullSafetyUtils._();

  /// Safely gets a value with a fallback and optional debug logging
  static T safeGet<T>(
    T? value,
    T fallback, {
    String? context,
    bool logWhenNull = kDebugMode,
  }) {
    if (value != null) {
      return value;
    }

    if (logWhenNull && context != null) {
      debugPrint(
        '⚠️ Null value detected in: $context. Using fallback: $fallback',
      );
    }

    return fallback;
  }

  /// Safely gets a string with empty string fallback
  static String safeString(
    String? value, {
    String fallback = '',
    String? context,
  }) {
    return safeGet(value, fallback, context: context);
  }

  /// Safely gets an int with zero fallback
  static int safeInt(int? value, {int fallback = 0, String? context}) {
    return safeGet(value, fallback, context: context);
  }

  /// Safely gets a double with zero fallback
  static double safeDouble(
    double? value, {
    double fallback = 0.0,
    String? context,
  }) {
    return safeGet(value, fallback, context: context);
  }

  /// Safely gets a bool with false fallback
  static bool safeBool(bool? value, {bool fallback = false, String? context}) {
    return safeGet(value, fallback, context: context);
  }

  /// Safely gets a list with empty list fallback
  static List<T> safeList<T>(
    List<T>? value, {
    List<T>? fallback,
    String? context,
  }) {
    return safeGet(value, fallback ?? <T>[], context: context);
  }

  /// Safely gets a map with empty map fallback
  static Map<K, V> safeMap<K, V>(
    Map<K, V>? value, {
    Map<K, V>? fallback,
    String? context,
  }) {
    return safeGet(value, fallback ?? <K, V>{}, context: context);
  }

  /// Safely executes a function with null check
  static R? safeExecute<R>(
    R Function()? function, {
    String? context,
    bool logErrors = kDebugMode,
  }) {
    if (function == null) {
      if (logErrors && context != null) {
        debugPrint('⚠️ Null function in: $context');
      }
      return null;
    }

    try {
      return function();
    } catch (e) {
      if (logErrors) {
        debugPrint(
          '❌ Error executing function${context != null ? ' in $context' : ''}: $e',
        );
      }
      return null;
    }
  }

  /// Safely executes an async function with null check
  static Future<R?> safeExecuteAsync<R>(
    Future<R> Function()? function, {
    String? context,
    bool logErrors = kDebugMode,
  }) async {
    if (function == null) {
      if (logErrors && context != null) {
        debugPrint('⚠️ Null async function in: $context');
      }
      return null;
    }

    try {
      return await function();
    } catch (e) {
      if (logErrors) {
        debugPrint(
          '❌ Error executing async function${context != null ? ' in $context' : ''}: $e',
        );
      }
      return null;
    }
  }

  /// Validates that a required value is not null
  static T requireNonNull<T>(
    T? value, {
    required String message,
    String? context,
  }) {
    if (value == null) {
      final errorMessage = '${context != null ? '[$context] ' : ''}$message';
      debugPrint('❌ Required value is null: $errorMessage');
      throw ArgumentError(errorMessage);
    }
    return value;
  }

  /// Checks if a string is null or empty
  static bool isStringNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }

  /// Checks if a string is null, empty, or whitespace
  static bool isNullOrWhitespace(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Checks if a collection is null or empty
  static bool isCollectionNullOrEmpty<T>(Iterable<T>? collection) {
    return collection == null || collection.isEmpty;
  }

  /// Gets the first non-null value from a list of nullable values
  static T? firstNonNull<T>(List<T?> values) {
    for (final value in values) {
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  /// Safely converts a value to string with null handling
  static String safeToString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  /// Safely parses a string to int with fallback
  static int parseInt(String? value, {int fallback = 0, String? context}) {
    if (isStringNullOrEmpty(value)) {
      if (kDebugMode && context != null) {
        debugPrint('⚠️ Null/empty string in parseInt: $context');
      }
      return fallback;
    }

    try {
      return int.parse(value!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Error parsing int${context != null ? ' in $context' : ''}: $e',
        );
      }
      return fallback;
    }
  }

  /// Safely parses a string to double with fallback
  static double parseDouble(
    String? value, {
    double fallback = 0.0,
    String? context,
  }) {
    if (isStringNullOrEmpty(value)) {
      if (kDebugMode && context != null) {
        debugPrint('⚠️ Null/empty string in parseDouble: $context');
      }
      return fallback;
    }

    try {
      return double.parse(value!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Error parsing double${context != null ? ' in $context' : ''}: $e',
        );
      }
      return fallback;
    }
  }

  /// Safely formats a nullable value for display
  static String formatForDisplay<T>(
    T? value, {
    String nullDisplay = 'N/A',
    String Function(T)? formatter,
  }) {
    if (value == null) return nullDisplay;
    return formatter?.call(value) ?? value.toString();
  }

  /// Creates a safe callback that handles null function references
  static VoidCallback? safeCallback(VoidCallback? callback, {String? context}) {
    if (callback == null) return null;

    return () {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '❌ Error in callback${context != null ? ' ($context)' : ''}: $e',
          );
        }
      }
    };
  }

  /// Creates a safe value notifier callback
  static ValueChanged<T>? safeValueCallback<T>(
    ValueChanged<T>? callback, {
    String? context,
  }) {
    if (callback == null) return null;

    return (T value) {
      try {
        callback(value);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '❌ Error in value callback${context != null ? ' ($context)' : ''}: $e',
          );
        }
      }
    };
  }
}
