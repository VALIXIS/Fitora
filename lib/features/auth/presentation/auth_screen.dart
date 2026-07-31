import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    final errorMessage = actionState.error ??
        (authSession.status == AuthStatus.error ? authSession.message : null);

    final isBusy = actionState.isLoading;
    final activeAction = actionState.action;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _AuthBackground(),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: FitoraSpacing.pagePadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _AuthHeader(),
                            const SizedBox(height: FitoraSpacing.lg),
                            AuthSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AuthActionButton(
                                    label: 'Continue with Google',
                                    icon: Icons.g_mobiledata_rounded,
                                    style: AuthActionStyle.primary,
                                    isLoading: isBusy &&
                                        activeAction == AuthActionType.google,
                                    onPressed: isBusy
                                        ? null
                                        : () =>
                                            actionController.signInWithGoogle(),
                                  ),
                                  const SizedBox(height: FitoraSpacing.md),

                                  AuthActionButton(
                                    label: 'Continue as Guest',
                                    icon: Icons.person_outline,
                                    style: AuthActionStyle.subtle,
                                    isLoading: isBusy &&
                                        activeAction == AuthActionType.guest,
                                    onPressed: isBusy
                                        ? null
                                        : () => actionController
                                            .signInAnonymously(),
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
                            _AuthFooter(
                              messageColor: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (isBusy)
              const AuthLoadingOverlay(message: 'Connecting your account'),
          ],
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GlowContainer(
          glowColor: colorScheme.primary.withOpacity(0.2),
          padding: const EdgeInsets.all(FitoraSpacing.sm),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.all(FitoraSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: FitoraSpacing.md),
        Text(
          'Fitora',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FitoraSpacing.xs),
        Text(
          'Move with intention. Build momentum every day.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AuthFooter extends StatelessWidget {
  final Color messageColor;

  const _AuthFooter({required this.messageColor});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'By continuing, you agree to Fitora\'s',
          style: textTheme.bodySmall?.copyWith(color: messageColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FitoraSpacing.xs),
        Text(
          'Terms of Service and Privacy Policy.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FitoraSpacing.sm),
        Text(
          'We respect your privacy. You can upgrade to a full account anytime.',
          style: textTheme.bodySmall?.copyWith(color: messageColor),
          textAlign: TextAlign.center,
        ),
      ],
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
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(
              color: colorScheme.primary,
              size: 240,
              duration: const Duration(seconds: 8),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _GlowOrb(
              color: colorScheme.secondary,
              size: 210,
              duration: const Duration(seconds: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const _GlowOrb({
    required this.color,
    this.size = 220,
    this.duration = const Duration(seconds: 7),
  });

  @override
  State<_GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<_GlowOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.92 + (_animation.value * 0.06);
        final opacity = 0.2 + (_animation.value * 0.1);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.color.withOpacity(0.3),
              widget.color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}
