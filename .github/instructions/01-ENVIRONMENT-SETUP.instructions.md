---
applyTo: 'environment'
---

# 🛠️ Development Environment Setup - Complete Developer Guide

## 📋 Prerequisites & System Requirements

### Operating System Support
- **Windows**: Windows 10 (64-bit) or later
- **macOS**: macOS 10.14 (Mojave) or later
- **Linux**: Ubuntu 18.04+ or equivalent

### Hardware Requirements
- **RAM**: Minimum 8GB, recommended 16GB+
- **Storage**: 50GB+ free space for tools and projects
- **CPU**: Multi-core processor (4+ cores recommended)
- **Network**: Stable internet connection for downloads and API calls

## 🔧 Core Development Tools Installation

### 1. Flutter SDK Setup (MANDATORY FIRST STEP)

#### Download and Install Flutter
```bash
# Windows (using PowerShell)
git clone https://github.com/flutter/flutter.git -b stable
# Add to PATH: C:\path\to\flutter\bin

# macOS/Linux
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
```

#### Environment Variables
```bash
# Add to your shell profile (.bashrc, .zshrc, etc.)
export FLUTTER_ROOT=/path/to/flutter
export PATH=$PATH:$FLUTTER_ROOT/bin
export PATH=$PATH:$FLUTTER_ROOT/bin/cache/dart-sdk/bin
```

#### Verify Installation
```bash
flutter doctor -v
# Must show no critical issues before proceeding
```

### 2. Development IDEs & Editors

#### Visual Studio Code (Recommended)
```bash
# Install VS Code extensions
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
code --install-extension ms-vscode.vscode-json
code --install-extension bradlc.vscode-tailwindcss
```

#### Android Studio (Alternative)
- Install Android Studio with Flutter and Dart plugins
- Configure Android SDK and emulators
- Set up device debugging

### 3. Platform-Specific Setup

#### Android Development
```bash
# Install Android Studio
# Configure Android SDK (API level 21+)
# Set ANDROID_HOME environment variable
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

#### iOS Development (macOS only)
```bash
# Install Xcode from App Store
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Install CocoaPods
sudo gem install cocoapods
```

#### Web Development
```bash
# Enable Flutter web
flutter config --enable-web
```

### 4. Firebase Tools Installation

#### Firebase CLI
```bash
# Install Node.js first (v16+)
npm install -g firebase-tools

# Verify installation
firebase --version

# Login to Firebase
firebase login
```

#### FlutterFire CLI
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Add to PATH if not already
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### 5. Version Control Setup

#### Git Configuration
```bash
# Configure Git (use your actual details)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set up SSH keys for GitHub
ssh-keygen -t ed25519 -C "your.email@example.com"
```

#### Git Hooks Setup
```bash
# Navigate to project root
cd your-project

# Install git hooks for code quality
echo '#!/bin/sh
flutter analyze
flutter test
' > .git/hooks/pre-commit

chmod +x .git/hooks/pre-commit
```

### 6. Additional Development Tools

#### Very Good CLI (VGV Architecture)
```bash
# Install Very Good CLI
dart pub global activate very_good_cli

# Verify installation
very_good --version
```

#### Code Quality Tools
```bash
# Install dart format
dart pub global activate dart_style

# Install import sorter
dart pub global activate import_sorter
```

## 🏗️ Project Initialization Process

### 1. Create New Flutter Project (VGV Architecture)

```bash
# Create project using Very Good CLI
very_good create revision \
  --desc "AI-powered photo editor with object removal capabilities" \
  --org "com.example" \
  --android-package "com.example.revision" \
  --ios-bundle-id "com.example.revision"

# Navigate to project
cd revision
```

### 2. Configure Project Structure

#### Update pubspec.yaml
```yaml
name: revision
description: AI-powered photo editor with object removal capabilities
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core Services
  firebase_core: ^3.7.1
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.1
  firebase_storage: ^12.3.7
  firebase_analytics: ^11.3.7
  cloud_functions: ^5.1.1
  firebase_app_check: ^0.3.1+3
  
  # AI & Machine Learning
  google_generative_ai: ^0.4.6
  
  # State Management & Architecture
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  dartz: ^0.10.1
  get_it: ^7.7.0
  injectable: ^2.4.4
  
  # Image Processing
  image_picker: ^1.1.2
  image: ^4.2.0
  image_gallery_saver: ^2.0.3
  flutter_painting: ^0.0.2
  
  # UI & User Experience
  flutter_svg: ^2.0.10+1
  lottie: ^3.1.2
  cached_network_image: ^3.4.1
  
  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0
  path_provider: ^2.1.4
  permission_handler: ^11.3.1
  share_plus: ^10.0.2
  url_launcher: ^6.3.0
  
  # Development
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  
  # Testing
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  fake_async: ^1.3.1
  
  # Code Quality
  very_good_analysis: ^5.1.0
  build_runner: ^2.4.12
  injectable_generator: ^2.6.2
  
  # Code Generation
  freezed: ^2.5.7
  json_annotation: ^4.9.0
  json_serializable: ^6.8.0

