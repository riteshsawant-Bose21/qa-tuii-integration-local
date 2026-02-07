import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionNeumorphicButton extends StatefulWidget {
  final String? text;
  final double? width;
  final double? height;
  final double borderRadius;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final Widget? child;
  final Color? color;
  final double? padding;
  final EdgeInsetsGeometry? margin;

  const FusionNeumorphicButton({
    super.key,
    this.text,
    this.width,
    this.height = 35,
    required this.onTap,
    this.borderRadius = 12,
    this.textStyle,
    this.child,
    this.color,
    this.padding,
    this.margin,
  });

  @override
  State<FusionNeumorphicButton> createState() => _FusionNeumorphicButtonState();
}

class _FusionNeumorphicButtonState extends State<FusionNeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    assert(widget.text != null || widget.child != null);

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
            height: widget.height,
            alignment: Alignment.center,
            color: widget.color,
            padding: widget.padding,
            margin: widget.margin,
            child:
                widget.child ??
                FusionAppText(
                  text: widget.text!,
                  style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
                ),
          ),
        ),
      ),
    );
  }
}
