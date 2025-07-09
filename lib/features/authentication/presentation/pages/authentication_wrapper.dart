import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
import 'package:revision/core/utils/session_manager.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';
import 'package:revision/features/dashboard/dashboard.dart';

/// A widget that listens to authentication state changes and
/// shows the appropriate screen based on the authentication status
class AuthenticationWrapper extends StatefulWidget {
  /// Creates a new [AuthenticationWrapper]
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Listen to session state changes
    SessionManager.instance.sessionStateStream.listen((sessionState) {
      switch (sessionState) {
        case SessionState.warningTimeout:
          _showSessionWarning();
          break;
        case SessionState.timedOut:
          _handleSessionTimeout();
          break;
        case SessionState.ended:
          // Session ended normally
          break;
        case SessionState.active:
          // Session is active
          break;
      }
    });
  }

  @override
  void dispose() {
    SessionManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AuthSecurityUtils.logAuthEvent('Building authentication wrapper');
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        AuthSecurityUtils.logAuthEvent(
          'Auth status changed',
          user: state.user,
          data: {'status': state.status.name},
        );

        try {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (state.status) {
              AuthenticationStatus.authenticated =>
                state.user != null
                    ? _buildAuthenticatedView(state.user!)
                    : const Center(
                        child: Text('Authentication error: User is null'),
                      ),
              AuthenticationStatus.unauthenticated => const WelcomePage(),
              AuthenticationStatus.unknown => const Center(
                child: CircularProgressIndicator(),
              ),
            },
          );
        } catch (e, stackTrace) {
          AuthSecurityUtils.logAuthError(
            'Authentication wrapper build',
            e,
            stackTrace: stackTrace,
            user: state.user,
          );

          // Return error widget with categorized error handling
          return _buildErrorWidget(context, e);
        }
      },
    );
  }

  /// Builds an error widget with proper error categorization and recovery
  Widget _buildErrorWidget(BuildContext context, Object error) {
    final errorCategory = AuthSecurityUtils.categorizeAuthError(error);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Authentication Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                errorCategory.userMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _handleRetry(context, errorCategory),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => _handleReset(context),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handles retry with appropriate delay based on error category
  void _handleRetry(BuildContext context, AuthErrorCategory errorCategory) {
    // Add delay based on error category
    Future.delayed(errorCategory.retryDelay, () {
      context.read<AuthenticationBloc>().add(
        const AuthenticationLogoutRequested(),
      );
    });
  }

  /// Handles reset by clearing auth state
  void _handleReset(BuildContext context) {
    context.read<AuthenticationBloc>().add(
      const AuthenticationLogoutRequested(),
    );
  }

  /// Builds authenticated view with session management
  Widget _buildAuthenticatedView(User user) {
    // Start session monitoring
    SessionManager.instance.startSession(user);
    
    return GestureDetector(
      onTap: () => SessionManager.instance.updateActivity(),
      onPanUpdate: (_) => SessionManager.instance.updateActivity(),
      child: const DashboardPage(),
    );
  }

  /// Shows session warning dialog
  void _showSessionWarning() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expiring'),
        content: const Text(
          'Your session will expire in 5 minutes. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SessionManager.instance.updateActivity();
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSessionTimeout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Handles session timeout
  void _handleSessionTimeout() {
    if (!mounted) return;
    
    SessionManager.instance.endSession();
    context.read<AuthenticationBloc>().add(
      const AuthenticationLogoutRequested(),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please sign in again.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
