import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/commission/presentation/widgets/ripple_animation.dart';
import 'package:fusion_lib/fusion_lib.dart';

class LoadingIndicator extends StatefulWidget {
  final IconData? icon;

  const LoadingIndicator({
    super.key,
    this.icon,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicRippleWidget(
      backgroundColor: context.colorScheme.primaryWhite,
      animationDuration: const Duration(seconds: 4),
      ripplesCount: 4,
      minRadius: 25,
      maxRadius: 200,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: context.colorScheme.elevation1.withAlpha((0.8 * 255).toInt()),
              offset: const Offset(-4, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          widget.icon ?? Icons.search,
          size: 24,
          color: context.colorScheme.primaryWhite,
        ),
      ),
    );
  }
}

class _LoadingCirclePainter extends CustomPainter {
  final Color color;

  _LoadingCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    // Draw arc (270 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start at top
      3.14159 * 1.5, // 270 degrees
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
