import 'package:flutter/material.dart';

class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownTo;

  const ScaleOnPress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownTo = 0.95,
  });

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );

    // Premium iOS spring curve with quick compress and bouncy recovery
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownTo,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: const ElasticOutCurve(0.6),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasTap = widget.onTap != null;

    Widget current = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    current = Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: hasTap
          ? GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: current,
            )
          : current,
    );

    return current;
  }
}
