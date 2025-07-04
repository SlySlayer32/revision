import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:revision/app/app.dart';
import 'package:revision/bootstrap.dart';
import 'package:revision/core/config/environment_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env.development");
  EnvironmentDetector.initialize(AppEnvironment.development);
  bootstrap(() => const App());
}
