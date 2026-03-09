import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../fusion_canvas/state/tools/measure_tool_state.dart';
import '../../../../fusion_canvas/state/tools/pen_tool_state.dart';
import '../../../../fusion_canvas/state/tools/select_tool_state.dart';
import '../../../../fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';

part '_tool_bar_icon.dart';
part 'acoustic_toolbar.dart';
part 'mode_selection_toolbar.dart';
part 'system_toolbar.dart';

class CanvasToolBar extends StatelessWidget {
  const CanvasToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ToolbarMode currentMode = context.watch<ProjectViewModel>().currentToolbarMode;

    return Row(
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
    );
  }
}
