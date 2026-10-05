import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/navigation/app_shell.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/app/router/startup_route_resolver.dart';
import 'package:fitora/features/splash/screens/splash_screen.dart';
import 'package:fitora/features/auth/models/auth_status.dart';
import 'package:fitora/features/auth/presentation/auth_email_screen.dart';
import 'package:fitora/features/auth/presentation/auth_screen.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/features/home/screens/home_screen.dart';
import 'package:fitora/features/onboarding/screens/onboarding_screen.dart';
import 'package:fitora/features/onboarding/providers/onboarding_controller.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/personalization/screens/personalization_flow_screen.dart';
import 'package:fitora/features/profile/screens/profile_screen.dart';
import 'package:fitora/features/progress/screens/progress_screen.dart';
import 'package:fitora/features/health_sync/screens/health_sync_screen.dart';
import 'package:fitora/features/settings/screens/settings_screen.dart';
import 'package:fitora/features/settings/screens/about_screen.dart';
import 'package:fitora/features/settings/screens/privacy_policy_screen.dart';
import 'package:fitora/features/settings/screens/terms_of_service_screen.dart';
import 'package:fitora/features/profile/screens/edit_profile_screen.dart';
import 'package:fitora/shared/screens/not_found_screen.dart';
import 'package:fitora/features/sleep/screens/sleep_detail_screen.dart';
import 'package:fitora/features/sleep/screens/sleep_schedule_screen.dart';
import 'package:fitora/features/sleep/screens/soundscapes_screen.dart';
import 'package:fitora/features/cycle/screens/cycle_dashboard_screen.dart';
import 'package:fitora/features/ai_coach/screens/ai_coach_screen.dart';
import 'package:fitora/features/gamification/screens/badges_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKeys = [
  GlobalKey<NavigatorState>(debugLabel: 'home'),
  GlobalKey<NavigatorState>(debugLabel: 'progress'),
  GlobalKey<NavigatorState>(debugLabel: 'profile'),
];

/// 60fps Fade-through transition for primary bottom shell navigation tabs
CustomTransitionPage<T> fadeThroughTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: RepaintBoundary(child: child),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      );
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInCubic),
      );
      final scaleIn = Tween<double>(begin: 0.97, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );

      return FadeTransition(
        opacity: fadeIn,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(fadeOut),
          child: ScaleTransition(
            scale: scaleIn,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
  );
}

/// 60fps Slide-up transition for modals, full screen dialogs, and detail views
CustomTransitionPage<T> slideUpTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: RepaintBoundary(child: child),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.2, 0.9, 0.3, 1.0), // Butter-smooth iOS spring curve
        ),
      );
      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );

      // Subtle parallax push for secondary outgoing route
      final secondarySlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.0, -0.02),
      ).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        ),
      );

      return SlideTransition(
        position: secondarySlide,
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
  );
}

