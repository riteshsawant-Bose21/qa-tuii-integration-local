part of 'canvas_toolbar.dart';

class SystemToolbar extends StatelessWidget {
  const SystemToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final FusionToolState toolState = context.watch<FusionCanvasToolViewModel>().state;
    return FusionFlatContainer(
      semanticsId: "system_toolbar",
      padding: const EdgeInsets.all(5),
      child: Row(
        children: <Widget>[
          _ToolBarIcon(
            icon: LucideIcons.music,
            label: "Speaker",
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
