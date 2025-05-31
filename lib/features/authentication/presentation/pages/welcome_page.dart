import 'package:flutter/material.dart';
import 'package:revision/features/authentication/presentation/pages/login_page.dart';
import 'package:revision/features/authentication/presentation/pages/signup_page.dart';

/// The initial page shown to unauthenticated users
class WelcomePage extends StatelessWidget {
  /// Creates a new [WelcomePage]
  const WelcomePage({super.key});

  /// Creates a [Route] for this page
  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const WelcomePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Welcome to Revision',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your personal guide to academic success',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(LoginPage.route());
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Log In'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(SignUpPage.route());
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
