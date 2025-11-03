import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class OverlayContainer extends StatelessWidget {
  const OverlayContainer({
    super.key,
    required this.position,
    required this.tipPosition,
    required this.width,
    required this.child,
  });
  final Offset position;
  final Offset tipPosition;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    _Side? side;
    double leftPadding = 0;
    double topPadding = 0;
    if (tipPosition.dy < position.dy) {
      side = _Side.top;
      topPadding = -10;
    } else if (tipPosition.dx > position.dx) {
      side = _Side.right;
      leftPadding = 0;
      topPadding = 20;
    } else {
      side = _Side.left;
      leftPadding = -0;
      topPadding = 20;
    }

    return Stack(
      children: <Widget>[
        Positioned(
          left: position.dx - leftPadding,
          top: position.dy - topPadding,
          child: Container(
            decoration: BoxDecoration(
              color: context.colorScheme.componentBG,
              boxShadow: <BoxShadow>[
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            width: width,

            child: child,
          ),
        ),
      ],
    );
  }
}

enum _Side { left, right, top }
