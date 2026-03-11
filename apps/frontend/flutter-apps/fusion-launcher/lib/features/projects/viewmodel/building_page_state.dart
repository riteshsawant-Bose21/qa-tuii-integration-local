import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPageState {
  final ToolbarMode toolbarMode;
  final SplState splState;

  BuildingPageState({required this.toolbarMode, required this.splState});

  @override
  bool operator ==(covariant BuildingPageState other) {
    if (identical(this, other)) return true;

    return other.toolbarMode == toolbarMode && other.splState == splState;
  }

  @override
  int get hashCode => toolbarMode.hashCode ^ splState.hashCode;
}

enum SplState {
  live,
  display,
  hidden,
}

enum DefaultTool {
  select,
  pen,
  measure,
}
