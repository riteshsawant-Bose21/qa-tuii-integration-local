import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_state.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPageViewModel extends Cubit<BuildingPageState> {
  BuildingPageViewModel()
    : super(
        BuildingPageState.defaultAcousticsState(),
      );

  void toggleMode(ToolbarMode mode) {
    if (mode == ToolbarMode.acoustics) {
      emit(BuildingPageState.defaultAcousticsState());
    } else {
      emit(BuildingPageState.defaultSystemState());
    }
  }
}
