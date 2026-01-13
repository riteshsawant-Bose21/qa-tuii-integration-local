import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/color_pallette.dart';

class FusionContainer extends StatelessWidget {
  const FusionContainer({super.key, this.width, this.borderRadius = 12.0, required this.child});
  final double? width;
  final double borderRadius;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
            const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
            const BoxShadow(color: FusionDarkColorPallette.dark70, blurRadius: 4, blurStyle: BlurStyle.inner),
          ],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      ),
    );
  }
}
