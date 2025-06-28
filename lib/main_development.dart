import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:revision/app/app.dart';
import 'package:revision/bootstrap.dart';

void main() {
  if (kDebugMode) {
    print('main_development.dart: Starting bootstrap...');
  }
  bootstrap(() {
    if (kDebugMode) {
      print('main_development.dart: Building App widget...');
    }
    return const App();
  });
  if (kDebugMode) {
    print('main_development.dart: App launched!');
  }
}
