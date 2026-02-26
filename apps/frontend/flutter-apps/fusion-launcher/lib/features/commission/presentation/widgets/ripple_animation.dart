import 'package:flutter/material.dart';

// ==========================================
// UPDATED WIDGET WITH 'maxRadius'
// ==========================================

class NeumorphicRippleWidget extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final int ripplesCount;
  final Duration animationDuration;
  final double minRadius;
  final double maxRadius; // New Parameter

  const NeumorphicRippleWidget({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.ripplesCount = 5,
    this.animationDuration = const Duration(milliseconds: 3000),
    this.minRadius = 25,
    this.maxRadius = 150, // Default fixed distance
  });

  @override
  State<NeumorphicRippleWidget> createState() => _NeumorphicRippleWidgetState();
}

class _NeumorphicRippleWidgetState extends State<NeumorphicRippleWidget> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant NeumorphicRippleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeumorphicRipplePainter(
        _controller,
        backgroundColor: widget.backgroundColor,
        count: widget.ripplesCount,
        minRadius: widget.minRadius,
        maxRadius: widget.maxRadius, // Pass the new parameter
      ),
      child: widget.child,
    );
  }
}

class _NeumorphicRipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color backgroundColor;
  final int count;
  final double minRadius;
  final double maxRadius; // Received here

  _NeumorphicRipplePainter(
    this.animation, {
    required this.backgroundColor,
    required this.count,
    required this.minRadius,
    required this.maxRadius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    // We removed the dependency on size.width.
    // Now it uses the explicit maxRadius passed from the widget.

    for (int i = 0; i < count; i++) {
      final double progress = (animation.value + (i / count)) % 1.0;
      final double currentRadius = minRadius + (maxRadius - minRadius) * progress;
      final double opacity = 1.0 - progress;

      if (opacity > 0 && opacity <= 1) {
        // Stroke width gets thinner as it expands
        final double strokeWidth = 20.0 * (1 - progress * 0.5);

        // 1. Light Shadow (Top-Left)
        final Paint lightPaint =
            Paint()
              ..color = backgroundColor.withOpacity(opacity * 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawCircle(center.translate(-3, -3), currentRadius, lightPaint);

        // 2. Dark Shadow (Bottom-Right)
        final Paint darkPaint =
            Paint()
              ..color = Colors.black.withOpacity(opacity * 0.1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawCircle(center.translate(3, 3), currentRadius, darkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_NeumorphicRipplePainter oldDelegate) => true;
}
