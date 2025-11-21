import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

List<BoxShadow> getNeumorphismBoxShadows({bool inner = false, Color? color}) {
  color ??= const Color(0xFFF5F5F5);
  return <BoxShadow>[
    if (inner) ...<BoxShadow>[
      const BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(-4, -4)),
      const BoxShadow(color: Colors.white, blurRadius: 1, offset: Offset(4, 4)),
      BoxShadow(color: color, blurRadius: 4),
    ] else ...<BoxShadow>[
      const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(2, 2)),
      const BoxShadow(color: Colors.white, blurRadius: 2, offset: Offset(-2, -2)),
      BoxShadow(color: color),
    ],
  ];
}

class NeumorphicButton extends StatefulWidget {
  final String text;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback onTap;
  final Color textColor;

  const NeumorphicButton({
    super.key,
    required this.text,
    required this.width,
    required this.height,
    required this.onTap,
    this.borderRadius = 10,
    this.textColor = Colors.black,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        clipBehavior: _isPressed ? Clip.hardEdge : Clip.none,
        child: Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: getNeumorphismBoxShadows(inner: _isPressed),
          ),
          child: FusionAppText(
            text: widget.text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
