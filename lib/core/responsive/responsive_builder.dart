import 'package:flutter/material.dart';
import 'package:fitora/core/responsive/breakpoints.dart';

class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= FitoraBreakpoints.desktop) {
          return (desktop ?? tablet ?? mobile)(context);
        }

        if (width >= FitoraBreakpoints.tablet) {
          return (tablet ?? mobile)(context);
        }

        return mobile(context);
      },
    );
  }
}
