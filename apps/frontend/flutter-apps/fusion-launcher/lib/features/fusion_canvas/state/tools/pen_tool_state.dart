import '../../model/fusion_canvas_point.dart';
import '../fusion_tool_state.dart';

abstract class PenToolState extends FusionToolState {
  // final List<FusionCanvasPoint> points;

  // PenToolState({required this.points});
}

class DrawingPenToolState extends PenToolState {
  final List<FusionCanvasPoint> points;

  DrawingPenToolState({required this.points});
}

class IdlePenToolState extends PenToolState {}
