import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/startup_route_resolver.dart';
import 'package:fitora/core/constants/app_constants.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/auth/models/auth_status.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/features/onboarding/providers/onboarding_controller.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  Timer? _maxTimeoutTimer;

  @override
  void initState() {
    super.initState();
    
    // Ensure native Android/iOS splash screen is removed instantly on frame 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _startNavigationCheck();
    });

    // Hard fallback timeout (3 seconds) to guarantee user never gets stuck
    _maxTimeoutTimer = Timer(const Duration(milliseconds: 3000), () {
      _checkAndNavigate(force: true);
    });
  }

  @override
  void dispose() {
    _maxTimeoutTimer?.cancel();
    super.dispose();
  }

  void _startNavigationCheck() async {
    // Wait minimum duration for splash visual branding effect (1200ms)
    await Future.delayed(AppConstants.splashDelay);
    _checkAndNavigate();
  }

  void _checkAndNavigate({bool force = false}) {
    if (!mounted || _navigated) return;

    final onboardingState = ref.read(onboardingControllerProvider);
    final personalizationState = ref.read(personalizationControllerProvider);
    final authSession = ref.read(authStateProvider);

    // If any provider is still loading and not forced, retry shortly
    if (!force &&
        (onboardingState.isLoading ||
            personalizationState.isLoading ||
            authSession.isLoading)) {
      Future.delayed(const Duration(milliseconds: 200), () => _checkAndNavigate());
      return;
    }

    _navigated = true;

    final targetRoute = resolveStartupRoute(
      onboardingComplete: onboardingState.isCompleted,
      authComplete: authSession.status == AuthStatus.authenticated ||
          authSession.status == AuthStatus.guest,
      personalizationComplete: personalizationState.isCompleted,
      authStatus: authSession.status,
    );

    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: FitoraBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── Animated Brand Icon with Glowing Aura ───────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsating cyan/purple glow aura
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: FitoraColors.mintGreen.withValues(alpha: 0.35),
                            blurRadius: 50,
                            spreadRadius: 15,
                          ),
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1.15, 1.15),
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),

                    // Glassmorphic App Icon Frame
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icon_foreground.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 36),

                // ── Animated App Title ─────────────────────────────────────────
                Text(
                  'FITORA',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.0,
                        color: Colors.white,
                        fontSize: 32,
                        shadows: [
                          Shadow(
                            color: FitoraColors.mintGreen.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.4), delay: 300.ms),

                const SizedBox(height: 8),

                // Subtitle Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: FitoraColors.mintGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'AI HEALTH & WELLNESS ENGINE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: FitoraColors.mintGreen,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          fontSize: 10,
                        ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                const Spacer(flex: 2),

                // ── Glowing Progress Indicator & Status ────────────────────────
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FitoraColors.mintGreen,
                    ),
                    backgroundColor: Colors.white10,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 16),

                Text(
                  'Initializing step engine...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 400.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