flutter:
  uses-material-design: true
  generate: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### 3. Firebase Project Setup

#### Create Firebase Projects
1. **Development Environment**
   ```bash
   # Create dev project in Firebase Console
   # Project ID: aura-dev-[random-string]
   ```

2. **Staging Environment**
   ```bash
   # Create staging project in Firebase Console  
   # Project ID: aura-staging-[random-string]
   ```

3. **Production Environment**
   ```bash
   # Create production project in Firebase Console
   # Project ID: aura-prod-[random-string]
   ```

#### Configure Flutter for Firebase
```bash
# Configure for development
flutterfire configure \
  --project=aura-dev-xxxxx \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=com.example.aura.dev \
  --android-package-name=com.example.aura.dev

# Configure for staging
flutterfire configure \
  --project=aura-staging-xxxxx \
  --out=lib/firebase_options_staging.dart \
  --ios-bundle-id=com.example.aura.staging \
  --android-package-name=com.example.aura.staging

# Configure for production
flutterfire configure \
  --project=aura-prod-xxxxx \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.example.aura \
  --android-package-name=com.example.aura
```

### 4. Firebase Services Configuration

#### Enable Authentication
```bash
# In Firebase Console for each project:
# 1. Go to Authentication > Sign-in method
# 2. Enable "Email/Password"
# 3. Enable "Google" (configure OAuth consent screen)
# 4. Add authorized domains for web
```

#### Setup Firestore Database
```bash
# In Firebase Console:
# 1. Go to Firestore Database
# 2. Create database in production mode
# 3. Start with default security rules (will update later)
```

#### Configure Firebase Storage
```bash
# In Firebase Console:
# 1. Go to Storage
# 2. Get started with default bucket
# 3. Set up security rules (will update later)
```

#### Enable Analytics
```bash
# In Firebase Console:
# 1. Go to Analytics
# 2. Enable Google Analytics
# 3. Link to Google Analytics account
```

### 5. Development Environment Configuration

#### Environment Files Setup
```bash
# Create environment configuration files
mkdir -p lib/core/config

# Create environment enum
cat > lib/core/config/environment.dart << EOF
enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  static const Environment environment = Environment.values.firstWhere(
    (env) => env.name == String.fromEnvironment('ENVIRONMENT', defaultValue: 'development'),
  );
  
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  
  static bool get isDevelopment => environment == Environment.development;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProduction => environment == Environment.production;
}
EOF
```

#### Bootstrap Configuration
```dart
// lib/bootstrap.dart
import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'app/app_bloc_observer.dart';
import 'core/config/environment.dart';
import 'core/di/injection.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_staging.dart' as staging;
import 'firebase_options_prod.dart' as prod;

Future<void> bootstrap() async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize Firebase
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      
      // Configure Crashlytics
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      }
      
      // Initialize dependency injection
      await configureDependencies();
      
      // Set up BLoC observer
      Bloc.observer = const AppBlocObserver();
      
      runApp(const App());
    },
    (error, stackTrace) => log(error.toString(), stackTrace: stackTrace),
  );
}

FirebaseOptions _getFirebaseOptions() {
  switch (EnvConfig.environment) {
    case Environment.development:
      return dev.DefaultFirebaseOptions.currentPlatform;
    case Environment.staging:
      return staging.DefaultFirebaseOptions.currentPlatform;
    case Environment.production:
      return prod.DefaultFirebaseOptions.currentPlatform;
  }
}
```

### 6. Development Scripts Setup

#### Create Scripts Directory
```bash
mkdir -p scripts

# Development script
cat > scripts/dev.sh << EOF
#!/bin/bash
flutter run \\
  --dart-define=ENVIRONMENT=development \\
  --dart-define=GEMINI_API_KEY=\${GEMINI_API_KEY_DEV} \\
  --target lib/main_development.dart
EOF

# Staging script
cat > scripts/staging.sh << EOF
#!/bin/bash
flutter run \\
  --dart-define=ENVIRONMENT=staging \\
  --dart-define=GEMINI_API_KEY=\${GEMINI_API_KEY_STAGING} \\
  --target lib/main_staging.dart \\
  --release
EOF

# Production script
cat > scripts/prod.sh << EOF
#!/bin/bash
flutter run \\
  --dart-define=ENVIRONMENT=production \\
  --dart-define=GEMINI_API_KEY=\${GEMINI_API_KEY_PROD} \\
  --target lib/main_production.dart \\
  --release
EOF

chmod +x scripts/*.sh
```

