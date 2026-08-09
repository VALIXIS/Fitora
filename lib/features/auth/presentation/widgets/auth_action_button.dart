import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

enum AuthActionStyle { primary, secondary, subtle }

class AuthActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final AuthActionStyle style;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const AuthActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.style = AuthActionStyle.primary,
    this.isLoading = false,
    this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedOnPressed = isLoading ? null : onPressed;
    final button = _buildButton(resolvedOnPressed);

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }

  Widget _buildButton(VoidCallback? onPressed) {
    final iconWidget = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Icon(icon, size: 20);

    switch (style) {
      case AuthActionStyle.primary:
        return FilledButton.icon(
          onPressed: onPressed,
          icon: iconWidget,
          label: _LabelText(text: label),
        );
      case AuthActionStyle.secondary:
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: iconWidget,
          label: _LabelText(text: label),
        );
      case AuthActionStyle.subtle:
        return TextButton.icon(
          onPressed: onPressed,
          icon: iconWidget,
          label: _LabelText(text: label),
        );
    }
  }
}

class _LabelText extends StatelessWidget {
  final String text;

  const _LabelText({required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitoraSpacing.xs),
      child: Text(
        text,
        style: textTheme.labelLarge,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
