import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionSvgIcon extends StatelessWidget {
  final String icon;
  final Color? color;
  final double? size;
  final BoxFit fit;
  final String? semanticId;

  const FusionSvgIcon({
    this.semanticId,
    super.key,
    required this.icon,
    this.color,
    this.size,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        "fusion_svg_icon_${semanticId ?? ""}",
      ),
      child: SvgPicture.asset(
        icon,
        height: size,
        fit: fit,
        // ignore: deprecated_member_use
        color: color,
      ),
    );
  }
}
