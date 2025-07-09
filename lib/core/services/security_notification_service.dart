import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/feature_flag_service.dart';

/// Security notifications service that handles security alerts and update prompts
///
/// This service manages security-related notifications including:
/// - App update notifications
/// - Security alerts
/// - Account security reminders
/// - Permission warnings
class SecurityNotificationService {
  static final SecurityNotificationService _instance = SecurityNotificationService._();
  factory SecurityNotificationService() => _instance;
  SecurityNotificationService._();

  final AnalyticsService _analytics = AnalyticsService();
  final FeatureFlagService _featureFlags = FeatureFlagService();

  /// Check and show security notifications if needed
  Future<void> checkSecurityNotifications(BuildContext context) async {
    if (!_featureFlags.enableSecurityNotifications) return;

    try {
      // Check for app updates
      if (_featureFlags.enableUpdatePrompts) {
        await _checkForAppUpdates(context);
      }

      // Check for security alerts
      await _checkSecurityAlerts(context);
    } catch (e) {
      log('❌ Failed to check security notifications: $e');
      await _analytics.trackError('security_notification_check_failed', context: e.toString());
    }
  }

  /// Check for app updates and show prompt if needed
  Future<void> _checkForAppUpdates(BuildContext context) async {
    try {
      // In a real implementation, this would check with app store or server
      // For now, we'll simulate based on feature flags
      if (_featureFlags.forceUpdate) {
        await _showForceUpdateDialog(context);
      }
    } catch (e) {
      log('❌ Failed to check for app updates: $e');
    }
  }

  /// Check for security alerts
  Future<void> _checkSecurityAlerts(BuildContext context) async {
    try {
      // In a real implementation, this would check with security service
      // For now, we'll show based on feature flags or conditions
      if (_featureFlags.maintenanceMode) {
        await _showMaintenanceAlert(context);
      }
    } catch (e) {
      log('❌ Failed to check security alerts: $e');
    }
  }

  /// Show force update dialog
  Future<void> _showForceUpdateDialog(BuildContext context) async {
    if (!context.mounted) return;

    await _analytics.trackAction('force_update_dialog_shown');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.red),
            SizedBox(width: 8),
            Text('Update Required'),
          ],
        ),
        content: const Text(
          'A critical security update is available. Please update the app to continue using it safely.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _analytics.trackAction('force_update_accepted');
              // In a real app, this would open the app store
              Navigator.of(context).pop();
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Show maintenance alert
  Future<void> _showMaintenanceAlert(BuildContext context) async {
    if (!context.mounted) return;

    await _analytics.trackAction('maintenance_alert_shown');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Scheduled maintenance in progress. Some features may be limited.'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () async {
            await _analytics.trackAction('maintenance_alert_dismissed');
          },
        ),
      ),
    );
  }

  /// Show security tip notification
  Future<void> showSecurityTip(BuildContext context, String tip) async {
    if (!context.mounted || !_featureFlags.enableSecurityNotifications) return;

    await _analytics.trackAction('security_tip_shown', parameters: {'tip': tip});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.security, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(tip)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Got it',
          textColor: Colors.white,
          onPressed: () async {
            await _analytics.trackAction('security_tip_acknowledged');
          },
        ),
      ),
    );
  }

  /// Show account security reminder
  Future<void> showAccountSecurityReminder(BuildContext context) async {
    if (!context.mounted || !_featureFlags.enableSecurityNotifications) return;

    await _analytics.trackAction('account_security_reminder_shown');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Account Security'),
          ],
        ),
        content: const Text(
          'Keep your account secure:\n\n'
          '• Use a strong, unique password\n'
          '• Enable two-factor authentication\n'
          '• Review account activity regularly\n'
          '• Keep your app updated',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _analytics.trackAction('account_security_reminder_dismissed');
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _analytics.trackAction('account_security_reminder_accepted');
              Navigator.of(context).pop();
              // In a real app, this would navigate to security settings
            },
            child: const Text('Review Settings'),
          ),
        ],
      ),
    );
  }

  /// Show permission warning
  Future<void> showPermissionWarning(BuildContext context, String permission) async {
    if (!context.mounted || !_featureFlags.enableSecurityNotifications) return;

    await _analytics.trackAction('permission_warning_shown', parameters: {'permission': permission});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$permission permission is required for this feature to work properly.'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Grant',
          textColor: Colors.white,
          onPressed: () async {
            await _analytics.trackAction('permission_grant_requested', parameters: {'permission': permission});
            // In a real app, this would request the permission
          },
        ),
      ),
    );
  }

  /// Show data privacy notification
  Future<void> showDataPrivacyNotification(BuildContext context) async {
    if (!context.mounted || !_featureFlags.enableSecurityNotifications) return;

    await _analytics.trackAction('data_privacy_notification_shown');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Your privacy is important. Review our updated privacy policy.'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Review',
          textColor: Colors.white,
          onPressed: () async {
            await _analytics.trackAction('privacy_policy_review_requested');
            // In a real app, this would open the privacy policy
          },
        ),
      ),
    );
  }
}