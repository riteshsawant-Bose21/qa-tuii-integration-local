import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';

import '../../state/tools/measure_tool_state.dart';
import 'fusion_canvas_painter.dart';
import 'tool/measure_tool_painter.dart';

class ToolPainter extends FusionBasePainter {
  final FusionToolState state;
  final Offset? cursor;
  ToolPainter({required this.state, this.cursor});
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    if (state is MeasureToolState) {
      MeasureToolPainter(state: state as MeasureToolState, cursor: cursor).paint(canvas, size, painter);
    }
  }

  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    // TODO: implement shouldRepaint
    throw UnimplementedError();
  }
}
