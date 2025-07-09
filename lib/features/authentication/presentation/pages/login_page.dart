import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/navigation/route_factory.dart' as app_routes;
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/widgets/login_form.dart';

/// Page that displays the login UI
class LoginPage extends StatelessWidget {
  /// Creates a new [LoginPage]
  const LoginPage({super.key});

  /// Creates a [Route] for this page
  static Route<void> route() {
    try {
      return app_routes.RouteFactory.createRoute<void>(
        builder: (_) => const LoginPage(),
        routeName: RouteNames.login,
      );
    } catch (e) {
      // Fallback to basic MaterialPageRoute if RouteFactory fails
      return MaterialPageRoute<void>(
        builder: (_) => const LoginPage(),
        settings: const RouteSettings(name: RouteNames.login),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LoginBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Log In')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                const LoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
