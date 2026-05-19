import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/navigation/app_shell.dart';
import 'package:fitora/app/router/app_routes.dart';
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
import 'package:fitora/features/splash/screens/splash_screen.dart';
import 'package:fitora/features/wellness/screens/wellness_screen.dart';
import 'package:fitora/features/workouts/screens/workout_detail_screen.dart';
import 'package:fitora/features/workouts/session/screens/workout_session_screen.dart';
import 'package:fitora/features/workouts/screens/workouts_screen.dart';
import 'package:fitora/shared/screens/not_found_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKeys = [
  GlobalKey<NavigatorState>(debugLabel: 'home'),
  GlobalKey<NavigatorState>(debugLabel: 'workouts'),
  GlobalKey<NavigatorState>(debugLabel: 'progress'),
  GlobalKey<NavigatorState>(debugLabel: 'wellness'),
  GlobalKey<NavigatorState>(debugLabel: 'profile'),
];

final appRouterProvider = Provider<GoRouter>(
  (ref) {
    final authStatus =
        ref.watch(authStateProvider.select((state) => state.status));
    final onboardingIsLoading = ref.watch(
      onboardingControllerProvider.select((state) => state.isLoading),
    );
    final onboardingIsCompleted = ref.watch(
      onboardingControllerProvider.select((state) => state.isCompleted),
    );
    final personalizationIsLoading = ref.watch(
      personalizationControllerProvider.select((state) => state.isLoading),
    );
    final personalizationIsCompleted = ref.watch(
      personalizationControllerProvider.select((state) => state.isCompleted),
    );

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: kDebugMode,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isAuthFlow =
            location == AppRoutes.auth || location == AppRoutes.authEmail;
        final isProfileSetup = location == AppRoutes.profileSetup;

        if (location == AppRoutes.splash) {
          return null;
        }

        if (onboardingIsLoading ||
            personalizationIsLoading ||
            authStatus == AuthStatus.loading) {
          return null;
        }

        if (!onboardingIsCompleted) {
          return location == AppRoutes.onboarding
              ? null
              : AppRoutes.onboarding;
        }

        if (authStatus == AuthStatus.unauthenticated) {
          if (isAuthFlow) {
            return null;
          }
          if (isProfileSetup) {
            return AppRoutes.auth;
          }
          return AppRoutes.auth;
        }

        if (authStatus == AuthStatus.error) {
          return isAuthFlow ? null : AppRoutes.auth;
        }

        final isAllowed = authStatus == AuthStatus.authenticated ||
            authStatus == AuthStatus.guest;

        if (isAllowed && !personalizationIsCompleted) {
          return isProfileSetup ? null : AppRoutes.profileSetup;
        }

        if (isAllowed &&
            (isAuthFlow || location == AppRoutes.onboarding || isProfileSetup)) {
          return AppRoutes.home;
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
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.auth,
          name: AppRouteNames.auth,
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: AppRoutes.authEmail,
          name: AppRouteNames.authEmail,
          builder: (context, state) => const AuthEmailScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileSetup,
          name: AppRouteNames.profileSetup,
          builder: (context, state) => const PersonalizationFlowScreen(),
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
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: HomeScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeys[1],
              routes: [
                GoRoute(
                  path: AppRoutes.workouts,
                  name: AppRouteNames.workouts,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: WorkoutsScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: AppRoutes.workoutDetail,
                      name: AppRouteNames.workoutDetail,
                      builder: (context, state) {
                        final id = state.pathParameters['id'] ?? '';
                        return WorkoutDetailScreen(workoutId: id);
                      },
                    ),
                    GoRoute(
                      path: AppRoutes.workoutSession,
                      name: AppRouteNames.workoutSession,
                      builder: (context, state) {
                        final id = state.pathParameters['id'] ?? '';
                        return WorkoutSessionScreen(workoutId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeys[2],
              routes: [
                GoRoute(
                  path: AppRoutes.progress,
                  name: AppRouteNames.progress,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ProgressScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeys[3],
              routes: [
                GoRoute(
                  path: AppRoutes.wellness,
                  name: AppRouteNames.wellness,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: WellnessScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeys[4],
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  name: AppRouteNames.profile,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ProfileScreen(),
                  ),
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
