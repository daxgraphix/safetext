import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class GlowContainer extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final bool animate;
  final bool hasBorder;

  const GlowContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.borderRadius = AppRadius.sm,
    this.animate = true,
    this.hasBorder = true,
  });

  @override
  State<GlowContainer> createState() => _GlowContainerState();
}

class _GlowContainerState extends State<GlowContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.hasBorder 
              ? Border.all(color: scheme.onSurface, width: 2.0)
              : null,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.2 * (widget.animate ? _controller.value : 1.0)),
                blurRadius: 12 * (widget.animate ? _controller.value : 1.0),
                spreadRadius: 2 * (widget.animate ? _controller.value : 1.0),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
