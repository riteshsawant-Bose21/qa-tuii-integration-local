import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionFlatContainer extends StatelessWidget {
  const FusionFlatContainer({
    super.key,
    this.width,
    this.borderRadius = 12.0,
    required this.child,
    this.semanticsId,
    this.color,
    this.borderColor,
    this.height,
    this.alignment,
    this.padding,
    this.toolTip,
    this.margin,
  });
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final String? semanticsId;
  final String? toolTip;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "fusion_flat_container_${semanticsId ?? ""}"),
      child: Tooltip(
        message: toolTip ?? "",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: width,
            height: height,
            alignment: alignment,
            margin: margin ?? const EdgeInsets.all(2),
            padding: padding ?? EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color ?? context.colorScheme.elevation1,

              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor ?? context.colorScheme.elevation2, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
