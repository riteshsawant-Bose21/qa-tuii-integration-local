import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/select_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/widgets/canvas_control_wrapper.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/widgets/fusion_canvas_listeners_wrapper.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_canvas_state.dart';
import '../state/fusion_snap_state.dart';
import '../viewmodel/fusion_canvas_hover_viewmodel.dart';
import '../viewmodel/fusion_canvas_image_viewmodel.dart';
import '../viewmodel/fusion_canvas_input_viewmodel.dart';
import '../viewmodel/fusion_canvas_state_viewmodel.dart';
import '../viewmodel/fusion_snap_viewmodel.dart';
import 'painters/elements/fusion_rect_painter.dart';
import 'painters/fusion_canvas_painter.dart';
import 'painters/snap_painter.dart';
import 'painters/tool/selection_tool_painter.dart';
import 'painters/tool_painter.dart';

class FusionCanvas extends StatelessWidget {
  const FusionCanvas({
    super.key,
    required this.elements,
    required this.builder,
    this.toolbarEvents,
    this.selectedIds,
  });
  final List<FusionBasePainter> elements;
  final Widget Function(BuildContext context)? builder;
  final FusionCanvasEvents? toolbarEvents;

  /// Set of selected layer IDs to sync with selection state
  final Set<String>? selectedIds;

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
      ],

      child: _SelectionSync(
        selectedIds: selectedIds,
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
                            final FusionToolState toolState = context.watch<FusionCanvasToolViewModel>().state;
                            final FusionCanvasPainter fusionCanvasPainter = FusionCanvasPainter(
                              state: state,
                              context: context,
                              layers: <FusionBasePainter>[
                                ...elements,

                                // Selection tool painter for highlighting selected elements
                                ToolPainter(
                                  state: toolState,
                                  cursor: snapState.effectivePosition,
                                ),
                                if (toolState is SelectToolState)
                                  SelectionToolPainter(
                                    state: toolState,
                                    allPainters: elements,
                                  ),

                                if (toolState is! SelectToolState)
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
                                // Update hover position
                                context.read<FusionCanvasHoverViewModel>().updateHoverPosition(
                                  state.mousePosition,
                                  fusionCanvasPainter,
                                );

                                // Build input context with all required state
                                final FusionCanvasInputContext inputContext = FusionCanvasInputContext(
                                  hoverState: context.read<FusionCanvasHoverViewModel>().state,
                                  snapState: context.read<FusionSnapViewModel>().state,
                                );

                                // Delegate all input handling to the tool viewmodel
                                final FusionCanvasToolViewModel toolVm = context.read<FusionCanvasToolViewModel>();
                                final bool isHandled = toolVm.onInputStateChanged(state, inputContext);
                                if (!isHandled) {
                                  if (state is FusionCanvasInputDraggingState) {
                                    context.read<FusionCanvasStateViewModel>().onPanUpdate(
                                      state.delta,
                                    );
                                  }
                                }

                                // Notify external callbacks for selection events
                                // if (state is FusionCanvasInputTapUpState && state.gestureOrigin == FusionGestureOrigin.click) {
                                //   final FusionBasePainter? hit = fusionCanvasPainter.isHit(
                                //     state.mousePosition ?? Offset.zero,
                                //   );
                                //   toolbarEvents?.onLayerSelected?.call(hit);
                                // }
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
    final FusionCanvasToolViewModel toolVm = context.read<FusionCanvasToolViewModel>();
    final Set<String> selectedIds = toolVm.selectedLayerIds;
    final List<Offset> points = <Offset>[];
    for (final FusionBasePainter element in widget.elements) {
      if (element is FusionPolygonPainter) {
        // Don't include points from selected elements (they can be moved)
        if (!selectedIds.contains(element.id)) {
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

/// Widget that syncs selection state from external selectedIds
class _SelectionSync extends StatefulWidget {
  const _SelectionSync({
    required this.selectedIds,
    required this.child,
  });

  final Set<String>? selectedIds;
  final Widget child;

  @override
  State<_SelectionSync> createState() => _SelectionSyncState();
}

class _SelectionSyncState extends State<_SelectionSync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.selectedIds != null) {
        context.read<FusionCanvasToolViewModel>().syncSelection(widget.selectedIds!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SelectionSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIds != null && !listEquals(widget.selectedIds?.toList(), oldWidget.selectedIds?.toList())) {
      context.read<FusionCanvasToolViewModel>().syncSelection(widget.selectedIds!);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
