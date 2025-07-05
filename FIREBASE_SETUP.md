# Firebase Development Setup

## Overview
This Flutter app uses Firebase for authentication and other services. Different build flavors are configured for different environments.

## Firebase Auth Emulator (Development)
The development flavor can optionally use Firebase Auth Emulator for local testing.

### Setup Instructions
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Start emulator: `firebase emulators:start --only auth`
4. Run app with VS Code "Launch Development" configuration

### Without Emulator
Run development against real Firebase:
```bash
flutter run --flavor development --target lib/main_development.dart
```

## Build Flavors
- **Development** (`com.sly.revision.dev`): Optional emulator support
- **Staging** (`com.sly.revision.stg`): Real Firebase services
- **Production** (`com.sly.revision`): Real Firebase services

## Troubleshooting
- Ensure internet connectivity for Firebase services
- Verify Firebase project configuration in `firebase_options.dart`
- Check Firebase Auth Emulator is running for development with emulator flag