import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/widgets/app_button_widget.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/measure_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/elements/fusion_image_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:nested/nested.dart';

import '../state/fusion_canvas_input_state.dart';
import '../state/fusion_canvas_state.dart';
import '../viewmodel/fusion_canvas_image_viewmodel.dart';
import '../viewmodel/fusion_canvas_input_viewmodel.dart';
import '../viewmodel/fusion_canvas_state_viewmodel.dart';
import 'painters/fusion_canvas_painter.dart';
import 'painters/tool_painter.dart';

class FusionCanvas extends StatelessWidget {
  const FusionCanvas({
    super.key,
    required this.elements,
  });
  final List<FusionCanvasElement> elements;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<FusionCanvasStateViewModel>(create: (BuildContext context) => FusionCanvasStateViewModel()),
        BlocProvider<FusionCanvasInputViewModel>(create: (BuildContext context) => FusionCanvasInputViewModel()),
        BlocProvider<FusionCanvasImageViewModel>(create: (BuildContext context) => FusionCanvasImageViewModel()),
        BlocProvider<FusionCanvasToolViewModel>(
          create:
              (BuildContext context) => FusionCanvasToolViewModel(
                inputViewModel: context.read<FusionCanvasInputViewModel>(),
              ),
        ),
      ],

      child: BlocListener<FusionCanvasInputViewModel, FusionCanvasInputState>(
        listener: (BuildContext context, FusionCanvasInputState state) {},
        child: BlocBuilder<FusionCanvasStateViewModel, FusionCanvasState>(
          builder: (BuildContext context, FusionCanvasState state) {
            return CanvasControlWrapper(
              child: CustomPaint(
                painter: FusionCanvasPainter(
                  state: state,
                  layers: <FusionBasePainter>[
                    for (final FusionCanvasElement element in elements)
                      if (element is FusionCanvasImageElement)
                        FusionImagePainter(
                          image: context.watch<FusionCanvasImageViewModel>().getImage(element.image),
                          position: element.position,
                          size: element.size,
                        ),
                    ToolPainter(
                      state: context.watch<FusionCanvasToolViewModel>().state,
                      cursor: context.watch<FusionCanvasInputViewModel>().state.mousePosition,
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
                        child: AppButton(
                          btnWidth: 150,
                          onTap: () {
                            context.read<FusionCanvasToolViewModel>().setTool(MeasureToolState());
                          },
                          buttonLabel: "Measure Tool",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
    return MouseRegion(
      // cursor: SystemMouseCursors.none,
      onExit: (PointerExitEvent event) {
        context.read<FusionCanvasInputViewModel>().updateMousePosition(null);
      },
      onHover: (PointerHoverEvent event) {
        context.read<FusionCanvasInputViewModel>().updateMousePosition(controller.correctPosition(event.localPosition));
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
            controller.onPanUpdate(
              event.delta / controller.state.scale,
            );
          },
          onPointerUp: (PointerUpEvent event) {
            context.read<FusionCanvasInputViewModel>().onTapUp(controller.correctPosition(event.localPosition));
            // final Offset correctedPos = circuitPainter.correctPosition(
            //   event.localPosition,
            // );
            // final dynamic value = circuitPainter.isHit(correctedPos);
            // if (controller.state is ElementMovingState || controller.state is ConnectionProgressWiringState) {
            //   controller.onMoveEnd(value, correctedPos);
            // } else {
            //   controller.selectElement(value);
            // }
          },

          child: ClipRect(
            child: child,
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

class FusionCanvasImageElement extends FusionCanvasElement {
  FusionCanvasImageElement({
    required this.image,
    required this.position,
    required this.size,
  });

  final String image;
  final Offset position;
  final Size size;
}
