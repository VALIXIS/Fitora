import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/app/router/startup_route_resolver.dart';
import 'package:fitora/features/auth/models/auth_status.dart';

void main() {
  test('first launch goes splash to onboarding to auth', () {
    expect(
      resolveStartupRoute(
        onboardingComplete: false,
        authComplete: false,
        personalizationComplete: false,
        authStatus: AuthStatus.unauthenticated,
      ),
      AppRoutes.onboarding,
    );

    expect(
      resolveStartupRoute(
        onboardingComplete: true,
        authComplete: false,
        personalizationComplete: false,
        authStatus: AuthStatus.unauthenticated,
      ),
      AppRoutes.auth,
    );
  });

  test('returning user goes splash to home', () {
    expect(
      resolveStartupRoute(
        onboardingComplete: true,
        authComplete: true,
        personalizationComplete: true,
        authStatus: AuthStatus.authenticated,
      ),
      AppRoutes.home,
    );
  });

  test('personalization missing routes to profile setup', () {
    expect(
      resolveStartupRoute(
        onboardingComplete: true,
        authComplete: true,
        personalizationComplete: false,
        authStatus: AuthStatus.guest,
      ),
      AppRoutes.profileSetup,
    );
  });
}
