import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.15, 0.5, 0.85],
              colors: [
                baseColor.withValues(alpha: 0.06),
                baseColor.withValues(alpha: 0.12),
                baseColor.withValues(alpha: 0.06),
              ],
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (value * 2 - 1), 0, 0);
  }
}
