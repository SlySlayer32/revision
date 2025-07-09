import 'package:flutter/material.dart';
import 'package:revision/core/utils/security_utils.dart';

/// Widget that displays password strength indicator
class PasswordStrengthIndicator extends StatelessWidget {
  /// Creates a new [PasswordStrengthIndicator]
  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    this.showText = true,
  });

  /// The password strength to display
  final PasswordStrength? strength;

  /// Whether to show the strength text
  final bool showText;

  @override
  Widget build(BuildContext context) {
    if (strength == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getStrengthColor() {
      switch (strength!) {
        case PasswordStrength.weak:
          return colorScheme.error;
        case PasswordStrength.medium:
          return Colors.orange;
        case PasswordStrength.strong:
          return Colors.green;
      }
    }

    String getStrengthText() {
      switch (strength!) {
        case PasswordStrength.weak:
          return 'Weak';
        case PasswordStrength.medium:
          return 'Medium';
        case PasswordStrength.strong:
          return 'Strong';
      }
    }

    double getStrengthValue() {
      switch (strength!) {
        case PasswordStrength.weak:
          return 0.33;
        case PasswordStrength.medium:
          return 0.66;
        case PasswordStrength.strong:
          return 1.0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: getStrengthValue(),
          backgroundColor: colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(getStrengthColor()),
        ),
        if (showText) ...[
          const SizedBox(height: 4),
          Text(
            'Password strength: ${getStrengthText()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: getStrengthColor(),
            ),
          ),
        ],
      ],
    );
  }
}