import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final bool applyPadding;
  final bool safeArea;
  final bool scrollable;
  final Widget? bottomNavigationBar;
  final FloatingActionButton? floatingActionButton;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.appBar,
    this.actions,
    this.padding,
    this.applyPadding = true,
    this.safeArea = true,
    this.scrollable = false,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAppBar = appBar ??
        (title != null
            ? AppBar(
                title: Text(title!),
                actions: actions,
              )
            : null);

    Widget content = body;

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    if (applyPadding) {
      content = Padding(
        padding: padding ?? FitoraSpacing.pagePadding,
        child: content,
      );
    }

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      appBar: resolvedAppBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
