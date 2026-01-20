import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionContainer extends StatelessWidget {
  const FusionContainer({
    super.key,
    this.width,
    this.borderRadius = 12.0,
    required this.child,
    this.raised = false,
    this.color,
  });
  final double? width;
  final double borderRadius;
  final Widget child;
  final bool raised;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        // color: context.colorScheme.shadowDark,
        boxShadow: raised
            ? <BoxShadow>[
                BoxShadow(color: context.colorScheme.shadowLight, blurRadius: 2, offset: const Offset(-2, -2)),
                BoxShadow(color: context.colorScheme.shadowDark, blurRadius: 4, offset: const Offset(2, 2)),
                BoxShadow(color: color ?? context.colorScheme.elevation1),
              ]
            : <BoxShadow>[
                BoxShadow(color: context.colorScheme.shadowDark, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
                BoxShadow(
                  color: context.colorScheme.shadowLight,
                  blurRadius: 1,
                  offset: Offset(2, 2),
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(color: color ?? context.colorScheme.elevation1, blurRadius: 4, blurStyle: BlurStyle.inner),
              ],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );

    if (raised) {
      return container;
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }
  }
}
