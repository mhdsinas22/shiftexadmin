import 'package:flutter/material.dart';

/// Shares a single repeating shimmer gradient animation across descendant
/// [ShimmerBoxWidget] placeholders so every bone sweeps in unison.
class ShimmerScopeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerScopeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerScopeWidget> createState() => _ShimmerScopeWidgetState();
}

class _ShimmerScopeWidgetState extends State<ShimmerScopeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShimmerScopeProvider(
          progress: _controller.value,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerScopeProvider extends InheritedWidget {
  final double progress;

  const ShimmerScopeProvider({
    super.key,
    required this.progress,
    required super.child,
  });

  static double of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ShimmerScopeProvider>();
    return provider?.progress ?? 0.5;
  }

  @override
  bool updateShouldNotify(ShimmerScopeProvider oldWidget) {
    return oldWidget.progress != progress;
  }
}

/// Reusable shimmer skeleton placeholder matching the ShiftEx slate surface palette.
class ShimmerBoxWidget extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBoxWidget({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ShimmerScopeProvider.of(context);
    final slide = (progress * 3.0) - 1.5;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(slide - 1.0, -0.2),
          end: Alignment(slide + 1.0, 0.2),
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        ),
      ),
    );
  }
}
