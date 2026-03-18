part of 'canvas_toolbar.dart';

class AcousticToolBar extends StatelessWidget {
  const AcousticToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final BuildingPageToolState toolState = context.watch<BuildingPageViewModel>().state.toolState;
    return Row(
      spacing: 8,
      children: <Widget>[
        _ToolBarIcon(
          icon: "pencil.png",
          label: "Pen",
          isSelected: toolState is DrawingListingAreaState,
          onTap: () => context.read<BuildingPageViewModel>().setTool(DrawingListingAreaState()),
        ),
        _ToolBarIcon(
          icon: "measure.png",
          label: "Measure",
          isSelected: toolState is MeasuringToolState,
          onTap: () => context.read<BuildingPageViewModel>().setTool(MeasuringToolState()),
        ),
        _ToolBarIcon(
          icon: "spl.png",
          label: "SPL",
          isSelected: toolState is SplToolState,
          onTap: () => context.read<BuildingPageViewModel>().setTool(SplToolState()),
        ),
        _ToolBarIcon(
          icon: "pointer.png",
          label: "Select",
          isSelected: toolState is SelectToolState,
          onTap: () => context.read<BuildingPageViewModel>().setTool(SelectToolState()),
        ),

       
      ],
    );
  }
}
