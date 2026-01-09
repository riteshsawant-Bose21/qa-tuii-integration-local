import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class OverlayContainer extends StatefulWidget {
  const OverlayContainer({
    super.key,
    required this.position,
    required this.tipPosition,
    required this.width,
    required this.child,
    required this.viewPort,
  });
  final Offset position;
  final Offset tipPosition;
  final double width;
  final Widget child;
  final Rect viewPort;

  @override
  State<OverlayContainer> createState() => _OverlayContainerState();
}

class _OverlayContainerState extends State<OverlayContainer> {
  final GlobalKey<State<StatefulWidget>> key = GlobalKey();

  double? childHeight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      childHeight = key.currentContext?.size?.height;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant OverlayContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      childHeight = key.currentContext?.size?.height;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // _Side? side;
    double leftPadding = 0;
    double topPadding = 0;
    if (widget.tipPosition.dy < widget.position.dy) {
      // side = _Side.top;
      topPadding = -10;
    } else if (widget.tipPosition.dx > widget.position.dx) {
      //  side = _Side.right;
      leftPadding = 0;
      topPadding = 20;
    } else {
      //  side = _Side.left;
      leftPadding = -0;
      topPadding = 20;
    }

    if (widget.position.dy + (childHeight ?? 0) > widget.viewPort.bottom) {
      topPadding += (widget.viewPort.bottom - (widget.position.dy + (childHeight ?? 0))).abs();
    }
    return Stack(
      children: <Widget>[
        Positioned(
          left: widget.position.dx - leftPadding,
          top: widget.position.dy - topPadding,
          child: Container(
            key: key,
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
            width: widget.width,

            child: widget.child,
          ),
        ),
      ],
    );
  }
}

enum _Side { left, right, top }
