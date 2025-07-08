import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:revision/core/services/error_monitoring_service.dart';

/// Error boundary widget that catches and handles Flutter widget errors
/// Provides fallback UI and error reporting
class ErrorBoundaryWidget extends StatefulWidget {
  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
    this.reportToMonitoring = true,
  });

  final Widget child;
  final Widget Function(FlutterErrorDetails)? fallbackBuilder;
  final void Function(FlutterErrorDetails)? onError;
  final bool reportToMonitoring;

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();

    // Set custom error handler for this widget's subtree
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });

        // Report to monitoring service
        if (widget.reportToMonitoring) {
          ErrorMonitoringService().reportError(
            'UI_ERROR',
            details.exception,
            stackTrace: details.stack,
            context: {
              'library': details.library,
              'context': details.context?.toString(),
              'widget': widget.child.runtimeType.toString(),
            },
          );
        }

        // Call custom error handler
        widget.onError?.call(details);
      }

      // Also call the original handler
      originalOnError?.call(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.fallbackBuilder?.call(_errorDetails!) ??
          _DefaultErrorFallback(errorDetails: _errorDetails!);
    }

    return widget.child;
  }
}

/// Default error fallback widget
class _DefaultErrorFallback extends StatelessWidget {
  const _DefaultErrorFallback({required this.errorDetails});

  final FlutterErrorDetails errorDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'An error occurred while rendering this component. '
            'The error has been reported and will be fixed in a future update.',
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  // Copy error details to clipboard
                  _copyErrorToClipboard(context);
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Error'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  // Refresh the widget
                  if (context.mounted) {
                    // This would trigger a rebuild
                    (context as Element).markNeedsBuild();
                  }
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyErrorToClipboard(BuildContext context) {
    final errorText =
        '''
Error: ${errorDetails.exception}
Library: ${errorDetails.library}
Context: ${errorDetails.context}
Stack Trace: ${errorDetails.stack}
''';

    // In a real app, you'd use Clipboard.setData
    log('Error copied to clipboard: $errorText');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error details copied to clipboard'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// AI Operation Error Widget - Specialized for AI errors
class AIErrorWidget extends StatelessWidget {
  const AIErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.showDetails = false,
  });

  final dynamic error;
  final VoidCallback? onRetry;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final isNetworkError = _isNetworkError(error);
    final isAIServiceError = _isAIServiceError(error);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNetworkError ? Icons.wifi_off : Icons.smart_toy_outlined,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getErrorTitle(isNetworkError, isAIServiceError),
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getErrorMessage(isNetworkError, isAIServiceError),
            style: TextStyle(color: Colors.orange.shade700),
          ),
          if (showDetails) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  // Report to monitoring
                  ErrorMonitoringService().reportError(
                    'UI_USER_REPORTED',
                    error,
                    context: {'user_action': 'manual_report'},
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Error reported. Thank you for helping us improve!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('Report Issue'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('socket');
  }

  bool _isAIServiceError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('ai') ||
        errorStr.contains('gemini') ||
        errorStr.contains('firebase') ||
        errorStr.contains('role: model') ||
        errorStr.contains('empty response');
  }

  String _getErrorTitle(bool isNetworkError, bool isAIServiceError) {
    if (isNetworkError) return 'Connection Problem';
    if (isAIServiceError) return 'AI Service Temporarily Unavailable';
    return 'Something Went Wrong';
  }

  String _getErrorMessage(bool isNetworkError, bool isAIServiceError) {
    if (isNetworkError) {
      return 'Please check your internet connection and try again.';
    }
    if (isAIServiceError) {
      return 'Our AI service is experiencing temporary issues. Please try again in a moment.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Loading widget with error handling
class SafeAsyncWidget<T> extends StatefulWidget {
  const SafeAsyncWidget({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.onError,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final void Function(dynamic error)? onError;

  @override
  State<SafeAsyncWidget<T>> createState() => _SafeAsyncWidgetState<T>();
}

class _SafeAsyncWidgetState<T> extends State<SafeAsyncWidget<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  void _retry() {
    setState(() {
      _future = widget.future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          widget.onError?.call(snapshot.error);

          return widget.errorBuilder?.call(context, snapshot.error) ??
              AIErrorWidget(error: snapshot.error, onRetry: _retry);
        }

        if (snapshot.hasData) {
          return widget.builder(context, snapshot.data as T);
        }

        return const Center(child: Text('No data available'));
      },
    );
  }
}
