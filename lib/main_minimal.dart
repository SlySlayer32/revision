import 'package:flutter/material.dart';
import 'package:revision/app/app.dart';

/// Minimal main entry point for MVP testing
/// Bypasses complex Firebase initialization to get the app running first
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🚀 Starting minimal MVP version...');
  
  // For MVP: Skip complex initialization and just run the app
  runApp(const App());
  
  debugPrint('✅ MVP app launched successfully!');
}
