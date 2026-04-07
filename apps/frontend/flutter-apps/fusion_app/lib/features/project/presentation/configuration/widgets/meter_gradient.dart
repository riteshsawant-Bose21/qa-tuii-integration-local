import 'package:flutter/material.dart';

class MeterGradient extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const MeterGradient({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter, // 0deg
          end: Alignment.topCenter,
          colors: [
            Color(0xFF2F7554), // Green
            Color(0xFFFAB62E), // Yellow
            Color(0xFFD03B1E), // Red
          ],
          stops: [
            0.0,
            0.5029, // 50.29%
            1.0,
          ],
        ),
      ),
    );
  }
}
