import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

enum PBSectionType { left, middle, right }

class PBSection extends StatelessWidget {
  const PBSection({
    super.key,
    required this.child,
    required this.type,
    this.padding = const EdgeInsets.all(8),
  });
  final PBSectionType type;
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: switch (type) {
          PBSectionType.left => BorderRadius.horizontal(
            left: Radius.circular(context.mediumRadius),
          ),
          PBSectionType.middle => null,
          PBSectionType.right => BorderRadius.horizontal(
            right: Radius.circular(context.mediumRadius),
          ),
        },
      ),
      child: child,
    );
  }
}
