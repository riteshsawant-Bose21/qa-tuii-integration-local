import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/projects/view_model/spl_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nested/nested.dart';

import '../../../../fusion_canvas/state/tools/measure_tool_state.dart';
import '../../../../fusion_canvas/state/tools/pen_tool_state.dart';
import '../../../../fusion_canvas/state/tools/select_tool_state.dart' hide SelectToolState;
import '../../../../fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';
import '../../../viewmodel/building_page_state.dart';
import '../../../viewmodel/building_page_viewmodel.dart';

part '_tool_bar_icon.dart';
part 'acoustic_toolbar.dart';
part 'mode_selection_toolbar.dart';
part 'system_toolbar.dart';

class CanvasToolBar extends StatelessWidget {
  const CanvasToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ToolbarMode currentMode = context.watch<BuildingPageViewModel>().state.toolbarMode;

    return MultiBlocListener(
      listeners: <SingleChildWidget>[
        BlocListener<BuildingPageViewModel, BuildingPageState>(
          listenWhen: (BuildingPageState previous, BuildingPageState current) => previous.toolState.runtimeType != current.toolState.runtimeType,
          listener: (BuildContext context, BuildingPageState state) {
            if (state.toolState is SystemToolState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleSelectToolState());
            } else if (state.toolState is DrawingListingAreaState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdlePenToolState());
            } else if (state.toolState is MeasuringToolState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleMeasureToolState());
            } else if (state.toolState is SelectToolState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleSelectToolState());
            } else if (state.toolState is SpeakerPlacementState) {
            } else if (state.toolState is SplToolState) {
              context.read<SplViewModel>().calculateSPL();
            }
          },
        ),
      ],
      child: Row(
        children: <Widget>[
          const ModeSelectionToolbar(),
          AnimatedSwitcher(
            transitionBuilder:
                (Widget child, Animation<double> animation) =>
                    SlideTransition(position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation), child: child),
            duration: const Duration(milliseconds: 200),
            child: currentMode == ToolbarMode.acoustics ? const AcousticToolBar() : const SystemToolbar(),
          ),
        ],
      ),
    );
  }
}
