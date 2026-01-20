import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';



class FusionNeumorphicButton extends StatefulWidget {
  final String text;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback onTap;
  final Color textColor;

  const FusionNeumorphicButton({
    super.key,
    required this.text,
    required this.width,
    required this.height,
    required this.onTap,
    this.borderRadius = 12,
    this.textColor = Colors.black,
  });

  @override
  State<FusionNeumorphicButton> createState() => _FusionNeumorphicButtonState();
}

class _FusionNeumorphicButtonState extends State<FusionNeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "neumorphic_button_${widget.text}"),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          clipBehavior: _isPressed ? Clip.hardEdge : Clip.none,
          child: FusionContainer(
            width: widget.width,
            raised: !_isPressed,
            borderRadius: widget.borderRadius,
            // height: widget.height,
            // alignment: Alignment.center,
            // decoration: BoxDecoration(
            //   color: Colors.transparent,
            //   borderRadius: BorderRadius.circular(widget.borderRadius),
            //   boxShadow: getNeumorphismBoxShadows(inner: _isPressed),
            // ),
            child: FusionAppText(
              text: widget.text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
