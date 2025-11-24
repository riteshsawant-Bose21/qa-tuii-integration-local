import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/neumorphic_button.dart';

class NeumorphicAudioToggleButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final double borderRadius;
  final double iconSize;

  const NeumorphicAudioToggleButton({
    super.key,
    required this.isActive,
    this.onTap,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderRadius = 6,
    this.iconSize = 16,
  });

  @override
  State<NeumorphicAudioToggleButton> createState() => _NeumorphicAudioToggleButtonState();
}

class _NeumorphicAudioToggleButtonState extends State<NeumorphicAudioToggleButton> {
  bool get _effectiveIsActive => widget.isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTapUp: (_) {
          widget.onTap?.call();
        },
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(widget.borderRadius),
          clipBehavior: _effectiveIsActive ? Clip.hardEdge : Clip.none,
          child: Container(
            height: widget.height ?? 50,
            width: widget.width ?? double.infinity,
            clipBehavior: _effectiveIsActive ? Clip.hardEdge : Clip.none,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: getNeumorphismBoxShadows(inner: _effectiveIsActive),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/volume.svg',
                height: widget.iconSize,
                width: widget.iconSize,
                // ignore: deprecated_member_use
                color: widget.isActive ? Colors.black : const Color(0xFFE2E2E2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
