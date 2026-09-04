import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

export 'fitora_native_ad.dart';

class AdService {
  static const String _lastAdDateKey = 'fitora_last_daily_video_ad_date';

  // Production AdMob Ad Unit IDs
  static const String productionBannerAdUnitId = 'ca-app-pub-6059224677913709/5926741912';
  static const String productionInterstitialAdUnitId = 'ca-app-pub-6059224677913709/2861972172';
  static const String productionNativeAdUnitId = 'ca-app-pub-6059224677913709/5926741912';

  // Google Test Ad Unit IDs (Used in Debug mode to protect AdMob account)
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testNativeAdUnitIdAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String testNativeAdUnitIdIos = 'ca-app-pub-3940256099942544/3986624511';

  static String get bannerAdUnitId =>
      kDebugMode ? testBannerAdUnitId : productionBannerAdUnitId;

  static String get interstitialAdUnitId =>
      kDebugMode ? testInterstitialAdUnitId : productionInterstitialAdUnitId;

  static String get nativeAdUnitId => kDebugMode
      ? (defaultTargetPlatform == TargetPlatform.iOS
          ? testNativeAdUnitIdIos
          : testNativeAdUnitIdAndroid)
      : productionNativeAdUnitId;

  static bool _initialized = false;
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoading = false;

  /// Initializes Google Mobile Ads SDK
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      AppLogger.info('Google Mobile Ads initialized successfully.');
    } catch (e, stackTrace) {
      AppLogger.error('Google Mobile Ads initialization failed', stackTrace);
    }
  }

  /// Checks if daily skippable video ad should be shown (Once per calendar day)
  static Future<bool> shouldShowDailyVideoAd() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAdDate = prefs.getString(_lastAdDateKey);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (lastAdDate == todayStr) {
      return false; // Already shown today
    }
    return true;
  }

  /// Marks daily video ad as shown for today
  static Future<void> markDailyVideoAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_lastAdDateKey, todayStr);
  }

  /// Shows the once-daily skippable video ad on first launch of the day
  static Future<void> showDailyVideoAdIfEligible(BuildContext context) async {
    await initialize();

    final eligible = await shouldShowDailyVideoAd();
    if (!eligible) {
      AppLogger.info('Daily video ad skipped (already shown today).');
      return;
    }

    if (_isAdLoading) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isAdLoading = false;
          _interstitialAd = ad;

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              markDailyVideoAdShown();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isAdLoading = false;
            },
          );

          _interstitialAd!.show();
        },
        onAdFailedToLoad: (error) {
          _isAdLoading = false;
          AppLogger.info('Failed to load daily video ad: ${error.message}');
        },
      ),
    );
  }
}

/// A clean, premium Banner Ad Widget for Fitora screens
class FitoraBannerAd extends StatefulWidget {
  const FitoraBannerAd({super.key});

  @override
  State<FitoraBannerAd> createState() => _FitoraBannerAdState();
}

class _FitoraBannerAdState extends State<FitoraBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() async {
    await AdService.initialize();

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
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
          _bannerAd = null;
          AppLogger.info('Banner ad failed to load: ${error.message} (code ${error.code})');
          
          // Retry with exponential backoff if initial fill fails during AdMob warm-up
          if (_retryCount < 3 && mounted) {
            _retryCount++;
            Future.delayed(Duration(seconds: 3 * _retryCount), () {
              if (mounted) _loadBannerAd();
            });
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
