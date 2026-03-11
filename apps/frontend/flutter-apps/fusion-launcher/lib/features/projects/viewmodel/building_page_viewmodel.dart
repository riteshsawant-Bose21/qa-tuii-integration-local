import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_state.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPageViewModel extends Cubit<BuildingPageState> {
  BuildingPageViewModel()
    : super(
        BuildingPageState(toolbarMode: ToolbarMode.acoustics, splState: SplState.hidden),
      );

  void toggleMode(ToolbarMode mode) {
    emit(BuildingPageState(toolbarMode: mode, splState: state.splState));
  }
}
