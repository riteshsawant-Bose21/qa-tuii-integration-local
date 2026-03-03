import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_input_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/pen_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/fusion_canvas.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_input_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_snap_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart';

class FusionCanvasListenersWrapper extends StatelessWidget {
  const FusionCanvasListenersWrapper({super.key, required this.child, this.toolbarEvents});
  final Widget child;
  final FusionCanvasEvents? toolbarEvents;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <SingleChildWidget>[
        ///
        /// Listners for snapping logic and cursor updates.
        ///
        BlocListener<FusionCanvasInputViewModel, FusionCanvasInputState>(
          listenWhen: (
            FusionCanvasInputState previous,
            FusionCanvasInputState current,
          ) {
            return previous.mousePosition != current.mousePosition;
          },
          listener: (BuildContext context, FusionCanvasInputState state) {
            context.read<FusionSnapViewModel>().updateCursorPosition(
              state.mousePosition,
            );
          },
        ),
        BlocListener<FusionCanvasToolViewModel, FusionToolState>(
          listener: (BuildContext context, FusionToolState state) {
            final List<FusionCanvasPoint> points = switch (state) {
              DrawingPenToolState(
                points: final List<FusionCanvasPoint> points,
              ) =>
                points,
              DrawingMeasureToolState(
                start: final Offset start,
                end: final Offset? end,
              ) =>
                <FusionCanvasPoint>[
                  FusionCanvasPoint(position: start),
                  if (end != null) FusionCanvasPoint(position: end),
                ],
              _ => <FusionCanvasPoint>[],
            };
            context.read<FusionSnapViewModel>().setToolPoints(
              points.map((FusionCanvasPoint p) => p.position).toList(),
            );
          },
        ),

       

        ///
        /// Listener for Triggering Events via callback.
        ///
        BlocListener<FusionCanvasToolViewModel, FusionToolState>(
          listener: (BuildContext context, FusionToolState state) {
            if (state is ClosedPenToolState) {
              toolbarEvents?.penToolEvents?.onPathClosed?.call(
                state.points,
              );
            } else if (state is DrawingPenToolState) {
              toolbarEvents?.penToolEvents?.onPointsChanged?.call(
                state.points,
              );
            }
          },
        ),
      ],
      child: child,
    );
  }
}
