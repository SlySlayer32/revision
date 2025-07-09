import 'package:flutter/material.dart';
import 'package:revision/core/services/preferences_service.dart';

/// Widget that displays session management information
class SessionIndicator extends StatelessWidget {
  const SessionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final lastSessionTime = PreferencesService.getLastSessionTime();
    final isExpired = PreferencesService.isSessionExpired();
    final sessionTimeout = PreferencesService.getSessionTimeout();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red.shade300 : Colors.green.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.warning_amber : Icons.check_circle_outline,
            size: 16,
            color: isExpired ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            _getSessionStatus(lastSessionTime, isExpired, sessionTimeout),
            style: TextStyle(
              fontSize: 12,
              color: isExpired ? Colors.red.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getSessionStatus(int lastSessionTime, bool isExpired, int timeoutMinutes) {
    if (lastSessionTime == 0) {
      return 'New Session';
    }
    
    if (isExpired) {
      return 'Session Expired';
    }

    final lastActivity = DateTime.fromMillisecondsSinceEpoch(lastSessionTime);
    final now = DateTime.now();
    final diff = now.difference(lastActivity);

    if (diff.inMinutes < 1) {
      return 'Active';
    } else if (diff.inMinutes < timeoutMinutes) {
      return 'Active (${diff.inMinutes}m ago)';
    } else {
      return 'Session Expired';
    }
  }
}