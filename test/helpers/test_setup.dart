import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'firebase_test_helper.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}
class MockGetAuthStateChangesUseCase extends Mock implements GetAuthStateChangesUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements FirebaseFirestore {}

class TestSetup {
  static bool _isSetupComplete = false;
  
  static Future<void> setupTestEnvironment() async {
    if (_isSetupComplete) return;
    
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup Firebase for testing
    await _setupFirebaseForTesting();
    
    // Reset and setup service locator with test doubles
    await _setupTestServiceLocator();
    
    _isSetupComplete = true;
  }

  static Future<void> _setupFirebaseForTesting() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project',
        ),
      );
    } catch (e) {
      // Firebase may already be initialized
      debugPrint('Firebase already initialized or test setup: $e');
    }
  }

  static Future<void> _setupTestServiceLocator() async {
    // Reset service locator
    await getIt.reset();
    
    // Register test doubles
    getIt.registerLazySingleton<AuthRepository>(() {
      final mock = MockAuthRepository();
      // Setup default behaviors
      when(mock.getAuthStateChanges()).thenAnswer((_) => Stream.value(null));
      return mock;
    });
    
    getIt.registerLazySingleton<GetAuthStateChangesUseCase>(() {
      final mock = MockGetAuthStateChangesUseCase();
      when(mock.call()).thenAnswer((_) => Stream.value(null));
      return mock;
    });
    
    getIt.registerLazySingleton<SignOutUseCase>(() {
      final mock = MockSignOutUseCase();
      when(mock.call()).thenAnswer((_) async {});
      return mock;
    });
  }

  static Future<void> tearDownTestEnvironment() async {
    await getIt.reset();
    _isSetupComplete = false;
  }
}
