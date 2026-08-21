import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/utils/app_logger.dart';

/// Orchestrates first-launch permission requests in a user-friendly, sequential flow.
class PermissionManager {
  static const _kPermissionsShownKey = 'fitora_permissions_shown';

  /// Returns true if the first-launch permission flow has already been shown.
  static Future<bool> wasPermissionsFlowShown() async {
    final prefs = await AppPreferences.instance();
    final val = prefs.getBool(_kPermissionsShownKey) ?? false;
    AppLogger.info('[PM] wasPermissionsFlowShown: $val');
    return val;
  }

  /// Marks the first-launch permission flow as shown.
  static Future<void> markPermissionsFlowShown() async {
    AppLogger.info('[PM] markPermissionsFlowShown: writing true to prefs');
    final prefs = await AppPreferences.instance();
    await prefs.setBool(_kPermissionsShownKey, true);
    AppLogger.info('[PM] markPermissionsFlowShown: done');
  }

  /// Shows the sequential first-launch permission bottom sheets.
  /// Requests Activity Recognition first, then Notifications.
  static Future<void> requestFirstLaunchPermissions(
    BuildContext context,
    WidgetRef ref,
  ) async {
    AppLogger.info('[PM] requestFirstLaunchPermissions: called');
    if (!context.mounted) return;

    final alreadyShown = await wasPermissionsFlowShown();
    if (alreadyShown) {
      AppLogger.info('[PM] requestFirstLaunchPermissions: already shown – aborting');
      return;
    }

    if (!context.mounted) return;
    await _showActivityRecognitionSheet(context, ref);
  }

  // ── Step 1: Activity Recognition ─────────────────────────────────────────────

  static Future<void> _showActivityRecognitionSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    AppLogger.info('[PM] _showActivityRecognitionSheet: checking existing grant');
    if (!context.mounted) return;

    final alreadyGranted = await ph.Permission.activityRecognition.isGranted;
    AppLogger.info('[PM] activityRecognition.isGranted=$alreadyGranted');
    if (!context.mounted) return;

    if (alreadyGranted) {
      AppLogger.info('[PM] activity recognition already granted – going to notifications');
      await _showNotificationSheet(context, ref);
      return;
    }

    AppLogger.info('[PM] showing Step Tracking custom sheet');
    final userTappedAllow = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _PermissionSheet(
        icon: Icons.directions_walk_rounded,
        iconColor: Color(0xFF06B6D4),
        title: 'Step Tracking',
        description:
            'Fitora uses your device\'s step counter to track your daily activity in real time. This keeps your fitness data accurate even when your phone is in your pocket.',
        permissionLabel: 'Activity Recognition',
        allowLabel: 'Allow Step Tracking',
        skipLabel: 'Not now',
      ),
    );

    // Sheet is now FULLY CLOSED – safe to call native dialog
    AppLogger.info('[PM] Step Tracking sheet closed, userTappedAllow=$userTappedAllow');
    if (userTappedAllow == true) {
      AppLogger.info('[PM] Requesting Activity Recognition native dialog...');
      await ref.read(sensorStatusProvider.notifier).requestPermission();
      AppLogger.info('[PM] Activity Recognition request completed');
    }

    if (context.mounted) {
      await _showNotificationSheet(context, ref);
    }
  }

  // ── Step 2: Notifications ─────────────────────────────────────────────────────

  static Future<void> _showNotificationSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    AppLogger.info('[PM] _showNotificationSheet: checking existing grant');
    if (!context.mounted) return;

    final alreadyGranted = await ph.Permission.notification.isGranted;
    AppLogger.info('[PM] notification.isGranted=$alreadyGranted');
    if (alreadyGranted) {
      AppLogger.info('[PM] notification already granted – saving & finishing');
      await ref
          .read(settingsProvider.notifier)
          .updateSetting('notificationsEnabled', true);
      await markPermissionsFlowShown();
      return;
    }

    if (!context.mounted) return;

    AppLogger.info('[PM] showing Stay on Track custom sheet');
    final userTappedAllow = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Allow drag/dismiss so the user is NEVER stuck if something goes wrong
      isDismissible: true,
      enableDrag: true,
      builder: (_) => const _PermissionSheet(
        icon: Icons.notifications_active_rounded,
        iconColor: Color(0xFF8B5CF6),
        title: 'Stay on Track',
        description:
            'Fitora can send you friendly hydration reminders and daily goal check-ins. You can customize or turn these off anytime in Settings.',
        permissionLabel: 'Notifications',
        allowLabel: 'Allow Notifications',
        skipLabel: 'Maybe later',
      ),
    );

    // Sheet is now FULLY CLOSED – the activity is topmost and focused again
    AppLogger.info('[PM] Stay on Track sheet closed, userTappedAllow=$userTappedAllow');

    bool notificationGranted = false;
    if (userTappedAllow == true) {
      AppLogger.info('[PM] Requesting POST_NOTIFICATIONS native dialog...');
      final status = await ph.Permission.notification.request();
      notificationGranted = status.isGranted;
      AppLogger.info('[PM] POST_NOTIFICATIONS result: $status, granted=$notificationGranted');

      // Initialise notification channels after permission is granted
      if (notificationGranted) {
        final svc = NotificationService();
        await svc.initialize();
        AppLogger.info('[PM] NotificationService initialized after grant');
      }
    } else {
      AppLogger.info('[PM] User skipped notification permission');
    }

    if (context.mounted) {
      await ref
          .read(settingsProvider.notifier)
          .updateSetting('notificationsEnabled', notificationGranted);
    }

    // Mark as completed AFTER the full flow so Home screen never re-triggers
    await markPermissionsFlowShown();
    AppLogger.info('[PM] Permission flow marked as completed');
  }
}

// ── Permission Sheet Widget ────────────────────────────────────────────────────

class _PermissionSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String permissionLabel;
  final String allowLabel;
  final String skipLabel;

  const _PermissionSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.permissionLabel,
    required this.allowLabel,
    required this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Permission badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              permissionLabel,
              style: tt.labelSmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: tt.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Allow button – pops the sheet with true; native dialog fires AFTER sheet closes
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                allowLabel,
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Skip button – pops the sheet with false
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(skipLabel, style: tt.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}
