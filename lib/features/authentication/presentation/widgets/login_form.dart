import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/constants/app_constants.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/core/utils/validators.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/widgets/password_strength_indicator.dart';

/// Login form widget that handles user authentication
class LoginForm extends StatefulWidget {
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

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (_passwordController.text.isNotEmpty) {
      context.read<LoginBloc>().add(
            PasswordStrengthChecked(password: _passwordController.text),
          );
    }
  }

  void _onLoginPressed() {
    if (!_formKey.currentState!.validate()) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final sanitizedEmail = SecurityUtils.sanitizeInput(_emailController.text.trim());
    final sanitizedPassword = SecurityUtils.sanitizeInput(_passwordController.text);

    context.read<LoginBloc>().add(
          LoginRequested(
            email: sanitizedEmail,
            password: sanitizedPassword,
          ),
        );
  }

  void _onBiometricLoginPressed() {
    context.read<LoginBloc>().add(const BiometricLoginRequested());
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
          Navigator.of(context).pop();

          // Show success message if this was a password reset
          if (state.errorMessage?.contains('Password reset') ?? false) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        }

        if (state.status == LoginStatus.failure && state.errorMessage != null) {
          String errorMessage = state.errorMessage!;

          // Provide user-friendly error messages
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
                onPressed: _onLoginPressed,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          final isLoading = state.status == LoginStatus.loading;

          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  enabled: !isLoading,
                  maxLength: 254,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.email],
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    LengthLimitingTextInputFormatter(254),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return Validators.validateEmail(value.trim());
                  },
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  enabled: !isLoading,
                  maxLength: 128,
                  obscureText: _obscurePassword,
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
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    ),
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                    }
                    final strength = SecurityUtils.validatePasswordStrength(value);
                    if (strength == PasswordStrength.weak) {
                      return 'Password is too weak. Use uppercase, lowercase, numbers, and symbols.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _onLoginPressed(),
                ),
                const SizedBox(height: 8),
                PasswordStrengthIndicator(strength: state.passwordStrength),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Remember me'),
                  value: _rememberMe,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onLoginPressed,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.biometricAvailable)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Login with Biometrics'),
                      onPressed: isLoading ? null : _onBiometricLoginPressed,
                    ),
                  ),
                if (state.biometricAvailable) const SizedBox(height: 16),
                if (state.isRateLimited)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Too many login attempts. Please wait before trying again.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.isRateLimited) const SizedBox(height: 16),
                if (state.showCaptcha)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.security, size: 48),
                        SizedBox(height: 8),
                        Text('Please verify you are human'),
                        Text('(CAPTCHA integration would go here)'),
                      ],
                    ),
                  ),
                if (state.showCaptcha) const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : _onGoogleLoginPressed,
                      child: const Text('Sign in with Google'),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : _onForgotPasswordPressed,
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