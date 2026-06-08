import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/providers/health_providers.dart';

/// ⚠️ TEMPORARY — Developer-only sensor debug panel.
/// Remove once on-device verification is confirmed.
class SensorDebugPanel extends ConsumerStatefulWidget {
  const SensorDebugPanel({super.key});

  @override
  ConsumerState<SensorDebugPanel> createState() => _SensorDebugPanelState();
}

class _SensorDebugPanelState extends ConsumerState<SensorDebugPanel> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 2 seconds so values update while walking
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        ref.invalidate(sensorDebugSnapshotProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sensorStatus = ref.watch(sensorStatusProvider);
    final liveSteps = ref.watch(liveStepsProvider);
    final debugAsync = ref.watch(sensorDebugSnapshotProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC00).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFFFCC00).withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bug_report_rounded, color: Color(0xFFFFCC00), size: 18),
                const SizedBox(width: 8),
                Text(
                  'SENSOR DEBUG  ⚠️ TEMP',
                  style: tt.labelSmall?.copyWith(
                    color: const Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => ref.invalidate(sensorDebugSnapshotProvider),
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFFFFCC00), size: 18),
                ),
              ],
            ),
          ),

          // Live Riverpod status row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                _debugRow(tt, 'Sensor Status (Provider)',
                    _sensorStatusLabel(sensorStatus), _sensorStatusColor(sensorStatus)),
                _divider(),
                liveSteps.when(
                  data: (steps) => _debugRow(tt, 'Live Steps (Provider)', '$steps steps',
                      FitoraColors.mintGreen),
                  loading: () =>
                      _debugRow(tt, 'Live Steps (Provider)', 'Waiting for sensor...', Colors.white38),
                  error: (e, _) =>
                      _debugRow(tt, 'Live Steps (Provider)', 'Error: $e', Colors.redAccent),
                ),
                _divider(),
              ],
            ),
          ),

          // Native plugin snapshot
          debugAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFCC00)),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Native plugin unavailable (running on non-Android or emulator)\n$e',
                  style: tt.bodySmall?.copyWith(color: Colors.white38, height: 1.4)),
            ),
            data: (snap) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _debugRow(tt, 'Sensor Hardware', snap.sensorAvailable ? 'Present ✓' : 'Not Found ✗',
                      snap.sensorAvailable ? FitoraColors.mintGreen : Colors.redAccent),
                  _divider(),
                  _debugRow(tt, 'Raw Sensor Value (cumulative)',
                      snap.rawSteps >= 0 ? '${snap.rawSteps} steps' : 'No reading yet', Colors.white70),
                  _divider(),
                  _debugRow(tt, 'Daily Baseline (boot offset)',
                      snap.baseline >= 0 ? '${snap.baseline} steps' : 'Not set', Colors.white70),
                  _divider(),
                  _debugRow(
                    tt,
                    'Today\'s Calculated Steps',
                    '${snap.todaySteps} steps  (raw - baseline = ${snap.rawSteps >= 0 && snap.baseline >= 0 ? snap.rawSteps - snap.baseline : '?'})',
                    snap.todaySteps > 0 ? FitoraColors.mintGreen : Colors.white54,
                  ),
                  _divider(),
                  _debugRow(
                    tt,
                    'Last Sensor Event',
                    snap.lastEventTime != null
                        ? _formatTime(snap.lastEventTime!)
                        : 'No events received yet',
                    Colors.white54,
                  ),
                  _divider(),
                  _debugRow(tt, 'Double Count Guard',
                      snap.todaySteps >= 0 ? 'OK — steps ≥ 0' : '⚠️ Negative value detected',
                      snap.todaySteps >= 0 ? FitoraColors.mintGreen : Colors.redAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugRow(TextTheme tt, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: tt.bodySmall?.copyWith(color: Colors.white54, height: 1.3)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(value,
                style: tt.bodySmall?.copyWith(
                    color: valueColor, fontWeight: FontWeight.bold, height: 1.3),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1);

  String _sensorStatusLabel(SensorStatus s) => switch (s) {
        SensorStatus.active => 'Active ✓',
        SensorStatus.permissionRequired => 'Permission Required',
        SensorStatus.unavailable => 'Unavailable',
        SensorStatus.unknown => 'Checking...',
      };

  Color _sensorStatusColor(SensorStatus s) => switch (s) {
        SensorStatus.active => FitoraColors.mintGreen,
        SensorStatus.permissionRequired => FitoraColors.warningOrange,
        SensorStatus.unavailable => Colors.white38,
        SensorStatus.unknown => Colors.white38,
      };

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
