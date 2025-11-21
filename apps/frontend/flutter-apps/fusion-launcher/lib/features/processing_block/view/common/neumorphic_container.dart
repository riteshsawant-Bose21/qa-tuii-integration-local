import 'package:flutter/material.dart';

import 'neumorphic_button.dart';

class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    this.inner = false,
    required this.child,
  });
  final bool inner;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        boxShadow: getNeumorphismBoxShadows(inner: inner),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
