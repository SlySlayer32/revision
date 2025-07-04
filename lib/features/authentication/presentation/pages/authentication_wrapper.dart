import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';
import 'package:revision/features/dashboard/dashboard.dart';

/// A widget that listens to authentication state changes and
/// shows the appropriate screen based on the authentication status
class AuthenticationWrapper extends StatelessWidget {
  /// Creates a new [AuthenticationWrapper]
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthenticationWrapper: Building, waiting for auth state...');
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        debugPrint('AuthenticationWrapper: Auth status = ${state.status}');
        debugPrint('AuthenticationWrapper: User = ${state.user?.email ?? "null"}');
        
        try {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (state.status) {
              AuthenticationStatus.authenticated => state.user != null 
                ? const DashboardPage()
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
          debugPrint('❌ Error in AuthenticationWrapper: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          
          // Return error widget instead of crashing
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Authentication Error'),
                  const SizedBox(height: 8),
                  Text(e.toString()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger state refresh
                      context.read<AuthenticationBloc>().add(
                        const AuthenticationLogoutRequested(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
