import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';
//
// class FusionSvgIcon extends StatelessWidget {
//   final String icon;
//   final Color? color;
//   final double? size;
//   final BoxFit fit;
//   final String? semanticId;
//
//   const FusionSvgIcon({
//     this.semanticId,
//     super.key,
//     required this.icon,
//     this.color,
//     this.size,
//     this.fit = BoxFit.contain,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SemanticHelper.container(
//       testId: SemanticHelper.createTestId(
//         SemanticTypes.section,
//         "fusion_svg_icon_${semanticId ?? ""}",
//       ),
//       child: SvgPicture.asset(
//         icon,
//         height: size,
//         fit: fit,
//         // ignore: deprecated_member_use
//         color: color,
//       ),
//     );
//   }
// }
//
//

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionIcon extends StatelessWidget {
  /// Material icon
  final IconData? icon;

  /// SVG asset path
  final String? svg;

  /// Color of icon
  final Color? color;

  /// Size of icon
  final double? size;

  /// How SVG should fit
  final BoxFit fit;

  /// Semantic id for testing/accessibility
  final String semanticId;

  /// Private main constructor
  const FusionIcon._({
    super.key,
    this.icon,
    this.svg,
    this.color,
    this.size,
    this.fit = BoxFit.contain,
    required this.semanticId,
  });

  /// Material icon
  factory FusionIcon.icon(
    IconData icon, {
    Key? key,
    Color? color,
    double? size,
    required String semanticId,
  }) {
    return FusionIcon._(
      key: key,
      icon: icon,
      color: color,
      size: size,
      semanticId: semanticId,
    );
  }

  /// SVG asset icon
  factory FusionIcon.svg(
    String assetPath, {
    Key? key,
    Color? color,
    double? size,
    BoxFit fit = BoxFit.contain,
    required String semanticId,
  }) {
    return FusionIcon._(
      key: key,
      svg: assetPath,
      color: color,
      size: size,
      fit: fit,
      semanticId: semanticId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String semanticsLabel = "fusion_icon_${semanticId}";

    Widget iconWidget;

    // SVG Icon
    if (svg != null) {
      iconWidget = SemanticHelper.container(
        testId: SemanticHelper.createTestId(
          SemanticTypes.container,
          semanticsLabel,
        ),
        child: SvgPicture.asset(
          svg!,
          width: size,
          height: size,
          fit: fit,
          color: color, // ignore: deprecated_member_use
        ),
      );
    }
    // Material Icon
    else if (icon != null) {
      iconWidget = Icon(
        icon,
        size: size,
        color: color,
        semanticLabel: semanticsLabel,
      );
    }
    // Fallback
    else {
      iconWidget = const SizedBox.shrink();
    }

    return iconWidget;
  }
}
