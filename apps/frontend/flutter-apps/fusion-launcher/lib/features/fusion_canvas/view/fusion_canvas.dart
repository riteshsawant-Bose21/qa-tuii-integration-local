import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_action_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/pen_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/widgets/canvas_control_wrapper.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/widgets/fusion_canvas_listeners_wrapper.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_canvas_state.dart';
import '../state/fusion_snap_state.dart';
import '../viewmodel/fusion_canvas_action_viewmodel.dart';
import '../viewmodel/fusion_canvas_hover_viewmodel.dart';
import '../viewmodel/fusion_canvas_image_viewmodel.dart';
import '../viewmodel/fusion_canvas_input_viewmodel.dart';
import '../viewmodel/fusion_canvas_state_viewmodel.dart';
import '../viewmodel/fusion_snap_viewmodel.dart';
import 'painters/elements/fusion_rect_painter.dart';
import 'painters/fusion_canvas_painter.dart';
import 'painters/snap_painter.dart';
import 'painters/tool_painter.dart';

class FusionCanvas extends StatelessWidget {
  const FusionCanvas({
    super.key,
    required this.elements,
    required this.builder,
    this.toolbarEvents,
  });
  final List<FusionBasePainter> elements;
  final Widget Function(BuildContext context)? builder;
  final FusionCanvasEvents? toolbarEvents;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<FusionCanvasStateViewModel>(
          create: (BuildContext context) => FusionCanvasStateViewModel(),
        ),
        BlocProvider<FusionCanvasInputViewModel>(
          create: (BuildContext context) => FusionCanvasInputViewModel(),
        ),
        BlocProvider<FusionSnapViewModel>(
          create: (BuildContext context) => FusionSnapViewModel(),
        ),
        BlocProvider<FusionCanvasImageViewModel>(
          create: (BuildContext context) => FusionCanvasImageViewModel(),
        ),
        BlocProvider<FusionCanvasToolViewModel>(
          create: (BuildContext context) => FusionCanvasToolViewModel(),
        ),
        BlocProvider<FusionCanvasHoverViewModel>(
          create: (BuildContext context) => FusionCanvasHoverViewModel(),
        ),
        BlocProvider<FusionCanvasActionViewModel>(
          create: (BuildContext context) => FusionCanvasActionViewModel(),
        ),
      ],

      child: _PolygonPointsSync(
        elements: elements,
        child: FusionCanvasListenersWrapper(
          painters: elements,
          toolbarEvents: toolbarEvents,
          child: BlocBuilder<FusionCanvasStateViewModel, FusionCanvasState>(
            builder: (BuildContext context, FusionCanvasState state) {
              return Stack(
                children: <Widget>[
                  BlocBuilder<FusionCanvasInputViewModel, FusionCanvasInputState>(
                    builder: (
                      BuildContext context,
                      FusionCanvasInputState inputState,
                    ) {
                      return BlocBuilder<FusionSnapViewModel, FusionSnapState>(
                        builder: (
                          BuildContext context,
                          FusionSnapState snapState,
                        ) {
                          final FusionCanvasPainter fusionCanvasPainter = FusionCanvasPainter(
                            state: state,
                            context: context,
                            layers: <FusionBasePainter>[
                              ...elements,
                              ToolPainter(
                                state: context.watch<FusionCanvasToolViewModel>().state,
                                cursor: snapState.effectivePosition,
                              ),
                              if (context.watch<FusionCanvasToolViewModel>().state is! FusionCanvasIdleToolState)
                                SnapPainter(
                                  snapResult: snapState.snapResult,
                                ),
                            ],
                          );
                          return BlocListener<FusionCanvasInputViewModel, FusionCanvasInputState>(
                            listener: (
                              BuildContext context,
                              FusionCanvasInputState state,
                            ) {
                              context.read<FusionCanvasHoverViewModel>().updateHoverPosition(state.mousePosition, fusionCanvasPainter);

                              final FusionCanvasToolViewModel toolVm = context.read<FusionCanvasToolViewModel>();
                              toolVm.onInputStateChanged(
                                state,
                                context.read<FusionSnapViewModel>().state,
                              );

                              final FusionCanvasActionViewModel actionVm = context.read<FusionCanvasActionViewModel>();
                              if ((toolVm.state is MeasureToolState || toolVm.state is PenToolState)) {
                                actionVm.setToolActive();
                              }
                              if ((toolVm.state is! MeasureToolState && toolVm.state is! PenToolState) && state is FusionCanvasInputTapDownState) {
                                final FusionHoverState item = context.read<FusionCanvasHoverViewModel>().state;

                                if (item.hoveredPainterId != null) {
                                  final FusionCanvasElement? hitElement = item.hoveredElement;
                                  final List<String> pointIds = switch (hitElement) {
                                    FusionCanvasPoint() => <String>[hitElement.id],
                                    FusionCanvasLine(:final FusionCanvasPoint start, :final FusionCanvasPoint end) => <String>[start.id, end.id],
                                    FusionCanvasPolygon(:final List<FusionCanvasPoint> points) => points.map((FusionCanvasPoint p) => p.id).toList(),
                                    _ => <String>[],
                                  };
                                  if (pointIds.isNotEmpty) {
                                    actionVm.startPointsDrag(
                                      item.hoveredPainterId ?? '',
                                      pointIds,
                                    );
                                  } else {
                                    actionVm.startLayerDrag(item.hoveredPainterId ?? '');
                                  }
                                } else {
                                  actionVm.setCanvasPanning(Offset.zero);
                                }
                              }

                              if (state is FusionCanvasInputDraggingState) {
                                actionVm.updateDragDelta(
                                  state.delta,
                                );
                              }

                              if (state is FusionCanvasInputTapUpState) {
                                if (state.gestureOrigin == FusionGestureOrigin.click) {
                                  final FusionBasePainter? hit = fusionCanvasPainter.isHit(state.mousePosition ?? Offset.zero);
                                  toolbarEvents?.onLayerSelected?.call(hit);
                                }
                                if (state.gestureOrigin == FusionGestureOrigin.drag) {
                                  actionVm.onDragEnd();
                                }
                              }
                            },

                            child: BlocBuilder<FusionCanvasActionViewModel, FusionActionState>(
                              builder: (
                                BuildContext context,
                                FusionActionState actionState,
                              ) {
                                return CanvasControlWrapper(
                                  painter: fusionCanvasPainter,
                                  child: CustomPaint(
                                    painter: fusionCanvasPainter,
                                    child: const SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),

                  if (builder != null) builder!(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class FusionCanvasEvents {
  final FusionPenToolEvents? penToolEvents;
  final ValueChanged<FusionBasePainter?>? onLayerSelected;
  final void Function(FusionBasePainter painter, Offset offset)? onMoveLayer;

  final void Function(FusionBasePainter painter, List<FusionCanvasPoint> points, Offset delta)? onMovePoints;

  FusionCanvasEvents({this.penToolEvents, this.onLayerSelected, this.onMoveLayer, this.onMovePoints});
}

class FusionPenToolEvents {
  final ValueChanged<List<FusionCanvasPoint>>? onPointsChanged;
  final ValueChanged<List<FusionCanvasPoint>>? onPathClosed;

  FusionPenToolEvents({this.onPointsChanged, this.onPathClosed});
}

class _PolygonPointsSync extends StatefulWidget {
  const _PolygonPointsSync({
    required this.elements,
    required this.child,
  });

  final List<FusionBasePainter> elements;
  final Widget child;

  @override
  State<_PolygonPointsSync> createState() => _PolygonPointsSyncState();
}

class _PolygonPointsSyncState extends State<_PolygonPointsSync> {
  void _syncPolygonPoints() {
    final List<Offset> points = <Offset>[];
    for (final FusionBasePainter element in widget.elements) {
      if (element is FusionPolygonPainter) {
        if (!element.isSelected) {
          points.addAll(
            element.polygon.points.map((FusionCanvasPoint p) => p.position),
          );
        }
      }
    }
    context.read<FusionSnapViewModel>().addPolygonPoints(points);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPolygonPoints();
    });
  }

  @override
  void didUpdateWidget(covariant _PolygonPointsSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elements != widget.elements) {
      _syncPolygonPoints();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
