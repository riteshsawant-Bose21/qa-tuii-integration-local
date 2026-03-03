import '../../view/painters/fusion_canvas_painter.dart';
import '../fusion_tool_state.dart';

abstract class SelectToolState extends FusionToolState {}

class IdleSelectToolState extends SelectToolState {}

class SelectingSelectToolState extends SelectToolState {
  final List<FusionBasePainter> selectedLayerIds;

  SelectingSelectToolState({required this.selectedLayerIds});
}
