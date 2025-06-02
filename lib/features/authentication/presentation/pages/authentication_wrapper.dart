import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';
import 'package:revision/features/dashboard/view/dashboard_page.dart';

/// A widget that listens to authentication state changes and
/// shows the appropriate screen based on the authentication status
class AuthenticationWrapper extends StatelessWidget {
  /// Creates a new [AuthenticationWrapper]
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (state.status) {
            AuthenticationStatus.authenticated => const DashboardPage(),
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
