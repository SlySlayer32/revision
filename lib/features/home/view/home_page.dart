import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/debug/firebase_setup_checker.dart';
import 'package:revision/debug/firebase_ai_test_page.dart';
import 'package:revision/debug/firebase_ai_config_checker.dart';

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
                    const AuthenticationLogoutRequested(),
                  );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Revision!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Debug buttons
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔧 Debug Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirebaseSetupChecker(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Check Firebase AI Setup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirebaseAIConfigChecker(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Fix API Configuration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirebaseAITestPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.psychology),
                    label: const Text('Test Firebase AI API'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
