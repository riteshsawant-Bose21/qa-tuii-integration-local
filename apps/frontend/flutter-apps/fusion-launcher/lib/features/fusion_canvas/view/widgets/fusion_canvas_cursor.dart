import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_input_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_input_viewmodel.dart';

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
