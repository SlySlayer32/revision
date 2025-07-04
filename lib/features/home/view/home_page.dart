import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/navigation/route_factory.dart' as app_routes;
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
// import 'package:revision/debug/firebase_setup_checker.dart'; // Disabled
// import 'package:revision/debug/firebase_ai_test_page.dart'; // Disabled
// import 'package:revision/debug/firebase_ai_config_checker.dart'; // Disabled

/// The main page shown to authenticated users
class HomePage extends StatelessWidget {
  /// Creates a new [HomePage]
  const HomePage({super.key});

  /// Creates a [Route] for this page
  static Route<void> route() {
    return app_routes.RouteFactory.createRoute<void>(
      builder: (_) => const HomePage(),
      routeName: RouteNames.home,
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
                  // Debug buttons temporarily disabled
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI Service updated to use REST API\nDebug tools temporarily disabled during migration',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Test REST API integration
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'REST API integration ready! Add your GEMINI_API_KEY to .env file'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.psychology),
                    label: const Text('Test Gemini REST API'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
