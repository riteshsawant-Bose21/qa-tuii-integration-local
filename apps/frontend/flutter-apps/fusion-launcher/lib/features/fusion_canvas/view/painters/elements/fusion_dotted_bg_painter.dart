import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_canvas_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_canvas_painter.dart';

import '../../../../wiring_design/view/painters/dotted_grid_painter.dart';
import '../fusion_base_painter.dart';

class FusionDottedBgPainter extends FusionBasePainter {
  final Color color;
  FusionDottedBgPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    final FusionCanvasState state = painter.state;
    final Offset offset = state.offset;

    DottedGridPainter(color: color).paint(
      canvas,
      size,
      offset,
      state.scale,
    );
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
