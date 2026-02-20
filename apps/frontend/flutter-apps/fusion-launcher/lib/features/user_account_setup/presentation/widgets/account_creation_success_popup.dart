import 'dart:ui';

import 'package:flutter/material.dart';

Future<void> showSuccessPopup(BuildContext context, Function onDismiss, {int durationInMils = 1000}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext ctx) {
      return Center(
        child: _AnimatedCheckMarkDialog(
          onDismiss: onDismiss,
        ),
      );
    },
  );
}

class _AnimatedCheckMarkDialog extends StatefulWidget {
  final Function onDismiss;

  const _AnimatedCheckMarkDialog({required this.onDismiss});

  @override
  State<_AnimatedCheckMarkDialog> createState() => _AnimatedCheckMarkDialogState();
}

class _AnimatedCheckMarkDialogState extends State<_AnimatedCheckMarkDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pop();
        widget.onDismiss();
      }
    });

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: Colors.black.withAlpha((0.01 * 255).toInt()), // Slight tint
            ),
          ),

          // Dialog container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                "assets/images/check_mark.webp",
                fit: BoxFit.contain,
                height: 150,
                width: 150,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
