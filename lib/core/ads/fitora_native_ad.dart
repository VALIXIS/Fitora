import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fitora/core/ads/ad_service.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

/// A premium Native Advanced Ad Card matching Fitora's signature GlowContainer card design language.
class FitoraNativeAdCard extends StatefulWidget {
  const FitoraNativeAdCard({super.key});

  @override
  State<FitoraNativeAdCard> createState() => _FitoraNativeAdCardState();
}

class _FitoraNativeAdCardState extends State<FitoraNativeAdCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() async {
    await AdService.initialize();

    if (!mounted) return;

    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    _nativeAd?.dispose();
    _nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _retryCount = 0;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
          AppLogger.info(
              'Native ad failed to load: ${error.message} (code ${error.code})');

          if (_retryCount < 3 && mounted) {
            _retryCount++;
            Future.delayed(Duration(seconds: 3 * _retryCount), () {
              if (mounted) _loadNativeAd();
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: cardColor,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: FitoraColors.mintGreen,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: theme.colorScheme.onSurface,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: theme.colorScheme.onSurfaceVariant,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: theme.colorScheme.onSurfaceVariant,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: FitoraColors.mintGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'SPONSORED',
                    style: textTheme.labelSmall?.copyWith(
                      color: FitoraColors.mintGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.sm),
            SizedBox(
              height: 96,
              child: AdWidget(ad: _nativeAd!),
            ),
          ],
        ),
      ),
    );
  }
}
