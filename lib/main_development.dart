import 'package:flutter/material.dart';
import 'package:revision/app/app.dart';
import 'package:revision/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrap(() => const App());
}
