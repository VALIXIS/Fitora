import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/features/cloud_backup/providers/cloud_backup_providers.dart';
import 'package:fitora/features/cloud_backup/domain/cloud_backup_models.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';

Future<void> showCloudBackupModal(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CloudBackupModalContent(),
  );
}

class _CloudBackupModalContent extends ConsumerWidget {
  const _CloudBackupModalContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final authSession = ref.watch(authStateProvider);
    final backupState = ref.watch(cloudBackupSyncProvider);
    final backupNotifier = ref.read(cloudBackupSyncProvider.notifier);

    final user = authSession.user;
    final isAuthenticated = user != null && !user.isAnonymous;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161E1C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: FitoraColors.mintGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Backup & Restore',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAuthenticated
                          ? 'Syncing with ${user.email ?? user.displayName ?? "Account"}'
                          : 'Guest Mode (Local Backup)',
                      style: tt.bodySmall?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Backup Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: backupState.status == CloudBackupSyncStatus.syncing
                                ? FitoraColors.warningOrange
                                : backupState.status == CloudBackupSyncStatus.success
                                    ? FitoraColors.successGreen
                                    : FitoraColors.mintGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sync Status',
                          style: tt.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      backupState.status == CloudBackupSyncStatus.syncing
                          ? 'Syncing...'
                          : backupState.lastSyncTime != null
                              ? 'Last synced ${_formatTimeAgo(backupState.lastSyncTime!)}'
                              : 'Not synced yet',
                      style: tt.bodySmall?.copyWith(
                        color: FitoraColors.mintGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (backupState.lastError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    backupState.lastError!,
                    style: tt.bodySmall?.copyWith(color: FitoraColors.errorRed),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ScaleOnPress(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: FitoraColors.mintGreen.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: (backupState.status == CloudBackupSyncStatus.syncing || backupState.isRestoring)
                        ? null
                        : () async {
                            ref.read(hapticServiceProvider).buttonPress();
                            await backupNotifier.restoreData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cloud data restored successfully!')),
                              );
                            }
                          },
                    icon: backupState.isRestoring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: FitoraColors.mintGreen),
                          )
                        : const Icon(Icons.cloud_download_rounded, color: FitoraColors.mintGreen, size: 20),
                    label: Text(
                      backupState.isRestoring ? 'Restoring' : 'Restore',
                      style: const TextStyle(color: FitoraColors.mintGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ScaleOnPress(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: FitoraColors.mintGreen,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: (backupState.status == CloudBackupSyncStatus.syncing || backupState.isRestoring)
                        ? null
                        : () async {
                            ref.read(hapticServiceProvider).buttonPress();
                            await backupNotifier.syncNow();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cloud backup completed successfully!')),
                              );
                            }
                          },
                    icon: (backupState.status == CloudBackupSyncStatus.syncing && !backupState.isRestoring)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.cloud_upload_rounded, size: 20),
                    label: Text(
                      (backupState.status == CloudBackupSyncStatus.syncing && !backupState.isRestoring) ? 'Syncing' : 'Backup Now',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
