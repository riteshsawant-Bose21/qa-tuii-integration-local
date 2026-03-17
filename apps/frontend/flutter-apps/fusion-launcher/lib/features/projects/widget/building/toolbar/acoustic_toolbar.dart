part of 'canvas_toolbar.dart';

class AcousticToolBar extends StatelessWidget {
  const AcousticToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final BuildingPageToolState toolState = context.watch<BuildingPageViewModel>().state.toolState;
    return FusionFlatContainer(
      semanticsId: "acoustic_toolbar",
      padding: const EdgeInsets.all(5),
      child: Row(
        spacing: 8,
        children: <Widget>[
          _ToolBarIcon(
            icon: LucideIcons.pencil100,
            label: "Pen",
            isSelected: toolState is DrawingListingAreaState,
            onTap: () => context.read<BuildingPageViewModel>().setTool(DrawingListingAreaState()),
          ),
          _ToolBarIcon(
            icon: LucideIcons.rulerDimensionLine200,
            label: "Measure",
            isSelected: toolState is MeasuringToolState,
            onTap: () => context.read<BuildingPageViewModel>().setTool(MeasuringToolState()),
          ),
          _ToolBarIcon(
            icon: LucideIcons.pointer,
            label: "SPL",
            isSelected: toolState is SplToolState,
            onTap: () => context.read<BuildingPageViewModel>().setTool(SplToolState()),
          ),
          _ToolBarIcon(
            icon: LucideIcons.pointer,
            label: "Select",
            isSelected: toolState is SelectToolState,
            onTap: () => context.read<BuildingPageViewModel>().setTool(SelectToolState()),
          ),
        ],
      ),
    );
  }
}
