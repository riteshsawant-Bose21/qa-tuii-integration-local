import 'package:flutter/material.dart';

class FusionNeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed; // Optional: Makes it clickable

  const FusionNeumorphicContainer({
    super.key,
    required this.child,
    this.width = 28, // Default small size
    this.height = 28,
    this.borderRadius = 6,
    this.padding,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Theme Colors (Dark Neumorphism)
    const Color baseLightColor = Color(0xFF262626);
    const Color baseDarkColor = Color(0xFF1A1A1A);

    final Container container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // 1. Surface Gradient (Convex shape)
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[baseLightColor, baseDarkColor],
          stops: <double>[0.1, 0.9],
        ),
        boxShadow: <BoxShadow>[
          // 2. Deep Dark Shadow (Bottom-Right)
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(2.5, 2.5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          // 3. Sharp Light Highlight (Top-Left)
          BoxShadow(
            color: Colors.white.withOpacity(0.07),
            offset: const Offset(-1, -1),
            blurRadius: 1.5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(child: child),
    );

    // If an onPressed callback is provided, wrap in InkWell for taps
    if (onPressed != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: container,
        ),
      );
    }

    return container;
  }
}
