import 'dart:ui';

import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../state/tools/measure_tool_state.dart';
import '../../state/tools/pen_tool_state.dart';
import 'fusion_canvas_painter.dart';
import 'tool/connection_tool_painter.dart';
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
    } else if (state is ConnectingToolState) {
      _toolPainter = ConnectionToolPainter(state: state as ConnectingToolState);
    }
  }

  FusionBasePainter? _toolPainter;
  @override
  void paint(Canvas canvas, Size size, FusionCanvasPainter painter) {
    _toolPainter?.paint(canvas, size, painter);
  }

  @override
  List<FusionCanvasElement> get elements => _toolPainter?.elements ?? <FusionCanvasElement>[];
  @override
  bool shouldRepaint(covariant FusionBasePainter oldDelegate) {
    return true;
  }
}
