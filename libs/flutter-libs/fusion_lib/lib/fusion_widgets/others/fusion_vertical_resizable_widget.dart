import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionVerticalResizableWidget extends StatefulWidget {
  final Widget child;
  final double minHeight;
  final double maxHeight;
  final bool dragTop;
  final bool dragBottom;
  final double initialHeight;
  final ValueChanged<double>? onHeightChanged;
  final String? semanticId;

  const FusionVerticalResizableWidget({
    this.semanticId,
    super.key,
    required this.child,
    this.minHeight = 100,
    this.maxHeight = double.infinity,
    this.dragTop = false,
    this.dragBottom = true,
    required this.initialHeight,
    this.onHeightChanged,
  });

  @override
  State<FusionVerticalResizableWidget> createState() =>
      _FusionVerticalResizableWidgetState();
}

class _FusionVerticalResizableWidgetState
    extends State<FusionVerticalResizableWidget> {
  late double _currentHeight;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight.clamp(
      widget.minHeight,
      widget.maxHeight,
    );
  }

  @override
  void didUpdateWidget(FusionVerticalResizableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHeight != oldWidget.initialHeight) {
      setState(() {
        _currentHeight = widget.initialHeight.clamp(
          widget.minHeight,
          widget.maxHeight,
        );
      });
    }
  }

  void _handleResize(double delta) {
    final double newHeight = _currentHeight + delta;
    final double clampedHeight = newHeight.clamp(
      widget.minHeight,
      widget.maxHeight,
    );

    // Always try to update, let parent validate the constraints
    if (widget.onHeightChanged != null) {
      widget.onHeightChanged!(clampedHeight);
    }
  }

  Widget _buildResizeHandle({required bool isBottom}) {
    return Positioned(
      top: isBottom ? null : 0,
      bottom: isBottom ? 0 : null,
      left: 0,
      right: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: GestureDetector(
          onPanUpdate: (details) =>
              _handleResize(isBottom ? details.delta.dy : -details.delta.dy),
          child: Container(
            height: 8,
            color: Colors.transparent,
            // Removed the visible line - just transparent interactive area
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        "fusion_vertical_resizable${widget.semanticId ?? ""}",
      ),

      child: SizedBox(
        height: _currentHeight,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (widget.dragTop) _buildResizeHandle(isBottom: false),
            if (widget.dragBottom) _buildResizeHandle(isBottom: true),
          ],
        ),
      ),
    );
  }
}
