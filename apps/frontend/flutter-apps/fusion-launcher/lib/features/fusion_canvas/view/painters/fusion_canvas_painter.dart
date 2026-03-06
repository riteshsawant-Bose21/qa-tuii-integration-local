import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_hover_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_input_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_snap_viewmodel.dart';

import '../../../wiring_design/view/painters/dotted_grid_painter.dart';
import '../../state/fusion_canvas_input_state.dart';
import '../../state/fusion_canvas_state.dart';
import '../../state/fusion_snap_state.dart';
import '../../viewmodel/fusion_canvas_hover_viewmodel.dart';
import '../../viewmodel/fusion_canvas_image_viewmodel.dart';

class FusionCanvasPainter extends CustomPainter {
  final FusionCanvasState state;
  final List<FusionBasePainter> layers;
  final BuildContext context;

  FusionCanvasPainter({
    required this.state,
    this.layers = const <FusionBasePainter>[],
    required this.context,
  });
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final Offset offset = state.offset;
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(state.scale);

    DottedGridPainter(color: Colors.grey.shade300).paint(
      canvas,
      size,
      offset,
      state.scale,
    );

    for (final FusionBasePainter painter in layers) {
      painter.paint(canvas, size, this);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
    // oldDelegate is! FusionCanvasPainter ||
    //     oldDelegate.state != state ||
    //     oldDelegate.layers != layers ||
    //     layers.any(
    //       (FusionBasePainter p) =>
    //           !oldDelegate.layers.contains(p) ||
    //           p.shouldRepaint(oldDelegate.layers.firstWhere((FusionBasePainter op) => op.runtimeType == p.runtimeType, orElse: () => p)),
    //     );
  }

  ui.Image? getImage(String s) {
    return context.read<FusionCanvasImageViewModel>().getImage(s);
  }

  FusionBasePainter? isHit(Offset position) {
    for (final FusionBasePainter painter in layers.reversed) {
      if (painter.isHit(position, this) != null) {
        return painter;
      }
    }
    return null;
  }

  FusionCanvasInputState get inputViewModel => context.read<FusionCanvasInputViewModel>().state;

  Offset? get cursor => inputViewModel.mousePosition;

  FusionSnapState get snapViewModel => context.read<FusionSnapViewModel>().state;

  FusionHoverState get hoverViewModel => context.read<FusionCanvasHoverViewModel>().state;

  FusionToolState get toolState => context.read<FusionCanvasToolViewModel>().state;
}
