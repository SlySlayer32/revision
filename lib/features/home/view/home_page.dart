import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';

/// The main page shown to authenticated users
class HomePage extends StatelessWidget {
  /// Creates a new [HomePage]
  const HomePage({super.key});

  /// Creates a [Route] for this page
  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const HomePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthenticationBloc>().add(
                    AuthenticationLogoutRequested(),
                  );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to Revision!'),
      ),
    );
  }
}
