import 'package:flutter/material.dart';

/// A reusable widget that moves its [child] back and forth horizontally.
class AnimatedActionWidget extends StatefulWidget {
  /// The widget to animate.
  final Widget child;

  /// Maximum horizontal offset. Defaults to 20 pixels.
  final double offset;

  /// Duration of one back‑and‑forth cycle. Defaults to 1 second.
  final Duration duration;

  const AnimatedActionWidget({
    super.key,
    required this.child,
    this.offset = 5,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  AnimatedActionWidgetState createState() => AnimatedActionWidgetState();
}

class AnimatedActionWidgetState extends State<AnimatedActionWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.offset,
      end: widget.offset,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
