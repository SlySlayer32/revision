import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/pages/authentication_wrapper.dart';
import 'package:revision/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('App: Building MaterialApp');
    
    // Error handling wrapper for hot reload safety
    try {
      return RepositoryProvider<AuthRepository>(
        create: (context) {
          try {
            return getIt<AuthRepository>();
          } catch (e) {
            debugPrint('App: Error getting AuthRepository: $e');
            rethrow;
          }
        },
        child: BlocProvider(
          create: (context) {
            try {
              return AuthenticationBloc(
                getAuthStateChanges: getIt<GetAuthStateChangesUseCase>(),
                signOut: getIt<SignOutUseCase>(),
              );
            } catch (e) {
              debugPrint('App: Error creating AuthenticationBloc: $e');
              rethrow;
            }
          },
          child: MaterialApp(
            title: 'Revision',
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF13B9FF)),
              appBarTheme: AppBarTheme(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthenticationWrapper(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('App: Critical error in build: $e');
      debugPrint('App: Stack trace: $stackTrace');
      
      // Return error widget instead of crashing
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App initialization failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Force restart
                    debugPrint('App: User requested restart');
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
