```prompt
// filepath: g:\BUILDING\New folder\web-guide-generator\revision\.github\prompts\05-auth-presentation-layer.prompt.md
# Phase 2: Authentication Presentation Layer

## Context & Requirements
Implement the authentication UI using flutter_bloc with VGV patterns and test-first development approach. This layer must provide seamless user experience with comprehensive error handling and loading states.

**Critical Implementation Requirements:**
- BLoC pattern with Cubit for state management
- VGV Page/View separation pattern
- Test-first development approach (write tests before implementation)
- Form validation with real-time feedback
- Accessibility compliance (WCAG 2.1 AA)
- Error handling with user-friendly messages
- Loading states with proper animations

## Exact Implementation Specifications

### 1. Authentication BLoC Architecture (Test-First)

**First: Write BLoC Tests**
```dart
// test/features/authentication/cubit/auth_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/features/authentication/authentication.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  group('AuthCubit', () {
    late AuthCubit authCubit;
    late MockSignInUseCase mockSignInUseCase;
    late MockSignUpUseCase mockSignUpUseCase;
    late MockSignOutUseCase mockSignOutUseCase;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

    setUp(() {
      mockSignInUseCase = MockSignInUseCase();
      mockSignUpUseCase = MockSignUpUseCase();
      mockSignOutUseCase = MockSignOutUseCase();
      mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
      
      authCubit = AuthCubit(
        signInUseCase: mockSignInUseCase,
        signUpUseCase: mockSignUpUseCase,
        signOutUseCase: mockSignOutUseCase,
        getCurrentUserUseCase: mockGetCurrentUserUseCase,
      );
    });

    tearDown(() => authCubit.close());

    test('initial state is AuthState.initial()', () {
      expect(authCubit.state, const AuthState.initial());
    });

    group('signInWithEmailAndPassword', () {
      const email = 'test@example.com';
      const password = 'password123';
      const user = User(id: '1', email: email, displayName: 'Test User');

      blocTest<AuthCubit, AuthState>(
        'emits [loading, authenticated] when sign in succeeds',
        build: () {
          when(() => mockSignInUseCase(email: email, password: password))
              .thenAnswer((_) async => const Success(user));
          return authCubit;
        },
        act: (cubit) => cubit.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(user),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [loading, unauthenticated] when sign in fails with invalid credentials',
        build: () {
          when(() => mockSignInUseCase(email: email, password: password))
              .thenAnswer((_) async => const Failure(
                AuthException.invalidCredentials('Invalid email or password'),
              ));
          return authCubit;
        },
        act: (cubit) => cubit.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(
            error: AuthException.invalidCredentials('Invalid email or password'),
          ),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [loading, unauthenticated] when sign in fails with network error',
        build: () {
          when(() => mockSignInUseCase(email: email, password: password))
              .thenAnswer((_) async => const Failure(
                AuthException.networkError('No internet connection'),
              ));
          return authCubit;
        },
        act: (cubit) => cubit.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(
            error: AuthException.networkError('No internet connection'),
          ),
        ],
      );
    });

    group('signUpWithEmailAndPassword', () {
      const email = 'newuser@example.com';
      const password = 'password123';
      const displayName = 'New User';
      const user = User(id: '2', email: email, displayName: displayName);

      blocTest<AuthCubit, AuthState>(
        'emits [loading, authenticated] when sign up succeeds',
        build: () {
          when(() => mockSignUpUseCase(
                email: email,
                password: password,
                displayName: displayName,
              )).thenAnswer((_) async => const Success(user));
          return authCubit;
        },
        act: (cubit) => cubit.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(user),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [loading, unauthenticated] when sign up fails with email already in use',
        build: () {
          when(() => mockSignUpUseCase(
                email: email,
                password: password,
                displayName: displayName,
              )).thenAnswer((_) async => const Failure(
                AuthException.emailAlreadyInUse('Email is already registered'),
              ));
          return authCubit;
        },
        act: (cubit) => cubit.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(
            error: AuthException.emailAlreadyInUse('Email is already registered'),
          ),
        ],
      );
    });

    group('signOut', () {
      blocTest<AuthCubit, AuthState>(
        'emits [loading, unauthenticated] when sign out succeeds',
        build: () {
          when(() => mockSignOutUseCase())
              .thenAnswer((_) async => const Success(unit));
          return authCubit;
        },
        act: (cubit) => cubit.signOut(),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [loading, error] when sign out fails',
        build: () {
          when(() => mockSignOutUseCase())
              .thenAnswer((_) async => const Failure(
                AuthException.unknown('Sign out failed'),
              ));
          return authCubit;
        },
        act: (cubit) => cubit.signOut(),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(
            error: AuthException.unknown('Sign out failed'),
          ),
        ],
      );
    });

    group('checkAuthStatus', () {
      const user = User(id: '1', email: 'test@example.com', displayName: 'Test User');

      blocTest<AuthCubit, AuthState>(
        'emits [loading, authenticated] when user is signed in',
        build: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Success(user));
          return authCubit;
        },
        act: (cubit) => cubit.checkAuthStatus(),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(user),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [loading, unauthenticated] when no user is signed in',
        build: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Failure(
                AuthException.userNotFound('No user signed in'),
              ));
          return authCubit;
        },
        act: (cubit) => cubit.checkAuthStatus(),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );
    });
  });
}
```

**Then: Implement AuthCubit**
```dart
// lib/features/authentication/cubit/auth_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/domain.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AuthState.initial());

  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    
    final result = await _signInUseCase(
      email: email,
      password: password,
    );
    
    result.fold(
      (failure) => emit(AuthState.unauthenticated(error: failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    emit(const AuthState.loading());
    
    final result = await _signUpUseCase(
      email: email,
      password: password,
      displayName: displayName,
    );
    
    result.fold(
      (failure) => emit(AuthState.unauthenticated(error: failure)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> signOut() async {
    emit(const AuthState.loading());
    
    final result = await _signOutUseCase();
    
    result.fold(
      (failure) => emit(AuthState.unauthenticated(error: failure)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> checkAuthStatus() async {
    emit(const AuthState.loading());
    
    final result = await _getCurrentUserUseCase();
    
    result.fold(
      (_) => emit(const AuthState.unauthenticated()),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
}
```

**AuthState Implementation**
```dart
// lib/features/authentication/cubit/auth_state.dart
part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = AuthAuthenticated;
  const factory AuthState.unauthenticated({AuthException? error}) = AuthUnauthenticated;

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.error});

  final AuthException? error;

  @override
  List<Object?> get props => [error];
}
```

### 2. Login Page Implementation (Test-First)

**First: Write Widget Tests**
```dart
// test/features/authentication/view/login_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/features/authentication/authentication.dart';
import '../../../helpers/helpers.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  group('LoginPage', () {
    late MockAuthCubit mockAuthCubit;

    setUp(() {
      mockAuthCubit = MockAuthCubit();
      when(() => mockAuthCubit.state).thenReturn(const AuthState.initial());
    });

    testWidgets('renders LoginView', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthCubit,
          child: const LoginPage(),
        ),
      );

      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('provides AuthCubit to LoginView', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: mockAuthCubit,
          child: const LoginPage(),
        ),
      );

      final loginView = tester.widget<LoginView>(find.byType(LoginView));
      expect(loginView, isNotNull);
    });
  });

  group('LoginView', () {
    late MockAuthCubit mockAuthCubit;

    setUp(() {
      mockAuthCubit = MockAuthCubit();
      when(() => mockAuthCubit.state).thenReturn(const AuthState.initial());
    });

    Widget buildSubject() {
      return BlocProvider.value(
        value: mockAuthCubit,
        child: const LoginView(),
      );
    }

    group('renders', () {
      testWidgets('email text field', (tester) async {
        await tester.pumpApp(buildSubject());

        expect(
          find.byKey(const Key('loginView_emailInput_textField')),
          findsOneWidget,
        );
      });

      testWidgets('password text field', (tester) async {
        await tester.pumpApp(buildSubject());

        expect(
          find.byKey(const Key('loginView_passwordInput_textField')),
          findsOneWidget,
        );
      });

      testWidgets('sign in button', (tester) async {
        await tester.pumpApp(buildSubject());

        expect(
          find.byKey(const Key('loginView_signIn_elevatedButton')),
          findsOneWidget,
        );
      });

      testWidgets('sign up button', (tester) async {
        await tester.pumpApp(buildSubject());

        expect(
          find.byKey(const Key('loginView_signUp_textButton')),
          findsOneWidget,
        );
      });
    });

    group('interactions', () {
      testWidgets('calls signInWithEmailAndPassword when sign in button is pressed', (tester) async {
        await tester.pumpApp(buildSubject());

        await tester.enterText(
          find.byKey(const Key('loginView_emailInput_textField')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('loginView_passwordInput_textField')),
          'password123',
        );

        await tester.tap(find.byKey(const Key('loginView_signIn_elevatedButton')));

        verify(() => mockAuthCubit.signInWithEmailAndPassword(
              email: 'test@example.com',
              password: 'password123',
            )).called(1);
      });

      testWidgets('navigates to sign up page when sign up button is pressed', (tester) async {
        await tester.pumpApp(buildSubject());

        await tester.tap(find.byKey(const Key('loginView_signUp_textButton')));
        await tester.pumpAndSettle();

        expect(find.byType(SignUpPage), findsOneWidget);
      });
    });

    group('state handling', () {
      testWidgets('shows loading indicator when state is loading', (tester) async {
        when(() => mockAuthCubit.state).thenReturn(const AuthState.loading());

        await tester.pumpApp(buildSubject());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows error message when state has error', (tester) async {
        const error = AuthException.invalidCredentials('Invalid credentials');
        when(() => mockAuthCubit.state).thenReturn(
          const AuthState.unauthenticated(error: error),
        );

        await tester.pumpApp(buildSubject());

        expect(find.text('Invalid credentials'), findsOneWidget);
      });

      testWidgets('navigates to home when state is authenticated', (tester) async {
        const user = User(id: '1', email: 'test@example.com', displayName: 'Test User');
        when(() => mockAuthCubit.state).thenReturn(
          const AuthState.authenticated(user),
        );

        await tester.pumpApp(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
      });
    });

    group('form validation', () {
      testWidgets('shows error when email is invalid', (tester) async {
        await tester.pumpApp(buildSubject());

        await tester.enterText(
          find.byKey(const Key('loginView_emailInput_textField')),
          'invalid-email',
        );
        
        // Trigger validation by attempting to submit
        await tester.tap(find.byKey(const Key('loginView_signIn_elevatedButton')));
        await tester.pump();

        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('shows error when password is too short', (tester) async {
        await tester.pumpApp(buildSubject());

        await tester.enterText(
          find.byKey(const Key('loginView_passwordInput_textField')),
          '123',
        );
        
        // Trigger validation by attempting to submit
        await tester.tap(find.byKey(const Key('loginView_signIn_elevatedButton')));
        await tester.pump();

        expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      });

      testWidgets('disables sign in button when form is invalid', (tester) async {
        await tester.pumpApp(buildSubject());

        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('loginView_signIn_elevatedButton')),
        );

        expect(button.onPressed, isNull);
      });

      testWidgets('enables sign in button when form is valid', (tester) async {
        await tester.pumpApp(buildSubject());

        await tester.enterText(
          find.byKey(const Key('loginView_emailInput_textField')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('loginView_passwordInput_textField')),
          'password123',
        );
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('loginView_signIn_elevatedButton')),
        );

        expect(button.onPressed, isNotNull);
      });
    });
  });
}
```

**Then: Implement Login Page**
```dart
// lib/features/authentication/view/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import 'login_view.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const LoginPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => context.read<AuthCubit>(),
        child: const LoginView(),
      ),
    );
  }
}
```

**LoginView Implementation**
```dart
// lib/features/authentication/view/login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/widgets.dart';
import 'sign_up_page.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthAuthenticated():
            Navigator.of(context).pushReplacementNamed('/home');
          case AuthUnauthenticated(:final error):
            if (error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(_getErrorMessage(error)),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
            }
          case AuthLoading():
          case AuthInitial():
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign In'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  
                  // App Logo/Title
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Photo Editor',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transform your photos with AI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Email Field
                  EmailInputField(
                    key: const Key('loginView_emailInput_textField'),
                    controller: _emailController,
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  PasswordInputField(
                    key: const Key('loginView_passwordInput_textField'),
                    controller: _passwordController,
                    isVisible: _isPasswordVisible,
                    onVisibilityToggle: () => setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    }),
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign In Button
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        key: const Key('loginView_signIn_elevatedButton'),
                        onPressed: _isFormValid && state is! AuthLoading
                            ? () => _signIn(context)
                            : null,
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign In'),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sign Up Button
                  TextButton(
                    key: const Key('loginView_signUp_textButton'),
                    onPressed: () => _navigateToSignUp(context),
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _emailController.text.contains('@') &&
           _passwordController.text.length >= 6;
  }

  void _signIn(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.of(context).push(SignUpPage.route());
  }

  String _getErrorMessage(AuthException error) {
    return switch (error) {
      AuthException.invalidCredentials() => 'Invalid email or password',
      AuthException.userNotFound() => 'No account found with this email',
      AuthException.networkError() => 'Please check your internet connection',
      AuthException.tooManyRequests() => 'Too many attempts. Please try again later',
      _ => 'An unexpected error occurred. Please try again',
    };
  }
}
```

### 3. Custom Input Widgets (Test-First)

**EmailInputField Widget**
```dart
// lib/features/authentication/widgets/email_input_field.dart
import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';

