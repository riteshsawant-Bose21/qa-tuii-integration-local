import 'dart:math' as math;

import 'package:flutter/material.dart';

class GlobalLoader {
  GlobalLoader._internal();

  static final GlobalLoader _instance = GlobalLoader._internal();

  factory GlobalLoader() => _instance;

  OverlayEntry? _overlayEntry;

  bool get isShowing => _overlayEntry != null;

  void show(BuildContext context, {String? message}) {
    if (isShowing) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoaderWidget(message: message),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _LoaderWidget extends StatelessWidget {
  final String? message;

  const _LoaderWidget({this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArcLoader(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}


class ArcLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const ArcLoader({
    super.key,
    this.size = 60,
    this.strokeWidth = 6,
  });

  @override
  State<ArcLoader> createState() => _ArcLoaderState();
}

class _ArcLoaderState extends State<ArcLoader>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ArcPainter(
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double strokeWidth;

  _ArcPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [
        const Color(0xFF1E6F50),
        const Color(0xFF3FA77B),
        const Color(0xFF1E6F50),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw only part of circle (like your image)
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      math.pi * 1.4, // arc length
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}