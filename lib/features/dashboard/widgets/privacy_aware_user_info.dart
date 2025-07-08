import 'package:flutter/material.dart';

/// Widget that displays user email with privacy controls
class PrivacyAwareUserInfo extends StatelessWidget {
  const PrivacyAwareUserInfo({
    super.key,
    required this.email,
    required this.isVisible,
    required this.onVisibilityChanged,
  });

  final String email;
  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            isVisible ? email : _maskEmail(email),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            size: 20,
          ),
          onPressed: () => onVisibilityChanged(!isVisible),
          tooltip: isVisible ? 'Hide email' : 'Show email',
        ),
      ],
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return 'Unknown User';
    
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';
    
    final username = parts[0];
    final domain = parts[1];
    
    String maskedUsername;
    if (username.length <= 2) {
      maskedUsername = '*' * username.length;
    } else {
      maskedUsername = username.substring(0, 2) + '*' * (username.length - 2);
    }
    
    final domainParts = domain.split('.');
    if (domainParts.length >= 2) {
      final maskedDomain = domainParts[0].substring(0, 1) + 
          '*' * (domainParts[0].length - 1) + 
          '.' + domainParts.last;
      return '$maskedUsername@$maskedDomain';
    }
    
    return '$maskedUsername@***';
  }
}