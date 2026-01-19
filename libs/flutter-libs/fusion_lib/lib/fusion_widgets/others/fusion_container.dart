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
    final container = Container(
      width: width,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        // color: context.colorScheme.shadowDark,
        boxShadow: raised
            ? <BoxShadow>[
                BoxShadow(color: context.colorScheme.shadowLight.withAlpha((0.1 * 255).toInt()), blurRadius: 2, offset: const Offset(-2, -2)),
                BoxShadow(color: context.colorScheme.shadowDark.withValues(alpha: 0.84), blurRadius: 4, offset: const Offset(2, 2)),
                BoxShadow(color: color ?? context.colorScheme.elevation1),
              ]
            : <BoxShadow>[
                const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
                const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
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
