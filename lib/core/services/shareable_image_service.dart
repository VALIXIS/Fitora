import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:fitora/features/progress/domain/shareable_milestone_models.dart';
import 'package:fitora/features/progress/widgets/shareable_milestone_card.dart';

/// Service for generating high-resolution milestone PNG cards using RepaintBoundary
/// and sharing them via package:share_plus.
class ShareableImageService {
  /// Captures a [RepaintBoundary] as high-resolution PNG image byte buffer.
  static Future<Uint8List?> captureBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        AppLogger.error('ShareableImageService: RenderRepaintBoundary not found');
        return null;
      }
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      AppLogger.error('ShareableImageService captureBoundary error: $e', st);
      return null;
    }
  }

  /// Saves PNG bytes to temporary directory and invokes native share sheet.
  static Future<bool> shareImageBytes(
    Uint8List pngBytes, {
    required String fileName,
    String? shareText,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: shareText ?? 'Check out my milestone on Fitora! ⚡',
      );
      return result.status == ShareResultStatus.success;
    } catch (e, st) {
      AppLogger.error('ShareableImageService shareImageBytes error: $e', st);
      return false;
    }
  }

  /// Displays an interactive modal bottom sheet rendering the branded 9:16 milestone card
  /// inside a RepaintBoundary, allowing the user to preview and share it instantly.
  static Future<void> showMilestoneShareModal(
    BuildContext context,
    ShareableMilestoneData milestoneData,
  ) async {
    final boundaryKey = GlobalKey();

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1312),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        bool isSharing = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FitoraSpacing.lg,
                vertical: FitoraSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    Text(
                      'SHARE MILESTONE',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Instagram Story & WhatsApp Status Format (9:16)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                    const SizedBox(height: FitoraSpacing.xl),

                    // 9:16 Preview Wrapped in RepaintBoundary
                    Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: RepaintBoundary(
                          key: boundaryKey,
                          child: ShareableMilestoneCardWidget(
                            data: milestoneData,
                            width: 300.0, // Scaled preview width
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.xl),

                    // Share Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSharing
                            ? null
                            : () async {
                                setState(() => isSharing = true);
                                try {
                                  final pngBytes = await captureBoundary(
                                    boundaryKey,
                                    pixelRatio: 3.0,
                                  );
                                  if (pngBytes != null) {
                                    final success = await shareImageBytes(
                                      pngBytes,
                                      fileName:
                                          'fitora_milestone_${DateTime.now().millisecondsSinceEpoch}',
                                      shareText:
                                          'Smashed my fitness goal on Fitora! ⚡ #FitoraFitness #Milestone',
                                    );
                                    if (success && context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isSharing = false);
                                  }
                                }
                              },
                        icon: isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded, size: 22),
                        label: Text(
                          isSharing ? 'GENERATING IMAGE...' : 'SHARE TO STORY / STATUS',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FitoraColors.mintGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
