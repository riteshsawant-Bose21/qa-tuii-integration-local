import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../common/neumorphic_button.dart';

class NeumorphicActiveBlueButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final double borderRadius;

  const NeumorphicActiveBlueButton({
    super.key,
    required this.text,
    required this.isActive,
    this.onTap,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTapUp: (_) {
          onTap?.call();
        },
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(borderRadius),
          clipBehavior: isActive ? Clip.hardEdge : Clip.none,
          child: Container(
            height: height ?? 50,
            width: width ?? double.infinity,
            clipBehavior: isActive ? Clip.hardEdge : Clip.none,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: getNeumorphismBoxShadows(inner: isActive),
            ),
            child: Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE2F2FB) : Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                border: isActive ? Border.all(color: const Color(0xFF4D9BC7), width: 1) : null,
              ),
              child: FusionAppText(
                text: text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
