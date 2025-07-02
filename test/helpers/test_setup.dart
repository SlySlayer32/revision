import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/di/service_locator.dart';
import 'firebase_test_helper.dart';

Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await FirebaseTestHelper.setupFirebaseForTesting();
  setupServiceLocator();
  await getIt.allReady();
}

Future<void> tearDownTestEnvironment() async {
  await getIt.reset();
}
