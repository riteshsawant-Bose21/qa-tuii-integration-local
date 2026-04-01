import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_input_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/pen_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_hover_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_input_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_state_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

enum _CanvasCursorType {
  basic(image: "assets/icons/canvas_cursor/cursor.png", pointerTip: Alignment.center),
  precise(image: "assets/icons/canvas_cursor/pencil.png", pointerTip: Alignment.bottomCenter),
  grab(image: "assets/icons/canvas_cursor/cursor.png", pointerTip: Alignment.center),
  grabbing(image: "assets/icons/canvas_cursor/cursor.png", pointerTip: Alignment.center),
  resizeLeftRight(image: "assets/icons/canvas_cursor/move_horizontal.png", pointerTip: Alignment.center),
  resizeUpDown(image: "assets/icons/canvas_cursor/move_vertical.png", pointerTip: Alignment.center);

  const _CanvasCursorType({required this.image, required this.pointerTip});
  final String image;
  final Alignment pointerTip;
}

typedef CursorBuilder = (Alignment, Widget)? Function(BuildContext context);

class FusionCanvasCursor extends StatelessWidget {
  const FusionCanvasCursor({super.key, this.builder});
  final CursorBuilder? builder;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FusionCanvasInputViewModel, FusionCanvasInputState>(
      builder: (BuildContext context, FusionCanvasInputState state) {
        final Offset? mousePosition = state.mousePosition;
        if (mousePosition == null) {
          return const SizedBox();
        }

        final FusionToolState toolState = context.watch<FusionCanvasToolViewModel>().state;
        final FusionHoverState hoverState = context.watch<FusionCanvasHoverViewModel>().state;
        final FusionCanvasElement? hoveredElement = hoverState.hoveredElement;
        final bool isHoveringLineCenter = hoverState.isCenterHandleHovered;

        final _CanvasCursorType cursorType = switch (toolState) {
          _ when isHoveringLineCenter => _CanvasCursorType.precise,
          MeasureToolState _ => _CanvasCursorType.precise,
          PenToolState _ => _CanvasCursorType.precise,
          LayerDraggingState _ => _CanvasCursorType.grabbing,
          PointsDraggingState _ => _CanvasCursorType.grabbing,
          _ =>
            hoverState.hoveredPainterId != null
                ? switch (hoveredElement) {
                  FusionCanvasLine() => hoveredElement.isVerticalLine ? _CanvasCursorType.resizeLeftRight : _CanvasCursorType.resizeUpDown,
                  FusionCanvasPathSegment() => hoveredElement.isVerticalLine ? _CanvasCursorType.resizeLeftRight : _CanvasCursorType.resizeUpDown,
                  FusionCanvasPoint _ => _CanvasCursorType.grab,
                  FusionCanvasPolygon _ => _CanvasCursorType.grab,
                  _ => _CanvasCursorType.basic,
                }
                : _CanvasCursorType.basic,
        };

        final FusionCanvasStateViewModel canvasState = context.watch<FusionCanvasStateViewModel>();
        final Offset effectiveMousePosition = canvasState.transformPosition(mousePosition);
        final Widget cursor = _buildCursor(cursorType);
        final (Alignment, Widget)? customCursor = builder != null ? builder!(context) : null;

        final Alignment alignment = customCursor != null ? customCursor.$1 : cursorType.pointerTip;
        final Widget cursorWidget = customCursor != null ? customCursor.$2 : cursor;
        final double size = 18;
        return Positioned(
          left: effectiveMousePosition.dx + alignment.x * size,
          top: effectiveMousePosition.dy + alignment.y * -size,
          child: IgnorePointer(
            child: SizedBox(
              height: size,
              width: size,
              child: cursorWidget,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCursor(_CanvasCursorType cursorType) {
    return Image.asset(
      cursorType.image,
      width: 24,
      height: 24,
    );
    // return switch (cursorType) {
    //   _CanvasCursorType.precise => const Icon(LucideIcons.pencil, size: 18, color: Colors.black),
    //   _CanvasCursorType.grab => const Icon(LucideIcons.hand, size: 18, color: Colors.black),
    //   _CanvasCursorType.grabbing => const Icon(LucideIcons.handGrab, size: 18, color: Colors.black),
    //   _CanvasCursorType.resizeLeftRight => const Icon(LucideIcons.moveHorizontal, size: 18, color: Colors.black),
    //   _CanvasCursorType.resizeUpDown => const Icon(LucideIcons.moveVertical, size: 18, color: Colors.black),
    //   _CanvasCursorType.basic => const Icon(
    //     LucideIcons.mousePointer2,
    //     color: Colors.black,
    //   ),
    // };
  }
}
