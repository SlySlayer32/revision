import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/utils/validators.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';

/// Sign up form widget that handles user registration
class SignUpForm extends StatefulWidget {
  /// Creates a new [SignUpForm]
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _isAdult = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    if (!_formKey.currentState!.validate()) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    context.read<SignupBloc>().add(
      SignupRequested(
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        acceptedTerms: _acceptedTerms,
        acceptedPrivacy: _acceptedPrivacy,
        isAdult: _isAdult,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }

        if (state.status == SignupStatus.success) {
          // Show success message first
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          
          // Navigate to home screen after a delay
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
          });
        }
      },
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return Validators.validateEmail(value);
                },
                onFieldSubmitted: (_) {
                  _passwordFocusNode.requestFocus();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return Validators.validatePassword(value);
                },
                onFieldSubmitted: (_) {
                  _confirmPasswordFocusNode.requestFocus();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              // Phone number field (optional)
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+1 (555) 123-4567',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.validatePhoneNumber(value);
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _onSignUpPressed(),
              ),
              const SizedBox(height: 20),
              // Age verification checkbox
              CheckboxListTile(
                title: const Text('I am at least 13 years old'),
                value: _isAdult,
                onChanged: (bool? value) {
                  setState(() {
                    _isAdult = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              const SizedBox(height: 8),
              // Terms of service checkbox
              CheckboxListTile(
                title: Row(
                  children: [
                    const Text('I accept the '),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to terms of service
                        _showTermsOfService();
                      },
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                value: _acceptedTerms,
                onChanged: (bool? value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              const SizedBox(height: 8),
              // Privacy policy checkbox
              CheckboxListTile(
                title: Row(
                  children: [
                    const Text('I accept the '),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to privacy policy
                        _showPrivacyPolicy();
                      },
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                value: _acceptedPrivacy,
                onChanged: (bool? value) {
                  setState(() {
                    _acceptedPrivacy = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.status == SignupStatus.loading
                    ? null
                    : _onSignUpPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: state.status == SignupStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign Up'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'By using this application, you agree to the following terms:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. You must be at least 13 years old to use this service.'),
              SizedBox(height: 8),
              Text('2. You agree to use this service in compliance with all applicable laws.'),
              SizedBox(height: 8),
              Text('3. You are responsible for maintaining the confidentiality of your account.'),
              SizedBox(height: 8),
              Text('4. We reserve the right to suspend or terminate accounts that violate these terms.'),
              SizedBox(height: 8),
              Text('5. This service is provided "as is" without any warranties.'),
              SizedBox(height: 16),
              Text(
                'For the complete terms of service, please visit our website.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your privacy is important to us. This policy explains how we collect, use, and protect your information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Data Collection:'),
              Text('• We collect your email address and profile information'),
              Text('• We may collect usage data to improve our service'),
              Text('• Phone numbers are optional and used for verification only'),
              SizedBox(height: 12),
              Text('Data Use:'),
              Text('• Your data is used to provide and improve our services'),
              Text('• We do not sell your personal information to third parties'),
              Text('• Email addresses are used for account verification and communication'),
              SizedBox(height: 12),
              Text('Data Protection:'),
              Text('• We use industry-standard security measures'),
              Text('• Your data is encrypted in transit and at rest'),
              Text('• You can request deletion of your data at any time'),
              SizedBox(height: 16),
              Text(
                'For the complete privacy policy, please visit our website.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