### 7. Firebase Emulator Setup (Development)

#### Initialize Firebase Emulators
```bash
# Initialize emulators
firebase init emulators

# Select:
# - Authentication Emulator (port 9099)
# - Firestore Emulator (port 8080)
# - Storage Emulator (port 9199)
# - Functions Emulator (port 5001)
```

#### Emulator Configuration (firebase.json)
```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "functions": {
      "port": 5001
    },
    "ui": {
      "enabled": true,
      "port": 4000
    },
    "singleProjectMode": true
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

#### Emulator Integration in Bootstrap
```dart
// Add to bootstrap.dart
Future<void> _connectToEmulators() async {
  if (kDebugMode && EnvConfig.isDevelopment) {
    const host = '127.0.0.1';
    
    // Connect to emulators
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    
    log('🔥 Connected to Firebase Emulators');
  }
}
```

### 8. Code Quality Configuration

#### Analysis Options (analysis_options.yaml)
```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/firebase_options*.dart"
  
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    # Additional rules for production code
    avoid_dynamic_calls: true
    avoid_slow_async_io: true
    cancel_subscriptions: true
    close_sinks: true
    comment_references: true
    literal_only_boolean_expressions: true
    no_adjacent_strings_in_list: true
    prefer_single_quotes: true
    sort_constructors_first: true
    sort_unnamed_constructors_first: true
    unawaited_futures: true
    unnecessary_statements: true
```

### 9. VS Code Configuration

#### .vscode/settings.json
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 80,
  "dart.insertArgumentPlaceholders": false,
  "dart.updateImportsOnRename": true,
  "dart.completeFunctionCalls": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  },
  "files.associations": {
    "*.dart": "dart"
  },
  "files.exclude": {
    "**/.dart_tool": true,
    "**/.packages": true,
    "**/build/": true
  }
}
```

#### .vscode/launch.json
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Development",
      "type": "dart",
      "request": "launch",
      "program": "lib/main_development.dart",
      "args": [
        "--dart-define=ENVIRONMENT=development",
        "--dart-define=GEMINI_API_KEY=${env:GEMINI_API_KEY_DEV}"
      ]
    },
    {
      "name": "Staging",
      "type": "dart",
      "request": "launch",
      "program": "lib/main_staging.dart",
      "args": [
        "--dart-define=ENVIRONMENT=staging",
        "--dart-define=GEMINI_API_KEY=${env:GEMINI_API_KEY_STAGING}"
      ]
    },
    {
      "name": "Production",
      "type": "dart",
      "request": "launch",
      "program": "lib/main_production.dart",
      "args": [
        "--dart-define=ENVIRONMENT=production",
        "--dart-define=GEMINI_API_KEY=${env:GEMINI_API_KEY_PROD}"
      ]
    }
  ]
}
```

### 10. Environment Variables Setup

#### Create .env files (DO NOT COMMIT)
```bash
# .env.development (local development)
ENVIRONMENT=development
GEMINI_API_KEY_DEV=your_development_api_key_here
FIREBASE_PROJECT_ID=aura-dev-xxxxx

# .env.staging
ENVIRONMENT=staging
GEMINI_API_KEY_STAGING=your_staging_api_key_here
FIREBASE_PROJECT_ID=aura-staging-xxxxx

# .env.production
ENVIRONMENT=production
GEMINI_API_KEY_PROD=your_production_api_key_here
FIREBASE_PROJECT_ID=aura-prod-xxxxx
```

#### Update .gitignore
```bash
# Add to .gitignore
.env*
!.env.example
.flutter-plugins
.flutter-plugins-dependencies
.dart_tool/
build/
```

## ✅ Environment Verification Checklist

### Development Environment
- [ ] Flutter doctor shows no critical issues
- [ ] Firebase CLI authenticated and working
- [ ] FlutterFire CLI installed and functional
- [ ] All emulators start without errors
- [ ] Project builds successfully for all platforms
- [ ] Environment variables properly configured
- [ ] Code analysis passes without warnings
- [ ] Git hooks functioning correctly

### Firebase Configuration
- [ ] Three Firebase projects created (dev/staging/prod)
- [ ] Authentication configured with email/password and Google
- [ ] Firestore database created and accessible
- [ ] Storage bucket created with proper permissions
- [ ] Analytics enabled and tracking events
- [ ] App Check configured for security

### Development Tools
- [ ] VS Code with Flutter extensions installed
- [ ] Android Studio/Xcode configured for platform development
- [ ] Device/emulator debugging working
- [ ] Hot reload functioning properly
- [ ] Debugger breakpoints working
- [ ] Performance profiling tools accessible

This comprehensive setup ensures you have a production-ready development environment that follows industry best practices and supports the full development lifecycle of your Flutter application.
