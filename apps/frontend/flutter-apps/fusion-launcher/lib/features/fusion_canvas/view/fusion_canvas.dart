import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_canvas_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/pen_tool_state.dart';
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
        child: MultiBlocListener(
          listeners: <SingleChildWidget>[
            ///
            /// Listners for napping logic and cursor updates.
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

            BlocListener<FusionCanvasInputViewModel, FusionCanvasInputState>(
              listener: (BuildContext context, FusionCanvasInputState state) {
                context.read<FusionCanvasToolViewModel>().onInputStateChanged(
                  state,
                  context.read<FusionSnapViewModel>().state,
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
                              return previous.runtimeType != current.runtimeType;
                            },
                            listener: (
                              BuildContext context,
                              FusionCanvasInputState state,
                            ) {
                              if (state is FusionCanvasInputTapUpState) {
                                toolbarEvents?.onLayerSelected?.call(
                                  fusionCanvasPainter.isHit(
                                    state.tapPosition,
                                  ),
                                );
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

class CanvasControlWrapper extends StatelessWidget {
  const CanvasControlWrapper({
    super.key,

    required this.child,
    required this.painter,
  });

  final Widget child;
  final FusionCanvasPainter painter;

  @override
  Widget build(BuildContext context) {
    final FusionCanvasStateViewModel controller = context.read<FusionCanvasStateViewModel>();

    final FusionToolState toolState = context.watch<FusionCanvasToolViewModel>().state;

    return FusionKeyboardWrapper(
      onKeyEvent: (KeyEvent value) {
        context.read<FusionCanvasInputViewModel>().onKeyEvent(value);
      },
      child: MouseRegion(
        cursor: switch (toolState) {
          MeasureToolState _ => SystemMouseCursors.precise,
          PenToolState _ => SystemMouseCursors.precise,
          _ => SystemMouseCursors.basic,
        },
        onExit: (PointerExitEvent event) {
          context.read<FusionCanvasInputViewModel>().updateMousePosition(null);
        },
        onHover: (PointerHoverEvent event) {
          final Offset correctedPosition = controller.correctPosition(
            event.localPosition,
          );
          context.read<FusionCanvasInputViewModel>().updateMousePosition(
            correctedPosition,
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
            onPointerMove: (PointerMoveEvent event) {
              final Offset correctedPosition = controller.correctPosition(
                event.localPosition,
              );
              // Update mouse position for snapping before handling pan
              context.read<FusionCanvasInputViewModel>().updateMousePosition(
                correctedPosition,
              );

              // // Handle panning only if not snapping or in specific tool states
              // controller.onPanUpdate(
              //   event.delta / controller.state.scale,
              // );
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

class FusionCanvasCursor extends StatelessWidget {
  const FusionCanvasCursor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FusionCanvasInputViewModel, FusionCanvasInputState>(
      builder: (BuildContext context, FusionCanvasInputState state) {
        final Offset? mousePosition = state.mousePosition;
        if (mousePosition == null) {
          return const SizedBox();
        }
        return Positioned(
          left: mousePosition.dx,
          top: mousePosition.dy,
          child: Container(
            height: 10,
            width: 10,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class FusionCanvasEvents {
  final FusionPenToolEvents? penToolEvents;
  final ValueChanged<FusionBasePainter?>? onLayerSelected;
  FusionCanvasEvents({this.penToolEvents, this.onLayerSelected});
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
        points.addAll(
          element.polygon.points.map((FusionCanvasPoint p) => p.position),
        );
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
