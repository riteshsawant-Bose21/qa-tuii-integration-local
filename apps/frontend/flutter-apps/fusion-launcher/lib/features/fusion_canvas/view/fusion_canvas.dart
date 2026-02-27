import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/widgets/app_button_widget.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:nested/nested.dart';

import '../model/fusion_canvas_point.dart';
import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_canvas_state.dart';
import '../state/fusion_snap_state.dart';
import '../state/fusion_tool_state.dart';
import '../state/tools/pen_tool_state.dart';
import '../viewmodel/fusion_canvas_image_viewmodel.dart';
import '../viewmodel/fusion_canvas_input_viewmodel.dart';
import '../viewmodel/fusion_canvas_state_viewmodel.dart';
import '../viewmodel/fusion_snap_viewmodel.dart';
import 'painters/fusion_canvas_painter.dart';
import 'painters/snap_painter.dart';
import 'painters/tool_painter.dart';

class FusionCanvas extends StatelessWidget {
  const FusionCanvas({
    super.key,
    required this.elements,
  });
  final List<FusionBasePainter> elements;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<FusionCanvasStateViewModel>(create: (BuildContext context) => FusionCanvasStateViewModel()),
        BlocProvider<FusionCanvasInputViewModel>(create: (BuildContext context) => FusionCanvasInputViewModel()),
        BlocProvider<FusionSnapViewModel>(create: (BuildContext context) => FusionSnapViewModel()),
        BlocProvider<FusionCanvasImageViewModel>(create: (BuildContext context) => FusionCanvasImageViewModel()),
        BlocProvider<FusionCanvasToolViewModel>(
          create:
              (BuildContext context) => FusionCanvasToolViewModel(
                inputViewModel: context.read<FusionCanvasInputViewModel>(),
                snapViewModel: context.read<FusionSnapViewModel>(),
              ),
        ),
      ],

      child: BlocListener<FusionCanvasInputViewModel, FusionCanvasInputState>(
        listener: (BuildContext context, FusionCanvasInputState state) {
          // Update snap context when canvas state changes
          context.read<FusionSnapViewModel>().updateCursorPosition(state.mousePosition);
          _updateSnapContext(context);
        },
        child: BlocBuilder<FusionCanvasStateViewModel, FusionCanvasState>(
          builder: (BuildContext context, FusionCanvasState state) {
            return CanvasControlWrapper(
              child: BlocBuilder<FusionCanvasInputViewModel, FusionCanvasInputState>(
                builder: (BuildContext context, FusionCanvasInputState inputState) {
                  return BlocBuilder<FusionSnapViewModel, FusionSnapState>(
                    builder: (BuildContext context, FusionSnapState snapState) {
                      return CustomPaint(
                        painter: FusionCanvasPainter(
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
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Stack(
                            children: <Widget>[
                              // FusionCanvasCursor(),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Row(
                                  children: <Widget>[
                                    AppButton(
                                      btnWidth: 150,
                                      onTap: () {
                                        context.read<FusionCanvasToolViewModel>().setTool(IdleMeasureToolState());
                                      },
                                      buttonLabel: "Measure Tool",
                                    ),
                                    AppButton(
                                      btnWidth: 150,
                                      onTap: () {
                                        context.read<FusionCanvasToolViewModel>().setTool(IdlePenToolState());
                                      },
                                      buttonLabel: "Pen Tool",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _updateSnapContext(BuildContext context) {
    final FusionSnapViewModel snapViewModel = context.read<FusionSnapViewModel>();
    final FusionCanvasStateViewModel stateViewModel = context.read<FusionCanvasStateViewModel>();
    final FusionCanvasToolViewModel toolViewModel = context.read<FusionCanvasToolViewModel>();

    // Collect existing points from elements (you may need to adapt this based on your elements structure)
    final List<Offset> existingPoints = _collectExistingPoints(toolViewModel);

    // Get active start point based on current tool state
    final Offset? activeStartPoint = existingPoints.isNotEmpty ? existingPoints.last : null;

    snapViewModel.updateSnapContext(
      existingPoints: existingPoints,
      activeStartPoint: activeStartPoint,
      scale: stateViewModel.state.scale,
    );
  }

  List<Offset> _collectExistingPoints(FusionCanvasToolViewModel toolViewModel) {
    final List<Offset> points = <Offset>[];

    // Collect points from completed measurements
    final FusionToolState state = toolViewModel.state;
    if (state is DrawingMeasureToolState) {
      final DrawingMeasureToolState measureState = state;
      points.add(measureState.start);
      if (measureState.end != null) {
        points.add(measureState.end!);
      }
    }
    if (state is DrawingPenToolState) {
      final DrawingPenToolState penState = state;
      points.addAll(penState.points.map((FusionCanvasPoint p) => p.position));
    }

    return points;
  }
}

class CanvasControlWrapper extends StatelessWidget {
  const CanvasControlWrapper({
    super.key,

    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final FusionCanvasStateViewModel controller = context.read<FusionCanvasStateViewModel>();

    return FusionKeyboardWrapper(
      onKeyEvent: (KeyEvent value) {
        context.read<FusionCanvasInputViewModel>().onKeyEvent(value);
      },
      child: MouseRegion(
        // cursor: SystemMouseCursors.none,
        onExit: (PointerExitEvent event) {
          context.read<FusionCanvasInputViewModel>().updateMousePosition(null);
          context.read<FusionSnapViewModel>().updateCursorPosition(null);
        },
        onHover: (PointerHoverEvent event) {
          final Offset correctedPosition = controller.correctPosition(event.localPosition);
          context.read<FusionCanvasInputViewModel>().updateMousePosition(correctedPosition);
          context.read<FusionSnapViewModel>().updateCursorPosition(correctedPosition);
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
          child: Listener(
            onPointerSignal: (PointerSignalEvent event) {
              if (event is PointerScrollEvent) {
                controller.onScaleUpdate(
                  event.scrollDelta.distance * 0.001 * -event.scrollDelta.direction,
                  event.localPosition,
                );
              }
            },
            onPointerMove: (PointerMoveEvent event) {
              final Offset correctedPosition = controller.correctPosition(event.localPosition);
              // Update mouse position for snapping before handling pan
              context.read<FusionCanvasInputViewModel>().updateMousePosition(correctedPosition);

              // Handle panning only if not snapping or in specific tool states
              controller.onPanUpdate(
                event.delta / controller.state.scale,
              );
            },
            onPointerUp: (PointerUpEvent event) {
              final Offset correctedPosition = controller.correctPosition(event.localPosition);
              context.read<FusionCanvasInputViewModel>().onTapUp(correctedPosition);
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

abstract class FusionCanvasElement {}
