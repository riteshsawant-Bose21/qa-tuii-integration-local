import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NeumorphicAudioToggleButton extends StatelessWidget {
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
    this.borderRadius = 8,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "neumorphic_audio_toggle_button"),
        child: GestureDetector(
          onTapUp: (_) {
            onTap?.call();
          },
          child: FusionContainer(
            height: height ?? 32,
            width: width ?? double.infinity,
            raised: true,
            alignment: Alignment.center,
            color: backgroundColor,
            borderRadius: borderRadius,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FusionAppText(
                    text: !isActive ? "Mute" : "Unmute",
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    'assets/svg/volume.svg',
                    height: iconSize,
                    width: iconSize,
                    // ignore: deprecated_member_use
                    color: !isActive ? context.colorScheme.iconDefault : context.colorScheme.errorContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
