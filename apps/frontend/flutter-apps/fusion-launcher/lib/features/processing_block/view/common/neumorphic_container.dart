import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    this.inner = false,
    required this.child,
    this.radius = 12,
    required this.semanticId,
  });
  final bool inner;
  final String semanticId;
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "neumorphic_container${semanticId}",
      ),
      child: FusionContainer(
        borderRadius: radius,
        raised: !inner,

        child: child,
      ),
    );
  }
}
