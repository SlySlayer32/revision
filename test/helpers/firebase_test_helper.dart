// test/helpers/firebase_test_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/firebase_options.dart';

class MockFirebaseApp extends Mock implements FirebaseApp {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// Cannot implement final class GenerativeModel. Mocking behavior without implementing.
class MockGenerativeModel extends Mock {}

// Cannot implement final class GenerateContentResponse. Mocking behavior without implementing.
class MockGenerateContentResponse extends Mock {}

class FirebaseTestHelper {
  static Future<void> setupFirebaseForTesting() async {
    // Ensure binding is initialized for tests
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase may already be initialized in some test runners
    }
  }
}
