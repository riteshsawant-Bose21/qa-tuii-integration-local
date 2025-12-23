import 'package:flutter/material.dart';

import 'neumorphic_button.dart';

class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    this.inner = false,
    required this.child,
    this.radius = 12,
  });
  final bool inner;
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        // color: const Color(0xFFF5F5F5),
        boxShadow: getNeumorphismBoxShadows(inner: inner, color: Colors.white),
        border: Border.all(color: Colors.grey.shade200),
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: <Color>[
        //     Colors.white.withValues(alpha: 0),
        //     Colors.white,
        //     Colors.red,
        //   ],
        //   // stops: <double>[0, 0.5, 0.75],
        // ),
        borderRadius: BorderRadius.circular(radius.toDouble()),
      ),
      child: child,
    );
  }
}
