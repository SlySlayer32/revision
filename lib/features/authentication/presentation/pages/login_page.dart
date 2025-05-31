import 'package:flutter/material.dart';
import 'package:revision/features/authentication/presentation/widgets/login_form.dart';

/// Page that displays the login UI
class LoginPage extends StatelessWidget {
  /// Creates a new [LoginPage]
  const LoginPage({super.key});

  /// Creates a [Route] for this page
  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const LoginPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              const LoginForm(),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO(developer): Implement forgot password
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
