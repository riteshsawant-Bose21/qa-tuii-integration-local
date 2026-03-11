import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionHorizontalResizableWidget extends StatefulWidget {
  final Widget child;
  final double initialWidth, minWidth, maxWidth;
  final double handleWidth;
  final bool dragLeft, dragRight;
  final String? semanticId;

  const FusionHorizontalResizableWidget({
    super.key,
    required this.child,
    this.semanticId,
    this.initialWidth = 200,
    this.minWidth = 100,
    this.maxWidth = 400,
    this.handleWidth = 8.0,
    this.dragLeft = true,
    this.dragRight = true,
  });

  @override
  HorizontalResizableContainerState createState() =>
      HorizontalResizableContainerState();
}

class HorizontalResizableContainerState
    extends State<FusionHorizontalResizableWidget> {
  late double _width;
  bool _hoverLeft = false, _hoverRight = false;
  bool _draggingLeft = false, _draggingRight = false;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth.clamp(widget.minWidth, widget.maxWidth);
  }

  // Move handlers
  void _onDragLeft(DragUpdateDetails details) {
    setState(() {
      _width = (_width - details.delta.dx).clamp(
        widget.minWidth,
        widget.maxWidth,
      );
    });
  }

  void _onDragRight(DragUpdateDetails details) {
    setState(() {
      _width = (_width + details.delta.dx).clamp(
        widget.minWidth,
        widget.maxWidth,
      );
    });
  }

  // Drag start/end for left
  void _startLeft(_) {
    setState(() {
      _draggingLeft = true;
      _hoverLeft = false; // immediately clear hover so cursor resets
    });
  }

  void _endLeft(_) {
    setState(() {
      _draggingLeft = false;
    });
  }

  // Drag start/end for right
  void _startRight(_) {
    setState(() {
      _draggingRight = true;
      _hoverRight = false;
    });
  }

  void _endRight(_) {
    setState(() {
      _draggingRight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // The resizable box (border logic unchanged)
        Container(
          width: _width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
            // border: Border(
            //   left: (_hoverLeft || _draggingLeft) ? const BorderSide(color: Colors.blue, width: 2) : const BorderSide(color: Colors.transparent, width: 2),
            //   right: (_hoverRight || _draggingRight) ? const BorderSide(color: Colors.blue, width: 2) : const BorderSide(color: Colors.transparent, width: 2),
            // ),
          ),
          child: widget.child,
        ),

        // Left-edge hot zone
        if (widget.dragLeft)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: widget.handleWidth,
            child: MouseRegion(
              // only show resize cursor on hover (and not while dragging)
              cursor: (!_draggingLeft && _hoverLeft)
                  ? SystemMouseCursors.resizeLeftRight
                  : SystemMouseCursors.basic,
              onEnter: (_) {
                if (!_draggingLeft) setState(() => _hoverLeft = true);
              },
              onExit: (_) {
                if (!_draggingLeft) setState(() => _hoverLeft = false);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _startLeft,
                onHorizontalDragUpdate: _onDragLeft,
                onHorizontalDragEnd: _endLeft,
              ),
            ),
          ),

        // Right-edge hot zone
        if (widget.dragRight)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: widget.handleWidth,
            child: MouseRegion(
              cursor: (!_draggingRight && _hoverRight)
                  ? SystemMouseCursors.resizeLeftRight
                  : SystemMouseCursors.basic,
              onEnter: (_) {
                if (!_draggingRight) setState(() => _hoverRight = true);
              },
              onExit: (_) {
                if (!_draggingRight) setState(() => _hoverRight = false);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _startRight,
                onHorizontalDragUpdate: _onDragRight,
                onHorizontalDragEnd: _endRight,
              ),
            ),
          ),
      ],
    );
  }
}
