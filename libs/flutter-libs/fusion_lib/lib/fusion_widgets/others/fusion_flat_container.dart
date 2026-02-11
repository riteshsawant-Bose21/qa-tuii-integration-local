import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionFlatContainer extends StatelessWidget {
  const FusionFlatContainer({
    super.key,
    this.width,
    this.borderRadius = 12.0,
    required this.child,

    this.color,
    this.borderColor,
    this.height,
    this.alignment,
    this.padding,
  });
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: width,
      height: height,
      alignment: alignment,
      margin: const EdgeInsets.all(2),
      padding: padding ?? EdgeInsets.all(context.mediumGap),
      decoration: BoxDecoration(
        color: color ?? context.colorScheme.elevation1,

        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? context.colorScheme.textGrey, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
