import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/fitora_spacing.dart';
import '../providers/wellness_provider.dart';

class WaterLoggingModal extends ConsumerStatefulWidget {
  const WaterLoggingModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WaterLoggingModal(),
    );
  }

  @override
  ConsumerState<WaterLoggingModal> createState() => _WaterLoggingModalState();
}

class _WaterLoggingModalState extends ConsumerState<WaterLoggingModal> {
  final TextEditingController _customController = TextEditingController();

  final List<int> _presets = [150, 250, 350, 500, 750, 1000];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _logAmount(int amountMl) {
    if (amountMl <= 0) return;
    ref.read(wellnessProvider.notifier).addWaterLogEntry(amountMl: amountMl);
  }

  void _submitCustom() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) {
      _logAmount(parsed);
      _customController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wellness = ref.watch(wellnessProvider);
    final tt = Theme.of(context).textTheme;

    final todayStr = () {
      final now = DateTime.now();
      return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }();

    final todayLogs = wellness.waterLogs.where((l) => l.dateStr == todayStr).toList();
    final totalMl = (wellness.hydrationLiters * 1000).round();
    final goalMl = (wellness.hydrationGoalLiters * 1000).round();
    final progress = wellness.hydrationGoalLiters > 0
        ? (wellness.hydrationLiters / wellness.hydrationGoalLiters).clamp(0.0, 1.0)
        : 0.0;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1226),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: FitoraSpacing.lg,
        right: FitoraSpacing.lg,
        top: FitoraSpacing.lg,
        bottom: FitoraSpacing.lg + bottomPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: FitoraSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Water Intake',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Track your daily hydration',
                          style: tt.bodySmall?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.lg),

            // Progress Summary Card
            Container(
              padding: const EdgeInsets.all(FitoraSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Total',
                            style: tt.labelSmall?.copyWith(color: Colors.white54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalMl ml',
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Daily Goal',
                            style: tt.labelSmall?.copyWith(color: Colors.white54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$goalMl ml',
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitoraSpacing.xl),

            // Preset Amounts Section
            Text(
              'QUICK PRESETS',
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: FitoraSpacing.sm),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((ml) {
                return InkWell(
                  onTap: () => _logAmount(ml),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$ml ml',
                          style: tt.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: FitoraSpacing.lg),

            // Custom Amount Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Custom amount (ml)',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitCustom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.xl),

            // Today's History
            Text(
              'TODAY\'S LOGS (${todayLogs.length})',
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: FitoraSpacing.sm),

            if (todayLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: FitoraSpacing.lg),
                child: Center(
                  child: Text(
                    'No water logged yet today.',
                    style: tt.bodySmall?.copyWith(color: Colors.white30),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayLogs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final log = todayLogs[index];
                  final hour = log.timestamp.hour == 0 ? 12 : (log.timestamp.hour > 12 ? log.timestamp.hour - 12 : log.timestamp.hour);
                  final amPm = log.timestamp.hour >= 12 ? 'PM' : 'AM';
                  final minute = log.timestamp.minute.toString().padLeft(2, '0');
                  final timeStr = '$hour:$minute $amPm';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop_outlined, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              '${log.amountMl} ml',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              timeStr,
                              style: tt.bodySmall?.copyWith(color: Colors.white38),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                ref.read(wellnessProvider.notifier).deleteWaterLogEntry(log.id);
                              },
                              tooltip: 'Delete entry',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
