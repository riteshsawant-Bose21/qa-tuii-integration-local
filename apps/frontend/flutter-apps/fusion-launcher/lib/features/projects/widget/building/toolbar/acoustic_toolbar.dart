

part of 'canvas_toolbar.dart';

class AcousticToolBar extends StatelessWidget {
  const AcousticToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final FusionToolState toolState = context.watch<FusionCanvasToolViewModel>().state;
    return FusionFlatContainer(
      semanticsId: "acoustic_toolbar",
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
