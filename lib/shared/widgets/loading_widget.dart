import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool center;
  final double indicatorSize;

  const LoadingWidget({
    super.key,
    this.message,
    this.center = true,
    this.indicatorSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: const CircularProgressIndicator(strokeWidth: 2.6),
        ),
        if (message != null) ...[
          const SizedBox(height: FitoraSpacing.sm),
          Text(
            message!,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (center) {
      return Center(child: content);
    }

    return content;
  }
}
