import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/features/auth/models/auth_status.dart';

String resolveStartupRoute({
  required bool onboardingComplete,
  required bool authComplete,
  required bool personalizationComplete,
  required AuthStatus authStatus,
}) {
  final hasAuthAccess = authComplete ||
      authStatus == AuthStatus.authenticated ||
      authStatus == AuthStatus.guest;

  if (!onboardingComplete) {
    return AppRoutes.onboarding;
  }

  if (!hasAuthAccess) {
    return AppRoutes.auth;
  }

  if (!personalizationComplete) {
    return AppRoutes.profileSetup;
  }

  return AppRoutes.home;
}