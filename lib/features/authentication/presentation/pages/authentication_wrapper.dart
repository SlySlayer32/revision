import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';

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
        debugPrint('AuthenticationWrapper: Auth status = \\${state.status}');
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (state.status) {
            AuthenticationStatus.authenticated => _HomePage(),
            AuthenticationStatus.unauthenticated => const WelcomePage(),
            AuthenticationStatus.unknown => const Center(
                child: CircularProgressIndicator(),
              ),
          },
        );
      },
    );
  }
}

/// Temporary home page placeholder until dashboard is recreated
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision - AI Photo Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthenticationBloc>().add(
                    const AuthenticationLogoutRequested(),
                  );
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to Revision',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'AI-Powered Photo Editor',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            Text(
              'Dashboard coming soon...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
