import 'package:flutter/material.dart';

class DashboardScrollWrapper extends StatelessWidget {
  final Widget child;
  final double minWidth;

  const DashboardScrollWrapper({
    super.key,
    required this.child,
    this.minWidth = 1200, // Minimum width before scrolling starts
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // If screen is wider than minWidth, use screen width (fill).
        // If screen is narrower, use minWidth and allow scroll.
        final double contentWidth = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            // We need a constrained height to allow the inner Expanded
            // widgets to fill the vertical space of the screen.
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