class EmailInputField extends StatelessWidget {
  const EmailInputField({
    required this.controller,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email address',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) => Validators.email(value),
    );
  }
}
```

**PasswordInputField Widget**
```dart
// lib/features/authentication/widgets/password_input_field.dart
import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';

class PasswordInputField extends StatelessWidget {
  const PasswordInputField({
    required this.controller,
    required this.isVisible,
    required this.onVisibilityToggle,
    this.onChanged,
    this.isConfirmPassword = false,
    super.key,
  });

  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onVisibilityToggle;
  final ValueChanged<String>? onChanged;
  final bool isConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: !isVisible,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: isConfirmPassword ? 'Confirm Password' : 'Password',
        hintText: isConfirmPassword 
            ? 'Confirm your password' 
            : 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onVisibilityToggle,
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (value) => Validators.password(value),
    );
  }
}
```

### 4. Sign Up Page Implementation (Following Same Pattern)

**SignUpPage and SignUpView** (implement following same test-first pattern as LoginPage)

### 5. Barrel Exports

```dart
// lib/features/authentication/view/view.dart
export 'login_page.dart';
export 'login_view.dart';
export 'sign_up_page.dart';
export 'sign_up_view.dart';

// lib/features/authentication/widgets/widgets.dart
export 'email_input_field.dart';
export 'password_input_field.dart';

