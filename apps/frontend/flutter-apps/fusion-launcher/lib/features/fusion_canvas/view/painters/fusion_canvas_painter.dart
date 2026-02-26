import 'package:flutter/material.dart';

import '../../../wiring_design/view/painters/dotted_grid_painter.dart';
import '../../state/fusion_canvas_state.dart';

class FusionCanvasPainter extends CustomPainter {
  final FusionCanvasState state;
  final List<FusionBasePainter> childPainters;
  FusionCanvasPainter({required this.state, this.childPainters = const <FusionBasePainter>[]});
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

    for (final FusionBasePainter painter in childPainters) {
      painter.paint(canvas, size, this);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

abstract class FusionBasePainter {
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter);
  bool shouldRepaint(covariant FusionBasePainter oldDelegate);
}
