import 'package:flutter/material.dart';
import 'package:revision/app/app.dart';
import 'package:revision/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('main_development.dart: Starting bootstrap...');
  await bootstrap(() {
    debugPrint('main_development.dart: Building App widget...');
    return const App();
  });
  debugPrint('main_development.dart: App launched!');
}
