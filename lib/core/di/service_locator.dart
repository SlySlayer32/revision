import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Repositories
  getIt.registerLazySingleton<AuthenticationRepository>(
    () => FirebaseAuthenticationRepository(
      firebaseAuth: FirebaseAuth.instance,
    ),
  );

  // Add more services and repositories here as needed
}
