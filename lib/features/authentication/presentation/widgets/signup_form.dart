import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/utils/security_utils.dart';
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
  // Security questions options
  static const List<String> _securityQuestions = [
    'What was the name of your first pet?',
    'What city were you born in?',
    'What was your childhood nickname?',
    'What is your mother\'s maiden name?',
    'What was the name of your first school?',
    'What was your favorite food as a child?',
    'What was the model of your first car?',
  ];
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _securityQuestionController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _securityQuestionFocusNode = FocusNode();
  final _securityAnswerFocusNode = FocusNode();
  
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _isAdult = false;
  bool _enableSecurityQuestion = false;
  String? _selectedSecurityQuestion;
  
  // Simple anti-bot protection
  late int _captchaNum1;
  late int _captchaNum2;
  late int _captchaAnswer;
  final _captchaController = TextEditingController();
  final _captchaFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _securityQuestionController.dispose();
    _securityAnswerController.dispose();
    _captchaController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _securityQuestionFocusNode.dispose();
    _securityAnswerFocusNode.dispose();
    _captchaFocusNode.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    if (!_formKey.currentState!.validate()) return;

    // Validate CAPTCHA
    final userAnswer = int.tryParse(_captchaController.text);
    if (userAnswer == null || userAnswer != _captchaAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please solve the math problem correctly'),
          backgroundColor: Colors.red,
        ),
      );
      _generateCaptcha(); // Generate new CAPTCHA
      return;
    }

    // Implement basic rate limiting
    final deviceIdentifier = 'signup_${DateTime.now().millisecondsSinceEpoch ~/ 60000}'; // Per minute
    if (SecurityUtils.isRateLimited(deviceIdentifier, maxRequests: 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too many signup attempts. Please wait a moment before trying again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        securityQuestion: _enableSecurityQuestion ? _selectedSecurityQuestion : null,
        securityAnswer: _enableSecurityQuestion ? _securityAnswerController.text : null,
      ),
    );
  }

  void _generateCaptcha() {
    setState(() {
      _captchaNum1 = (DateTime.now().millisecondsSinceEpoch % 10) + 1;
      _captchaNum2 = (DateTime.now().millisecondsSinceEpoch % 9) + 1;
      _captchaAnswer = _captchaNum1 + _captchaNum2;
      _captchaController.clear();
    });
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = SecurityUtils.validatePasswordStrength(password);
    Color color;
    String text;
    double progress;

    switch (strength) {
      case PasswordStrength.weak:
        color = Colors.red;
        text = 'Weak';
        progress = 0.33;
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        text = 'Medium';
        progress = 0.66;
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        text = 'Strong';
        progress = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (strength == PasswordStrength.weak) ...[
          const SizedBox(height: 4),
          Text(
            'Use 8+ characters with uppercase, lowercase, numbers, and symbols',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ],
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
                onChanged: (value) {
                  setState(() {}); // Update password strength indicator
                },
              ),
              const SizedBox(height: 8),
              // Password strength indicator
              _buildPasswordStrengthIndicator(),
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
              // Security question section
              CheckboxListTile(
                title: const Text('Set up security question (Optional)'),
                subtitle: const Text('Helps recover your account if you forget your password'),
                value: _enableSecurityQuestion,
                onChanged: (bool? value) {
                  setState(() {
                    _enableSecurityQuestion = value ?? false;
                    if (!_enableSecurityQuestion) {
                      _selectedSecurityQuestion = null;
                      _securityAnswerController.clear();
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              if (_enableSecurityQuestion) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSecurityQuestion,
                  decoration: const InputDecoration(
                    labelText: 'Security Question',
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  items: _securityQuestions.map((String question) {
                    return DropdownMenuItem<String>(
                      value: question,
                      child: Text(question),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedSecurityQuestion = value;
                    });
                  },
                  validator: (value) {
                    if (_enableSecurityQuestion && value == null) {
                      return 'Please select a security question';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _securityAnswerController,
                  focusNode: _securityAnswerFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Security Answer',
                    prefixIcon: Icon(Icons.security),
                    hintText: 'Enter your answer',
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (_enableSecurityQuestion) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your security answer';
                      }
                      if (value.length < 3) {
                        return 'Security answer must be at least 3 characters';
                      }
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _onSignUpPressed(),
                ),
              ],
              const SizedBox(height: 20),
              // Simple CAPTCHA for anti-bot protection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify you\'re human',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'What is $_captchaNum1 + $_captchaNum2?',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _captchaController,
                            focusNode: _captchaFocusNode,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Answer',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final answer = int.tryParse(value);
                              if (answer == null) {
                                return 'Numbers only';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _generateCaptcha,
                          tooltip: 'Generate new question',
                        ),
                      ],
                    ),
                  ],
                ),
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
