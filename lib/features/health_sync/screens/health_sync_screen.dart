import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import '../domain/health_sync_models.dart';
import '../providers/health_sync_provider.dart';
import '../services/pedometer_service.dart';

class HealthSyncScreen extends ConsumerWidget {
  const HealthSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthSyncProvider);
    final controller = ref.read(healthSyncProvider.notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final isSyncing = state.isSyncing;
    final cached = state.cachedData;

    // Supported integrations filtered automatically per platform
    final supportedSources = HealthSource.getSupportedSources();

    return AppScaffold(
      title: 'Health Integration',
      actions: [
        IconButton(
          icon: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.sync_rounded),
          tooltip: 'Sync Now',
          onPressed: isSyncing ? null : () => controller.syncAllActive(),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Live Sync Status Hub ──────────────────────────────────────────
            _SyncStatusHub(
              isSyncing: isSyncing,
              cachedData: cached,
              onSyncPressed: () => controller.syncAllActive(),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.05, end: 0, duration: 400.ms),

            const SizedBox(height: FitoraSpacing.md),

            // ── Live Activity Walk Simulator ──────────────────────────────────
            const _LiveActivitySimulator()
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.05, end: 0, duration: 350.ms),

            const SizedBox(height: FitoraSpacing.lg),

            // ── Connected Sources Section ─────────────────────────────────────
            Text(
              'Connected Sources',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: FitoraSpacing.xs),
            Text(
              'Supported health sources are detected automatically for your device.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ).animate().fadeIn(delay: 170.ms),
            const SizedBox(height: FitoraSpacing.sm),

            ...supportedSources.map((src) {
              final conn = state.connections[src] ?? HealthSourceConnectionState(source: src);
              return _HealthSourceCard(
                connection: conn,
                isSyncing: isSyncing,
                onToggle: () => controller.toggleSourceConnection(src),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.05, end: 0, duration: 350.ms);
            }),

            const SizedBox(height: FitoraSpacing.lg),

            // ── Background Preferences ────────────────────────────────────────
            Text(
              'Effortless Synchronization',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: FitoraSpacing.sm),

            FitoraCard(
              child: SwitchListTile(
                activeThumbColor: FitoraColors.mintGreen,
                title: const Text('Invisible Syncing'),
                subtitle: const Text('Silently keep steps and activity synchronized in the background.'),
                value: state.isBackgroundSyncEnabled,
                onChanged: (v) => controller.toggleBackgroundSync(v),
              ),
            )
                .animate()
                .fadeIn(delay: 280.ms),

            const SizedBox(height: FitoraSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Live Sync Status Hub ──────────────────────────────────────────────────────

class _SyncStatusHub extends StatelessWidget {
  final bool isSyncing;
  final HealthMetricData cachedData;
  final VoidCallback onSyncPressed;

  const _SyncStatusHub({
    required this.isSyncing,
    required this.cachedData,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlowContainer(
      glowColor: (isSyncing ? FitoraColors.calmCyan : FitoraColors.mintGreen).withValues(alpha: 0.16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSyncing ? 'Syncing health data…' : 'Health Sync Active',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last updated: ${_formatDateTime(cachedData.timestamp)}',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              _SyncSpinnerGlow(isSyncing: isSyncing, onSyncPressed: onSyncPressed),
            ],
          ),
          const SizedBox(height: FitoraSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: FitoraSpacing.md),

          // Dashboard Reading Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SyncStatItem(
                icon: Icons.directions_walk_rounded,
                label: 'Steps',
                value: '${cachedData.steps}',
                color: FitoraColors.mintGreen,
              ),
              _SyncStatItem(
                icon: Icons.favorite_rounded,
                label: 'Heart Rate',
                value: cachedData.heartRate > 0 ? '${cachedData.heartRate.round()} bpm' : '--',
                color: FitoraColors.softPink,
              ),
              _SyncStatItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories',
                value: cachedData.activeCalories > 0 ? '${cachedData.activeCalories.round()} kcal' : '--',
                color: FitoraColors.warmCoral,
              ),
              _SyncStatItem(
                icon: Icons.nights_stay_rounded,
                label: 'Sleep',
                value: cachedData.sleepHours > 0 ? '${cachedData.sleepHours.toStringAsFixed(1)}h' : '--',
                color: FitoraColors.lavender,
              ),
            ],
          ),
          if (cachedData.workouts.isNotEmpty) ...[
            const SizedBox(height: FitoraSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: FitoraSpacing.sm),
            Row(
              children: [
                Icon(Icons.fitness_center_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Synced: ${cachedData.workouts.first.title}',
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${cachedData.workouts.first.durationMinutes}m | ${cachedData.workouts.first.caloriesBurned} kcal',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return 'Today at $hour:$min';
  }
}

class _SyncStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SyncStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(FitoraSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 6),
        Text(value, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
      ],
    );
  }
}

class _SyncSpinnerGlow extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback onSyncPressed;

  const _SyncSpinnerGlow({required this.isSyncing, required this.onSyncPressed});

  @override
  Widget build(BuildContext context) {
    final ringColor = isSyncing ? FitoraColors.calmCyan : FitoraColors.mintGreen;

    return GestureDetector(
      onTap: isSyncing ? null : onSyncPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ringColor.withValues(alpha: 0.1),
          border: Border.all(color: ringColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Center(
          child: Icon(
            isSyncing ? Icons.hourglass_empty_rounded : Icons.sync_rounded,
            color: ringColor,
            size: 24,
          )
              .animate(onPlay: (c) => isSyncing ? c.repeat() : c.stop())
              .rotate(duration: 1.5.seconds, curve: Curves.linear),
        ),
      ),
    );
  }
}

// ── Connected Sources Card ────────────────────────────────────────────────────

class _HealthSourceCard extends StatelessWidget {
  final HealthSourceConnectionState connection;
  final bool isSyncing;
  final VoidCallback onToggle;

  const _HealthSourceCard({
    required this.connection,
    required this.isSyncing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final src = connection.source;

    Color brandColor;
    switch (src) {
      case HealthSource.googleFit:
        brandColor = const Color(0xFFEA4335);
        break;
      case HealthSource.healthConnect:
        brandColor = const Color(0xFF3DDC84);
        break;
      case HealthSource.samsungHealth:
        brandColor = const Color(0xFF0A70F5);
        break;
      case HealthSource.appleHealth:
        brandColor = const Color(0xFFFF2D55);
        break;
    }

    IconData brandIcon;
    switch (src) {
      case HealthSource.googleFit:
        brandIcon = Icons.fitness_center_rounded;
        break;
      case HealthSource.healthConnect:
        brandIcon = Icons.android_rounded;
        break;
      case HealthSource.samsungHealth:
        brandIcon = Icons.directions_run_rounded;
        break;
      case HealthSource.appleHealth:
        brandIcon = Icons.favorite_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: FitoraSpacing.md),
      child: FitoraCard(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brandColor, brandColor.withValues(alpha: 0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(brandIcon, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    src.label,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    src.description,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (connection.isConnected) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FitoraColors.mintGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Authorized & Syncing',
                          style: tt.labelSmall?.copyWith(
                            color: FitoraColors.mintGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: FitoraSpacing.sm),
            Switch(
              activeThumbColor: brandColor,
              value: connection.isConnected,
              onChanged: isSyncing ? null : (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live Activity Walk Simulator Widget ───────────────────────────────────────

class _LiveActivitySimulator extends StatefulWidget {
  const _LiveActivitySimulator();

  @override
  State<_LiveActivitySimulator> createState() => _LiveActivitySimulatorState();
}

class _LiveActivitySimulatorState extends State<_LiveActivitySimulator> {
  Timer? _ticker;
  bool _isWalking = false;

  @override
  void initState() {
    super.initState();
    _isWalking = PedometerService().isWalking;
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        final currentWalking = PedometerService().isWalking;
        if (_isWalking != currentWalking) {
          setState(() {
            _isWalking = currentWalking;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(healthSyncProvider);
        final hasActiveConnection = state.connections.values.any(
          (c) => c.isConnected && c.permissionStatus == HealthPermissionStatus.authorized,
        );

        if (!hasActiveConnection) {
          return Container(
            padding: const EdgeInsets.all(FitoraSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Connect a health source below to enable real-time walking and step tracking.',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(FitoraSpacing.md),
          decoration: BoxDecoration(
            color: (_isWalking ? FitoraColors.mintGreen : Colors.white).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (_isWalking ? FitoraColors.mintGreen : Colors.white).withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (_isWalking ? FitoraColors.mintGreen : Colors.white).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _isWalking ? Icons.directions_walk_rounded : Icons.boy_rounded,
                    color: _isWalking ? FitoraColors.mintGreen : Colors.white70,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isWalking ? 'Active Walking Session' : 'Step Counter Standby',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isWalking ? 'Counting steps in real-time…' : 'Tap to start live walking test.',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isWalking ? FitoraColors.softPink.withValues(alpha: 0.15) : FitoraColors.mintGreen,
                  foregroundColor: _isWalking ? FitoraColors.softPink : Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  _isWalking ? Icons.pause_rounded : Icons.directions_run_rounded,
                  size: 16,
                ),
                label: Text(
                  _isWalking ? 'Stop' : 'Start',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  PedometerService().toggleWalkSimulation();
                  setState(() {
                    _isWalking = PedometerService().isWalking;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
