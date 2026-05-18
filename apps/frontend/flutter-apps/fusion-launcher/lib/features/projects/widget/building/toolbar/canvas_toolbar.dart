import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/add_source_popup/view/add_source_popup.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_dialog.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/rectangle_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_state_viewmodel.dart';
import 'package:fusion_launcher/features/projects/presentation/project_work_area.dart';
import 'package:fusion_launcher/features/projects/view_model/spl_viewmodel.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/equipment_location/parts/endpointdialog.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart';

import '../../../../fusion_canvas/state/fusion_tool_state.dart';
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
part 'ternary_toolbar.dart';

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
            } else if (state.toolState is DrawingListeningAreaState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdlePenToolState());
            } else if (state.toolState is DrawingRectangleListeningAreaState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleRectangleToolState());
            } else if (state.toolState is DrawingWallState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdlePenToolState());
            } else if (state.toolState is MeasuringToolState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleMeasureToolState());
            } else if (state.toolState is SelectToolState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleSelectToolState());
            } else if (state.toolState is SpeakerPlacementState) {
              // context.read<FusionCanvasToolViewModel>().setTool(IdleSelectToolState());
            } else if (state.toolState is SplToolState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleSelectToolState());
              context.read<SplViewModel>().calculateSPL();
            } else if (state.toolState is WallSelectToolState) {
              context.read<FusionCanvasToolViewModel>().setTool(IdleSelectToolState());
            }
          },
        ),
      ],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const ModeSelectionToolbar(),
          FusionFlatContainer(
            semanticsId: currentMode == ToolbarMode.acoustics ? "acoustic_toolbar" : "system_toolbar",
            padding: const EdgeInsets.all(5),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: <Widget>[
                  AnimatedSwitcher(
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder:
                        (Widget child, Animation<double> animation) => SlideTransition(
                          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                    duration: const Duration(milliseconds: 200),
                    child: currentMode == ToolbarMode.acoustics ? const AcousticToolBar() : const SystemToolbar(),
                  ),
                  _ToolBarIcon(
                    icon: "fit_to_screen.png",
                    label: "Fit to Screen",
                    isSelected: false,
                    onTap: () {
                      context.read<FusionCanvasStateViewModel>().fitToScreen(
                        padding: EdgeInsets.only(left: 250, right: 250, top: WorkAreaScope.of(context).appBarHeight, bottom: 20 + 50),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: _TernaryToolbar(),
          ),
        ],
      ),
    );
  }
}
