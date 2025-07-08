import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';

/// Widget that controls access based on user roles
class RoleBasedAccess extends StatelessWidget {
  const RoleBasedAccess({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
    this.showFallback = true,
  });

  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        final user = state.user;
        
        // If no user, don't show anything
        if (user == null) {
          return showFallback ? (fallback ?? const SizedBox.shrink()) : const SizedBox.shrink();
        }

        // Check if user has any of the allowed roles
        final userRoles = _getUserRoles(user);
        final hasAccess = allowedRoles.any((role) => userRoles.contains(role)) || 
                         allowedRoles.contains('*'); // '*' means all users

        if (hasAccess) {
          return child;
        } else {
          return showFallback ? (fallback ?? _buildNoAccessWidget()) : const SizedBox.shrink();
        }
      },
    );
  }

  List<String> _getUserRoles(dynamic user) {
    // Extract roles from user object
    // This assumes the user object has a roles property or custom claims
    if (user.customClaims != null && user.customClaims.containsKey('roles')) {
      final roles = user.customClaims['roles'];
      if (roles is List) {
        return roles.cast<String>();
      } else if (roles is String) {
        return [roles];
      }
    }
    
    // Default role for authenticated users
    return ['user'];
  }

  Widget _buildNoAccessWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Access restricted',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-defined role constants
class UserRoles {
  static const String admin = 'admin';
  static const String user = 'user';
  static const String premium = 'premium';
  static const String moderator = 'moderator';
  static const String all = '*';
}