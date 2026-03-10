import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_input_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/drag_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/pen_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/fusion_canvas.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_input_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_snap_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart';

import '../../state/tools/select_tool_state.dart';
import '../painters/elements/fusion_rect_painter.dart';

class FusionCanvasListenersWrapper extends StatelessWidget {
  const FusionCanvasListenersWrapper({super.key, required this.child, this.toolbarEvents, required this.painters});
  final Widget child;
  final FusionCanvasEvents? toolbarEvents;
  final List<FusionBasePainter> painters;

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
            final FusionToolState fusionToolState = context.read<FusionCanvasToolViewModel>().state;

            // Handle layer dragging - apply drag delta to all polygon points
            if (fusionToolState is LayerDraggingState) {
              final FusionBasePainter? painter = painters.cast<FusionBasePainter?>().firstWhere(
                (FusionBasePainter? p) => p?.id == fusionToolState.layerId,
                orElse: () => null,
              );
              if (painter is FusionPolygonPainter) {
                context.read<FusionSnapViewModel>().updateCursorPositions(
                  painter.polygon.points.map((FusionCanvasPoint e) => e.position + fusionToolState.delta).toList(),
                );
                return;
              }
            }

            // Handle points dragging - apply drag delta to specific points
            if (fusionToolState is PointsDraggingState) {
              final FusionBasePainter? painter = painters.cast<FusionBasePainter?>().firstWhere(
                (FusionBasePainter? p) => p?.id == fusionToolState.layerId,
                orElse: () => null,
              );
              if (painter is FusionPolygonPainter) {
                context.read<FusionSnapViewModel>().updateCursorPositions(
                  painter.polygon.points
                      .where((FusionCanvasPoint p) => fusionToolState.pointIds.contains(p.id))
                      .map((FusionCanvasPoint e) => e.position + fusionToolState.delta)
                      .toList(),
                );
                return;
              }
            }

            if (fusionToolState is SelectToolState && fusionToolState.selectedLayerIds.isNotEmpty) {
              context.read<FusionSnapViewModel>().updateCursorPositions(
                <Offset>[
                  for (final FusionBasePainter painter in painters) ...<Offset>[
                    if (fusionToolState.isLayerSelected(painter.id) && painter is FusionPolygonPainter)
                      ...painter.polygon.points.map((FusionCanvasPoint e) => e.position),
                  ],
                ],
              );
            } else {
              context.read<FusionSnapViewModel>().updateCursorPosition(
                state.mousePosition,
              );
            }
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
        /// Listener for dragging state changes to update snap positions.
        ///
        BlocListener<FusionCanvasToolViewModel, FusionToolState>(
          listenWhen: (FusionToolState previous, FusionToolState current) {
            return current is LayerDraggingState || current is PointsDraggingState;
          },
          listener: (BuildContext context, FusionToolState state) {
            if (state is LayerDraggingState) {
              final FusionBasePainter? painter = painters.cast<FusionBasePainter?>().firstWhere(
                (FusionBasePainter? p) => p?.id == state.layerId,
                orElse: () => null,
              );
              if (painter is FusionPolygonPainter) {
                context.read<FusionSnapViewModel>().updateCursorPositions(
                  painter.polygon.points.map((FusionCanvasPoint e) => e.position + state.delta).toList(),
                );
              }
            } else if (state is PointsDraggingState) {
              final FusionBasePainter? painter = painters.cast<FusionBasePainter?>().firstWhere(
                (FusionBasePainter? p) => p?.id == state.layerId,
                orElse: () => null,
              );
              if (painter is FusionPolygonPainter) {
                context.read<FusionSnapViewModel>().addTempPolygonPoints(
                  painter.polygon.points.where((FusionCanvasPoint p) => !state.pointIds.contains(p.id)).map((FusionCanvasPoint e) => e.position).toList(),
                );
                context.read<FusionSnapViewModel>().updateCursorPositions(
                  painter.polygon.points
                      .where((FusionCanvasPoint p) => state.pointIds.contains(p.id))
                      .map((FusionCanvasPoint e) => e.position + state.delta)
                      .toList(),
                );
              }
            }
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

        BlocListener<FusionCanvasToolViewModel, FusionToolState>(
          listenWhen: (FusionToolState previous, FusionToolState current) {
            return current is DragToolState || previous is DragToolState;
          },
          listener: (BuildContext context, FusionToolState state) {
            if (state is LayerDragEndState) {
              toolbarEvents?.onMoveLayer?.call(
                painters.firstWhere(
                  (FusionBasePainter p) => p.id == state.layerId,
                  orElse: () => throw Exception('Painter with id ${state.layerId} not found'),
                ),
                state.delta,
              );
            } else if (state is PointsDragEndState) {
              final FusionBasePainter basePainter = painters.firstWhere(
                (FusionBasePainter p) => p.id == state.layerId,
                orElse: () => throw Exception('Painter with id ${state.layerId} not found'),
              );
              toolbarEvents?.onMovePoints?.call(
                basePainter,
                basePainter is FusionPolygonPainter
                    ? basePainter.polygon.points.where((FusionCanvasPoint p) => state.pointIds.contains(p.id)).toList()
                    : <FusionCanvasPoint>[],
                state.delta,
              );
            } else if (state is LayerDragStartState) {
              toolbarEvents?.onLayerSelected?.call(
                painters.firstWhere(
                  (FusionBasePainter p) => p.id == state.layerId,
                  orElse: () => throw Exception('Painter with id ${state.layerId} not found'),
                ),
              );
            } else if (state is PointsDragStartState) {
              toolbarEvents?.onLayerSelected?.call(
                painters.firstWhere(
                  (FusionBasePainter p) => p.id == state.layerId,
                  orElse: () => throw Exception('Painter with id ${state.layerId} not found'),
                ),
              );
            } else if (state is SelectToolState) {
              final String? id = state.selectedLayerIds.firstOrNull;
              toolbarEvents?.onLayerSelected?.call(
                id != null
                    ? painters.firstWhere(
                      (FusionBasePainter p) => p.id == id,
                      orElse: () => throw Exception('Painter with id $id not found'),
                    )
                    : null,
              );
            }
          },
        ),
      ],
      child: child,
    );
  }
}
