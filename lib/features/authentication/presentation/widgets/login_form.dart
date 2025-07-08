import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/constants/app_constants.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/core/utils/validators.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';

/// Login form widget that handles user authentication
class LoginForm extends StatefulWidget {
  /// Creates a new [LoginForm]
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  // Password visibility toggle
  bool _isPasswordVisible = false;
  
  // Debouncing timer for login attempts
  Timer? _debounceTimer;
  bool _isLoginDebounced = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onLoginPressed() {
    if (!_formKey.currentState!.validate()) return;
    
    // Prevent multiple rapid login attempts
    if (_isLoginDebounced) return;
    
    setState(() {
      _isLoginDebounced = true;
    });
    
    // Reset debounce after specified duration
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: AppConstants.debounceDuration),
      () => setState(() => _isLoginDebounced = false),
    );

    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Sanitize inputs before sending
    final sanitizedEmail = SecurityUtils.sanitizeInput(_emailController.text.trim());
    final sanitizedPassword = SecurityUtils.sanitizeInput(_passwordController.text);

    context.read<LoginBloc>().add(
      LoginRequested(
        email: sanitizedEmail,
        password: sanitizedPassword,
      ),
    );
  }

  void _onGoogleLoginPressed() {
    context.read<LoginBloc>().add(const LoginWithGoogleRequested());
  }

  void _onForgotPasswordPressed() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first')),
      );
      _emailFocusNode.requestFocus();
      return;
    }
    
    // Validate email format before sending
    if (Validators.validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      _emailFocusNode.requestFocus();
      return;
    }

    context.read<LoginBloc>().add(
      ForgotPasswordRequested(email: SecurityUtils.sanitizeInput(email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          // Reset debounce timer on success
          _debounceTimer?.cancel();
          setState(() => _isLoginDebounced = false);
          
          // Pop login page and any dialogs
          Navigator.of(context).pop();

          // Show success message if this was a password reset
          if (state.errorMessage?.contains('Password reset') ?? false) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        }

        if (state.status == LoginStatus.failure && state.errorMessage != null) {
          // Reset debounce timer on failure
          _debounceTimer?.cancel();
          setState(() => _isLoginDebounced = false);
          
          // Provide better error messages based on error type
          String errorMessage = state.errorMessage!;
          
          // Handle specific error types
          if (errorMessage.toLowerCase().contains('network') ||
              errorMessage.toLowerCase().contains('connection')) {
            errorMessage = AppConstants.networkErrorMessage;
          } else if (errorMessage.toLowerCase().contains('invalid') ||
                     errorMessage.toLowerCase().contains('wrong')) {
            errorMessage = 'Invalid email or password. Please try again.';
          } else if (errorMessage.toLowerCase().contains('disabled') ||
                     errorMessage.toLowerCase().contains('locked')) {
            errorMessage = 'Account is disabled. Please contact support.';
          } else if (errorMessage.toLowerCase().contains('timeout')) {
            errorMessage = 'Request timed out. Please try again.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _onLoginPressed(),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          final isLoading = state.status == LoginStatus.loading;
          final isLoginDisabled = isLoading || _isLoginDebounced;

          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email field with improved validation and accessibility
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  enabled: !isLoading,
                  maxLength: 254, // RFC 5321 email length limit
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.email],
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
                    LengthLimitingTextInputFormatter(254),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    counterText: '', // Hide character counter
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Use proper email validation from Validators class
                    return Validators.validateEmail(value.trim());
                  },
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                // Password field with visibility toggle and complexity requirements
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  enabled: !isLoading,
                  maxLength: 128, // Reasonable password length limit
                  obscureText: !_isPasswordVisible,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(128),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
                    ),
                    border: const OutlineInputBorder(),
                    counterText: '', // Hide character counter
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                    }
                    
                    // Check password strength for additional security
                    final strength = SecurityUtils.validatePasswordStrength(value);
                    if (strength == PasswordStrength.weak) {
                      return 'Password is too weak. Use uppercase, lowercase, numbers, and symbols.';
                    }
                    
                    return null;
                  },
                  onFieldSubmitted: (_) => _onLoginPressed(),
                ),
                const SizedBox(height: 24),
                // Login button with debouncing protection
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoginDisabled ? null : _onLoginPressed,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isLoginDebounced ? 'Please wait...' : 'Log In',
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: isLoginDisabled ? null : _onGoogleLoginPressed,
                      child: const Text('Sign in with Google'),
                    ),
                    TextButton(
                      onPressed: isLoginDisabled ? null : _onForgotPasswordPressed,
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
