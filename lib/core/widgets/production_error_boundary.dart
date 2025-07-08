import 'package:flutter/material.dart';
import 'package:revision/core/error/exceptions.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

/// Production-grade error boundary widget with comprehensive error handling
class ProductionErrorBoundary extends StatefulWidget {
  const ProductionErrorBoundary({
    required this.child,
    this.onError,
    this.errorWidgetBuilder,
    this.shouldReportError,
    super.key,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error, StackTrace stackTrace)?
  errorWidgetBuilder;
  final bool Function(Object error)? shouldReportError;

  @override
  State<ProductionErrorBoundary> createState() =>
      _ProductionErrorBoundaryState();
}

class _ProductionErrorBoundaryState extends State<ProductionErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();

    // Set up global error handler
    FlutterError.onError = (details) {
      _handleError(details.exception, details.stack ?? StackTrace.current);
    };
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    // Report error if should report
    final shouldReport = widget.shouldReportError?.call(error) ?? true;
    if (shouldReport) {
      _reportError(error, stackTrace);
    }

    // Call custom error handler
    widget.onError?.call(error, stackTrace);
  }

  void _reportError(Object error, StackTrace stackTrace) {
    logger.error(
      'UI Error Boundary Caught: ${error.toString()}',
      operation: 'ERROR_BOUNDARY',
      error: error,
      stackTrace: stackTrace,
    );

    // You could integrate with crash reporting services here
    // Example: Crashlytics, Sentry, etc.
  }

  bool _isUserRecoverable(Object error) {
    // Determine if user can potentially recover from this error
    if (error is ValidationException) return true;
    if (error is NetworkException) return true;
    if (error is CircuitBreakerOpenException) return true;
    return false;
  }

  String _categorizeError(Object error) {
    if (error is NetworkException) return 'network';
    if (error is AuthenticationException) return 'authentication';
    if (error is AIServiceException) return 'ai_service';
    if (error is ValidationException) return 'validation';
    if (error is PermissionException) return 'permission';
    if (error is CircuitBreakerOpenException) return 'circuit_breaker';
    return 'unknown';
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidgetBuilder != null &&
        _error != null &&
        _stackTrace != null) {
      return widget.errorWidgetBuilder!(_error!, _stackTrace!);
    }

    return _buildDefaultErrorWidget();
  }

  Widget _buildDefaultErrorWidget() {
    final isRecoverable = _error != null && _isUserRecoverable(_error!);
    final errorCategory = _error != null
        ? _categorizeError(_error!)
        : 'unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Something went wrong'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(errorCategory),
              size: 64,
              color: Colors.red[700],
            ),
            const SizedBox(height: 24),
            Text(
              _getErrorTitle(errorCategory),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorMessage(errorCategory),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isRecoverable) ...[
              ElevatedButton(
                onPressed: _resetError,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
            ],
            TextButton(
              onPressed: () {
                // Navigate to home or safe screen
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text('Go to Home'),
            ),
            if (!isRecoverable) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Error ID: ${DateTime.now().millisecondsSinceEpoch}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon(String category) {
    switch (category) {
      case 'network':
        return Icons.wifi_off;
      case 'authentication':
        return Icons.lock;
      case 'ai_service':
        return Icons.smart_toy;
      case 'validation':
        return Icons.warning;
      case 'permission':
        return Icons.security;
      case 'circuit_breaker':
        return Icons.electrical_services;
      default:
        return Icons.error;
    }
  }

  String _getErrorTitle(String category) {
    switch (category) {
      case 'network':
        return 'Connection Problem';
      case 'authentication':
        return 'Authentication Required';
      case 'ai_service':
        return 'AI Service Unavailable';
      case 'validation':
        return 'Invalid Input';
      case 'permission':
        return 'Permission Required';
      case 'circuit_breaker':
        return 'Service Temporarily Unavailable';
      default:
        return 'Unexpected Error';
    }
  }

  String _getErrorMessage(String category) {
    switch (category) {
      case 'network':
        return 'Please check your internet connection and try again.';
      case 'authentication':
        return 'Please sign in to continue using the app.';
      case 'ai_service':
        return 'Our AI service is temporarily unavailable. Please try again in a few moments.';
      case 'validation':
        return 'Please check your input and try again.';
      case 'permission':
        return 'This feature requires additional permissions to work properly.';
      case 'circuit_breaker':
        return 'The service is temporarily overloaded. Please try again in a few minutes.';
      default:
        return 'An unexpected error occurred. Our team has been notified and is working on a fix.';
    }
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    return widget.child;
  }
}

/// Convenient wrapper for wrapping routes with error boundary
class ErrorBoundaryWrapper extends StatelessWidget {
  const ErrorBoundaryWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProductionErrorBoundary(
      onError: (error, stackTrace) {
        // Global error reporting logic
        logger.error(
          'Global Error Handler: $error',
          error: error,
          stackTrace: stackTrace,
        );
      },
      shouldReportError: (error) {
        // Don't report certain types of errors to reduce noise
        if (error is ValidationException) return false;
        return true;
      },
      child: child,
    );
  }
}
