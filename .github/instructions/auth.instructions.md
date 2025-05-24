---
applyTo: "**/auth/**/*.dart,**/login/**/*.dart,**/registration/**/*.dart"
---
# Authentication Module Instructions

<!-- Last reviewed: 2025-05-23 -->

## Implementation Details

When working on the authentication module, implement:

- Firebase Authentication integration with email/password and Google sign-in
- Clean, minimalist UI for login and registration screens
- Form validation with helpful error messages (e.g., inline validation, clear error text)
- Persistent login state using secure storage (e.g., `flutter_secure_storage`)
- Password reset functionality (via email link)

## Code Structure Guidelines

- Use BLoC pattern with separate events, states, and bloc files. Refer to [BLoC & Cubit Implementation Guidelines](./bloc-guidelines.instructions.md) and [BLoC Widget Structure Guidelines](./bloc_widget_structure.instructions.md).
- Implement a repository layer to abstract Firebase authentication
- Handle all authentication errors gracefully
- Implement proper loading states during authentication operations
- Add comprehensive unit tests for authentication logic

## API Integration

```dart
// Example Firebase Auth initialization
final firebaseAuth = FirebaseAuth.instance;

// Example repository method
Future<UserCredential> signInWithEmailAndPassword({
  required String email, 
  required String password
}) async {
  try {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    throw AuthException.fromFirebaseException(e);
  }
}
```

## User Experience Considerations

- Minimize the number of steps in the authentication flow
- Implement biometric authentication (e.g., fingerprint, Face ID) if available on device, as an alternative to password entry after initial setup.
- Ensure the authentication UI matches the app's overall design language
- Provide clear feedback for all authentication actions