// lib/features/authentication/authentication.dart
export 'cubit/cubit.dart';
export 'domain/domain.dart';
export 'data/data.dart';
export 'view/view.dart';
export 'widgets/widgets.dart';
```

### 6. Validators Utility

```dart
// lib/core/utils/validators.dart
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    final passwordError = Validators.password(value);
    if (passwordError != null) return passwordError;
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Display name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters';
    }
    
    return null;
  }
}
```

## Acceptance Criteria (Must All Pass)

1. ✅ All BLoC tests pass with 100% coverage
2. ✅ All widget tests pass with golden test verification
3. ✅ Form validation works with real-time feedback
4. ✅ Error handling displays user-friendly messages
5. ✅ Loading states show appropriate indicators
6. ✅ Navigation between login/signup works correctly
7. ✅ Accessibility labels and semantics are implemented
8. ✅ State management follows VGV BLoC patterns
9. ✅ File structure follows VGV conventions exactly
10. ✅ All widgets are properly tested and documented

**Quality Gate:** All tests pass, zero accessibility violations, smooth animations

**Performance Target:** Form interactions < 16ms response time, smooth 60fps animations

**Security Compliance:** No sensitive data logged, secure text input handling

---

**Next Step:** After completion, proceed to Image Selection Feature (Phase 3, Step 1)
```
