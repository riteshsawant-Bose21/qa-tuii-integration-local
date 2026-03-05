import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_lib/models/project_entities/canvas/fusion_canvas_point.dart';

import '../../state/tools/measure_tool_state.dart';
import '../../state/tools/pen_tool_state.dart';
import 'fusion_canvas_painter.dart';
import 'tool/measure_tool_painter.dart';
import 'tool/pen_tool_painter.dart';

class ToolPainter extends FusionBasePainter {
  final FusionToolState state;
  final Offset? cursor;
  ToolPainter({required this.state, this.cursor}) {
    if (state is MeasureToolState) {
      _toolPainter = MeasureToolPainter(state: state as MeasureToolState, cursor: cursor);
    } else if (state is PenToolState) {
      _toolPainter = PenToolPainter(state: state as PenToolState, cursor: cursor);
    }
  }

  FusionBasePainter? _toolPainter;
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    // if (state is MeasureToolState) {
    //   MeasureToolPainter(state: state as MeasureToolState, cursor: cursor).paint(canvas, size, painter);
    // } else if (state is PenToolState) {
    //   PenToolPainter(state: state as PenToolState, cursor: cursor).paint(canvas, size, painter);
    // }
    _toolPainter?.paint(canvas, size, painter);
  }

  @override
  List<FusionCanvasPoint> get points => _toolPainter?.points ?? <FusionCanvasPoint>[];
  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
