import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';

/// Orchestrates first-launch permission requests in a user-friendly, sequential flow.
class PermissionManager {
  static const _kPermissionsShownKey = 'fitora_permissions_shown';

  /// Returns true if the first-launch permission flow has already been shown.
  static Future<bool> wasPermissionsFlowShown() async {
    final prefs = await AppPreferences.instance();
    return prefs.getBool(_kPermissionsShownKey) ?? false;
  }

  /// Marks the first-launch permission flow as shown.
  static Future<void> markPermissionsFlowShown() async {
    final prefs = await AppPreferences.instance();
    await prefs.setBool(_kPermissionsShownKey, true);
  }

  /// Step 1 – Activity Recognition permission.
  /// Returns true if granted.
  static Future<bool> requestActivityRecognition() async {
    final result = await ph.Permission.activityRecognition.request();
    return result.isGranted;
  }

  /// Step 2 – Notification permission (Android 13+ / iOS).
  /// Returns true if granted.
  static Future<bool> requestNotifications() async {
    final svc = NotificationService();
    return await svc.requestPermissions();
  }

  /// Shows the sequential first-launch permission bottom sheet.
  /// Requests Activity Recognition first, then Notifications.
  /// Health Connect is handled separately when the user enters Health Sync.
  static Future<void> requestFirstLaunchPermissions(BuildContext context) async {
    if (!context.mounted) return;

    final alreadyShown = await wasPermissionsFlowShown();
    if (alreadyShown) return;

    await markPermissionsFlowShown();

    if (!context.mounted) return;
    await _showActivityRecognitionSheet(context);
  }

  static Future<void> _showActivityRecognitionSheet(BuildContext context) async {
    if (!context.mounted) return;

    final granted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _PermissionSheet(
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

    if (context.mounted && (granted ?? false)) {
      await requestActivityRecognition();
      if (context.mounted) {
        await _showNotificationSheet(context);
      }
    } else if (context.mounted) {
      // Skipped activity recognition – still offer notifications
      await _showNotificationSheet(context);
    }
  }

  static Future<void> _showNotificationSheet(BuildContext context) async {
    if (!context.mounted) return;

    // Check if permission already granted to avoid a redundant prompt
    final alreadyGranted = await ph.Permission.notification.isGranted;
    if (alreadyGranted) return;

    if (!context.mounted) return;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _PermissionSheet(
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

    if (context.mounted) {
      await requestNotifications();
    }
  }
}

// ── Permission Sheet Widget ───────────────────────────────────────────────────

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
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
              color: Colors.white24,
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
              border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
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
            style: tt.bodyMedium?.copyWith(color: Colors.white60, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Allow button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                allowLabel,
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Skip button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
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
