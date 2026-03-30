import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_input_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_state_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CanvasControlWrapper extends StatelessWidget {
  const CanvasControlWrapper({
    super.key,

    required this.child,
    required this.painter,
    this.onKeyEvent,
  });

  final Widget child;
  final FusionCanvasPainter painter;
  final ValueChanged<KeyEvent>? onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final FusionCanvasStateViewModel controller = context.read<FusionCanvasStateViewModel>();

    return FusionKeyboardWrapper(
      onKeyEvent: (KeyEvent value) {
        context.read<FusionCanvasInputViewModel>().onKeyEvent(value);
        onKeyEvent?.call(value);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.none,
        onExit: (PointerExitEvent event) {
          context.read<FusionCanvasInputViewModel>().updateMousePosition(null, null);
        },
        onHover: (PointerHoverEvent event) {
          final Offset correctedPosition = controller.correctPosition(
            event.localPosition,
          );

          // event.delta
          context.read<FusionCanvasInputViewModel>().updateMousePosition(
            correctedPosition,
            event.delta * (1 / controller.state.scale), // Scale delta for consistent panning speed
          );
        },
        child: GestureDetector(
          onScaleStart: (ScaleStartDetails details) {
            controller.onScaleStart(details);
          },
          onScaleUpdate: (ScaleUpdateDetails details) {
            controller.onScaleUpdate(details.scale, details.focalPoint);
          },
          onScaleEnd: (ScaleEndDetails details) {
            controller.onScaleEnd(details);
          },
          onDoubleTapDown: (TapDownDetails details) {
            final Offset correctedPosition = controller.correctPosition(
              details.localPosition,
            );
            context.read<FusionCanvasInputViewModel>().onDoubleTap(
              correctedPosition,
            );
          },
          onLongPressStart: (LongPressStartDetails details) {
            final Offset correctedPosition = controller.correctPosition(
              details.localPosition,
            );
            context.read<FusionCanvasInputViewModel>().onLongPress(
              correctedPosition,
            );
          },
          onSecondaryTapUp: (TapUpDetails details) {
            final Offset correctedPosition = controller.correctPosition(
              details.localPosition,
            );
            context.read<FusionCanvasInputViewModel>().onSecondaryTap(
              correctedPosition,
            );
          },
          child: Listener(
            // Handle scroll for zoom (not sent to input viewmodel)
            onPointerSignal: (PointerSignalEvent event) {
              if (event is PointerScrollEvent) {
                controller.onScaleUpdate(
                  event.scrollDelta.distance * 0.001 * -event.scrollDelta.direction,
                  event.localPosition,
                );
              }
            },
            onPointerPanZoomStart: (PointerPanZoomStartEvent event) {
              controller.onStartPanZoom(event.localPosition);
            },
            onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
              final Offset localPanDelta = event.localPanDelta * (1 / controller.state.scale);
              controller.onUpdatePanZoom(event.scale, event.localPosition, localPanDelta);
              final Offset correctedPosition = controller.correctPosition(
                event.localPosition,
              );
              // Update mouse position for snapping before handling pan
              context.read<FusionCanvasInputViewModel>().updateMousePosition(
                correctedPosition,
                localPanDelta, // Scale delta for consistent panning speed
              );
              // );
            },
            onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
              controller.onEndPanZoom();
            },

            onPointerMove: (PointerMoveEvent event) {
              final Offset correctedPosition = controller.correctPosition(
                event.localPosition,
              );
              // Update mouse position for snapping before handling pan
              context.read<FusionCanvasInputViewModel>().updateMousePosition(
                correctedPosition,
                event.delta * (1 / controller.state.scale), // Scale delta for consistent panning speed
              );
            },
            onPointerUp: (PointerUpEvent event) {
              final Offset correctedPosition = controller.correctPosition(
                event.localPosition,
              );

              context.read<FusionCanvasInputViewModel>().onTapUp(
                correctedPosition,
                buttons: event.buttons == 0 ? 0x01 : event.buttons,
              );
            },
            onPointerDown: (PointerDownEvent event) {
              final Offset correctedPosition = controller.correctPosition(
                event.localPosition,
              );

              context.read<FusionCanvasInputViewModel>().onTapDown(
                correctedPosition,
                buttons: event.buttons,
              );
            },

            child: ClipRect(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
