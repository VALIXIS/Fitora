import 'package:flutter/material.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class AuthLoadingOverlay extends StatelessWidget {
  final String message;

  const AuthLoadingOverlay({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: colorScheme.scrim.withOpacity(0.28),
          child: Center(
            child: LoadingWidget(message: message),
          ),
        ),
      ),
    );
  }
}
