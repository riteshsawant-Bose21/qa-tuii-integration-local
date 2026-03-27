// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fusion_launcher/core/service_locator.dart';
// import 'package:fusion_lib/fusion_lib.dart';

// import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

part of 'canvas_toolbar.dart';

class ModeSelectionToolbar extends StatelessWidget {
  const ModeSelectionToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final ToolbarMode currentMode = context.watch<BuildingPageViewModel>().state.toolbarMode;

    return FusionFlatContainer(
      semanticsId: "building_mode_selection_toolbar",
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: <Widget>[
          for (final ToolbarMode mode in ToolbarMode.values)
            InkWell(
              onTap: () => context.read<BuildingPageViewModel>().toggleMode(mode),

              child: FusionFlatContainer(
                semanticsId: "toolbar_mode_${mode.name.toLowerCase()}",
                color: currentMode == mode ? context.colorScheme.primary : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                borderColor: Colors.transparent,
                child: Text(mode.name.toUpperCase()),
              ),
            ),
        ],
      ),
    );
  }
}
