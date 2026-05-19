import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/auth/models/auth_action_state.dart';
import 'package:fitora/features/auth/models/auth_status.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/features/auth/presentation/widgets/auth_action_button.dart';
import 'package:fitora/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:fitora/features/auth/presentation/widgets/auth_loading_overlay.dart';
import 'package:fitora/features/auth/presentation/widgets/auth_section_card.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authStateProvider);
    final actionState = ref.watch(authActionProvider);
    final actionController = ref.read(authActionProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final errorMessage = actionState.error ??
        (authSession.status == AuthStatus.error ? authSession.message : null);

    final isBusy = actionState.isLoading;
    final activeAction = actionState.action;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _AuthBackground(),
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: FitoraSpacing.pagePadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlowContainer(
                        glowColor: colorScheme.primary.withOpacity(0.16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Fitora',
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: FitoraSpacing.sm),
                            Text(
                              'Build gentle habits, track your progress, and feel better every day.',
                              style: textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FitoraSpacing.lg),
                      AuthSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthActionButton(
                              label: 'Continue with Google',
                              icon: Icons.g_mobiledata_rounded,
                              style: AuthActionStyle.primary,
                              isLoading:
                                  isBusy && activeAction == AuthActionType.google,
                              onPressed: isBusy
                                  ? null
                                  : () => actionController.signInWithGoogle(),
                            ),
                            const SizedBox(height: FitoraSpacing.md),
                            AuthActionButton(
                              label: 'Continue with Email',
                              icon: Icons.mail_outline,
                              style: AuthActionStyle.secondary,
                              isLoading:
                                  isBusy && activeAction == AuthActionType.email,
                              onPressed: isBusy
                                  ? null
                                  : () => context.push(AppRoutes.authEmail),
                            ),
                            const SizedBox(height: FitoraSpacing.md),
                            AuthActionButton(
                              label: 'Continue as Guest',
                              icon: Icons.person_outline,
                              style: AuthActionStyle.subtle,
                              isLoading:
                                  isBusy && activeAction == AuthActionType.guest,
                              onPressed: isBusy
                                  ? null
                                  : () => actionController.signInAnonymously(),
                            ),
                          ],
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: FitoraSpacing.md),
                        AuthErrorBanner(
                          message: errorMessage,
                          onDismiss: actionController.clearError,
                        ),
                      ],
                      const SizedBox(height: FitoraSpacing.lg),
                      Text(
                        'We respect your privacy. You can upgrade to a full account anytime.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isBusy)
              const AuthLoadingOverlay(message: 'Connecting your account'),
          ],
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.background,
                  colorScheme.surfaceVariant.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(color: colorScheme.primary),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _GlowOrb(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;

  const _GlowOrb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}
