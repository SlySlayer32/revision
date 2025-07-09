import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/widgets/password_strength_indicator.dart';

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
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen to password changes for strength checking
    _passwordController.addListener(_onPasswordChanged);
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

    // Sanitize inputs before sending
    final sanitizedEmail = SecurityUtils.sanitizeInput(_emailController.text);
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
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first')),
      );
      _emailFocusNode.requestFocus();
      return;
    }

    // Sanitize email input
    final sanitizedEmail = SecurityUtils.sanitizeInput(_emailController.text);

    context.read<LoginBloc>().add(
      ForgotPasswordRequested(email: sanitizedEmail),
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
          // Pop login page and any dialogs
          Navigator.of(context).pop();

          // Show success message if this was a password reset
          if (state.errorMessage?.contains('Password reset') ?? false) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        }

        if (state.status == LoginStatus.failure || 
            state.status == LoginStatus.rateLimited ||
            state.status == LoginStatus.accountLocked ||
            state.status == LoginStatus.captchaRequired) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
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
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!SecurityUtils.isValidEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Password strength indicator
                PasswordStrengthIndicator(strength: state.passwordStrength),
                const SizedBox(height: 16),
                // Remember me checkbox
                CheckboxListTile(
                  title: const Text('Remember me'),
                  value: _rememberMe,
                  onChanged: isLoading ? null : (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                // Login button
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
                // Biometric login button
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
                // Rate limit warning
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
                // CAPTCHA placeholder (would integrate with actual CAPTCHA service)
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
                const SizedBox(height: 16),
                // Google login and forgot password buttons
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
