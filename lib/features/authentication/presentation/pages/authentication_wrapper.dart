import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';

/// A widget that listens to authentication state changes and
/// shows the appropriate screen based on the authentication status
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthenticationStatus.authenticated:
            // Placeholder for the app's main screen after authentication
            return const Scaffold(
              body: Center(
                child:
                    Text('Authenticated! Replace with your main app screen.'),
              ),
            );
          case AuthenticationStatus.unauthenticated:
          case AuthenticationStatus.unknown:
            return const WelcomePage();
        }
      },
    );
  }
}
