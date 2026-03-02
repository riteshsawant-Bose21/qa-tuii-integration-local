import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../fusion_canvas/state/tools/measure_tool_state.dart';
import '../../../../fusion_canvas/state/tools/pen_tool_state.dart';
import '../../../../fusion_canvas/state/tools/select_tool_state.dart';
import '../../../../fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';

class CanvasToolSelectionToolbar extends StatelessWidget {
  const CanvasToolSelectionToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final FusionToolState toolState = context.watch<FusionCanvasToolViewModel>().state;
    return FusionFlatContainer(
      semanticsId: "canvas_tool_selection_toolbar",
      padding: const EdgeInsets.all(5),
      child: Row(
        children: <Widget>[
          _ToolBarIcon(
            icon: LucideIcons.pencil100,
            label: "Pen",
            isSelected: toolState is PenToolState,
            onTap: () => context.read<FusionCanvasToolViewModel>().setTool(IdlePenToolState()),
          ),
          const SizedBox(width: 8),
          _ToolBarIcon(
            icon: LucideIcons.rulerDimensionLine200,
            label: "Measure",
            isSelected: toolState is MeasureToolState,
            onTap: () => context.read<FusionCanvasToolViewModel>().setTool(IdleMeasureToolState()),
          ),
          const SizedBox(width: 8),
          _ToolBarIcon(
            icon: LucideIcons.pointer,
            label: "Select",
            isSelected: toolState is SelectToolState,
            onTap: () => context.read<FusionCanvasToolViewModel>().setTool(IdleSelectToolState()),
          ),
        ],
      ),
    );
  }
}

class _ToolBarIcon extends StatelessWidget {
  const _ToolBarIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: FusionFlatContainer(
        semanticsId: "canvas_tool_${label.toLowerCase()}",
        color: isSelected ? context.colorScheme.elevation3 : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        borderColor: Colors.transparent,
        child: Icon(icon),
      ),
    );
  }
}