/// 60fps Horizontal Shared Axis transition for deep nested screens
CustomTransitionPage<T> slideHorizontalTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: RepaintBoundary(child: child),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideIn = Tween<Offset>(
        begin: const Offset(0.08, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.2, 0.9, 0.3, 1.0),
        ),
      );
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      final slideOut = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.04, 0.0),
      ).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        ),
      );

      return SlideTransition(
        position: slideOut,
        child: FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: slideIn,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(onboardingControllerProvider, (_, _) => notifyListeners());
    ref.listen(personalizationControllerProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>(
  (ref) {
    final routerRefreshNotifier = _RouterRefreshNotifier(ref);
    ref.onDispose(routerRefreshNotifier.dispose);

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: kDebugMode,
      refreshListenable: routerRefreshNotifier,
      redirect: (context, state) {
        final location = state.matchedLocation;
        if (location == AppRoutes.splash) {
          return null;
        }
        final isAuthFlow =
            location == AppRoutes.auth || location == AppRoutes.authEmail;
        final isProfileSetup = location == AppRoutes.profileSetup;
        final onboardingState = ref.read(onboardingControllerProvider);
        final personalizationState = ref.read(personalizationControllerProvider);
        final authSession = ref.read(authStateProvider);

        if (onboardingState.isLoading ||
            personalizationState.isLoading ||
            authSession.isLoading) {
          return null;
        }

        if (location == AppRoutes.onboarding && !onboardingState.isCompleted) {
          return null;
        }

        if (!onboardingState.isCompleted) {
          return AppRoutes.onboarding;
        }

        final startupRoute = resolveStartupRoute(
          onboardingComplete: onboardingState.isCompleted,
          authComplete: authSession.status == AuthStatus.authenticated ||
              authSession.status == AuthStatus.guest,
          personalizationComplete: personalizationState.isCompleted,
          authStatus: authSession.status,
        );

        if (startupRoute != AppRoutes.home) {
          if (location == startupRoute ||
              (isAuthFlow && startupRoute == AppRoutes.auth) ||
              (isProfileSetup && startupRoute == AppRoutes.profileSetup)) {
            return null;
          }
          return startupRoute;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: AppRouteNames.onboarding,
          pageBuilder: (context, state) => slideUpTransitionPage(
            context: context,
            state: state,
            child: const OnboardingScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.auth,
          name: AppRouteNames.auth,
          pageBuilder: (context, state) => slideUpTransitionPage(
            context: context,
            state: state,
            child: const AuthScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.authEmail,
          name: AppRouteNames.authEmail,
          pageBuilder: (context, state) => slideUpTransitionPage(
            context: context,
            state: state,
            child: const AuthEmailScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profileSetup,
          name: AppRouteNames.profileSetup,
          pageBuilder: (context, state) => slideUpTransitionPage(
            context: context,
            state: state,
            child: const PersonalizationFlowScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.aiCoach,
          name: AppRouteNames.aiCoach,
          pageBuilder: (context, state) => slideUpTransitionPage(
            context: context,
            state: state,
            child: const AICoachScreen(),
          ),
        ),


        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeys[0],
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  name: AppRouteNames.home,
                  pageBuilder: (context, state) => fadeThroughTransitionPage(
                    context: context,
                    state: state,
                    child: const HomeScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeys[1],
              routes: [
                GoRoute(
                  path: AppRoutes.progress,
                  name: AppRouteNames.progress,
                  pageBuilder: (context, state) => fadeThroughTransitionPage(
                    context: context,
                    state: state,
                    child: const ProgressScreen(),
                  ),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AppRoutes.sleepDetail,
                      name: AppRouteNames.sleepDetail,
                      pageBuilder: (context, state) => slideHorizontalTransitionPage(
                        context: context,
                        state: state,
                        child: const SleepDetailScreen(),
                      ),
                      routes: [
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          path: AppRoutes.sleepSchedule,
                          name: AppRouteNames.sleepSchedule,
                          pageBuilder: (context, state) => slideHorizontalTransitionPage(
                            context: context,
                            state: state,
                            child: const SleepScheduleScreen(),
                          ),
                        ),
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          path: AppRoutes.soundscapes,
                          name: AppRouteNames.soundscapes,
                          pageBuilder: (context, state) => slideHorizontalTransitionPage(
                            context: context,
                            state: state,
                            child: const SoundscapesScreen(),
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AppRoutes.cycleDetail,
                      name: AppRouteNames.cycleDetail,
                      pageBuilder: (context, state) => slideHorizontalTransitionPage(
                        context: context,
                        state: state,
                        child: const CycleDashboardScreen(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeys[2],
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  name: AppRouteNames.profile,
                  pageBuilder: (context, state) => fadeThroughTransitionPage(
                    context: context,
                    state: state,
                    child: const ProfileScreen(),
                  ),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AppRoutes.healthSync,
                      name: AppRouteNames.healthSync,
                      pageBuilder: (context, state) => slideHorizontalTransitionPage(
                        context: context,
                        state: state,
                        child: const HealthSyncScreen(),
                      ),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AppRoutes.editProfile,
                      name: AppRouteNames.editProfile,
                      pageBuilder: (context, state) => slideHorizontalTransitionPage(
                        context: context,
                        state: state,
                        child: const EditProfileScreen(),
                      ),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AppRoutes.badges,
                      name: AppRouteNames.badges,
                      pageBuilder: (context, state) => slideHorizontalTransitionPage(
                        context: context,
                        state: state,
                        child: const BadgesScreen(),
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.settings,
                      name: AppRouteNames.settings,
                      pageBuilder: (context, state) => slideHorizontalTransitionPage(
                        context: context,
                        state: state,
                        child: const SettingsScreen(),
                      ),
                      routes: [
                        GoRoute(
                          path: AppRoutes.about,
                          name: AppRouteNames.about,
                          pageBuilder: (context, state) => slideHorizontalTransitionPage(
                            context: context,
                            state: state,
                            child: const AboutScreen(),
                          ),
                        ),
                        GoRoute(
                          path: AppRoutes.privacyPolicy,
                          name: AppRouteNames.privacyPolicy,
                          pageBuilder: (context, state) => slideHorizontalTransitionPage(
                            context: context,
                            state: state,
                            child: const PrivacyPolicyScreen(),
                          ),
                        ),
                        GoRoute(
                          path: AppRoutes.termsOfService,
                          name: AppRouteNames.termsOfService,
                          pageBuilder: (context, state) => slideHorizontalTransitionPage(
                            context: context,
                            state: state,
                            child: const TermsOfServiceScreen(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => const NotFoundScreen(),
    );
  },
);
