import '../../model/fusion_canvas_element.dart';
import '../fusion_tool_state.dart';

class PenToolState extends FusionToolState {
  final List<FusionCanvasPoint> points;
  
  PenToolState({required this.points});
}

extension PenToolStateMutation on PenToolState {
  PenToolState addPoint(FusionCanvasPoint point) {
    return PenToolState(points: List<FusionCanvasPoint>.from(points)..add(point));
  }
}
