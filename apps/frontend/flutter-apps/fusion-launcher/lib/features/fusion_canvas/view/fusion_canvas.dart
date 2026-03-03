import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../state/tools/select_tool_state.dart';
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
                            listenWhen: (
                              FusionCanvasInputState previous,
                              FusionCanvasInputState current,
                            ) {
                              return previous != current;
                            },
                            listener: (
                              BuildContext context,
                              FusionCanvasInputState state,
                            ) {
                              // if (state is IdleFusionCanvasState) {
                              //   return;
                              // }

                              final FusionCanvasToolViewModel read = context.read<FusionCanvasToolViewModel>();
                              read.onInputStateChanged(
                                state,
                                context.read<FusionSnapViewModel>().state,
                              );
                              if ((read.state is! MeasureToolState && read.state is! PenToolState) && state is FusionCanvasInputTapDownState) {
                                final FusionBasePainter? item = fusionCanvasPainter.isHit(
                                  state.mousePosition ?? Offset.zero,
                                );
                                toolbarEvents?.onLayerSelected?.call(
                                  item,
                                );
                              }
                              if (state is FusionCanvasInputDraggingState) {
                                final List<FusionBasePainter> selectedLayers = elements.where((FusionBasePainter layer) => layer.isSelected).toList();

                                if (selectedLayers.isNotEmpty) {
                                  read.setTool(SelectingSelectToolState(selectedLayerIds: selectedLayers));
                                  for (final FusionBasePainter layer in selectedLayers) {
                                    toolbarEvents?.onMoveLayer?.call(
                                      layer,
                                      state.delta,
                                    );
                                  }
                                } else {
                                  context.read<FusionCanvasStateViewModel>().onPanUpdate(
                                    state.delta,
                                  );
                                }
                              }
                            },

                            child: CanvasControlWrapper(
                              painter: fusionCanvasPainter,
                              child: CustomPaint(
                                painter: fusionCanvasPainter,
                                child: const SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
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
  FusionCanvasEvents({this.penToolEvents, this.onLayerSelected, this.onMoveLayer});
}

class FusionPenToolEvents {
  final ValueChanged<List<FusionCanvasPoint>>? onPointsChanged;
  final ValueChanged<List<FusionCanvasPoint>>? onPathClosed;

  FusionPenToolEvents({this.onPointsChanged, this.onPathClosed});
}

/// A widget that syncs polygon points from elements to FusionSnapViewModel.
/// The ViewModel handles change detection internally.
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
