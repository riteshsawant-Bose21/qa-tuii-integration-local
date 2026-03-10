import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

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
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "neumorphic_container"),
      child: FusionContainer(
        borderRadius: radius,
        raised: !inner,
        
        child: child,
      ),
    );
  }
}
