import '../fusion_tool_state.dart';

abstract class SelectToolState extends FusionToolState {}

class IdleSelectToolState extends SelectToolState {}

class SelectingSelectToolState extends SelectToolState {
  final List<String> selectedLayerIds;

  SelectingSelectToolState({required this.selectedLayerIds});
}
