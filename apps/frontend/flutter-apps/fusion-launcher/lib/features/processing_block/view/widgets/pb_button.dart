import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class PBButton extends StatefulWidget {
  final String text;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback onTap;

  const PBButton({
    super.key,
    required this.text,
    required this.width,
    required this.height,
    required this.onTap,
    this.borderRadius = 10,
  });

  @override
  State<PBButton> createState() => _PBButtonState();
}

class _PBButtonState extends State<PBButton> {
  bool _isPressed = false;

  List<BoxShadow> get _shadows => <BoxShadow>[
    const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
    const BoxShadow(color: Colors.white, blurRadius: 1, offset: Offset(-2, -2)),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed ? Colors.white : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed ? null : _shadows,
        ),
        child: FusionAppText(text: widget.text),
      ),
    );
  }
}
