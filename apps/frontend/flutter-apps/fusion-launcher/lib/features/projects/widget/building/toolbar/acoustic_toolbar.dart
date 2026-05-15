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
          icon: "listening_area.png",
          label: "Listening Area",
          isSelected: toolState is ListeningAreaToolState,
          onTap: () => context.read<BuildingPageViewModel>().setTool(DrawingListeningAreaState(listeningAreaId: null)),
        ),

        BlocConsumer<ProjectViewModel, ProjectViewModelState>(
          listener: (BuildContext context, ProjectViewModelState state) {
            if (toolState is SplToolState) {
              final bool canCalculateSpl = context.read<SplViewModel>().canCalculateSPL();
              if (!canCalculateSpl) {
                context.read<BuildingPageViewModel>().setTool(SelectToolState());
              }
            }
          },
          builder: (BuildContext context, ProjectViewModelState state) {
            final bool canCalculateSpl = context.read<SplViewModel>().canCalculateSPL();
            return _ToolBarIcon(
              icon: "spl.png",
              label: "SPL",
              isEnabled: canCalculateSpl,
              isSelected: toolState is SplToolState,
              onTap: () => context.read<BuildingPageViewModel>().setTool(SplSelectToolState()),
            );
          },
        ),
        _ToolBarIcon(
          icon: "measure.png",
          label: "Measure",
          isSelected: toolState is MeasuringToolState,
          onTap: () => context.read<BuildingPageViewModel>().setTool(MeasuringToolState()),
        ),
        _ToolBarIcon(
          icon: "wall.png",
          label: "Wall",
          isSelected: toolState is WallToolState,
          onTap:
              () => context.read<BuildingPageViewModel>().setTool(
                DrawingWallState(
                  wallId: null,
                ),
              ),
        ),
        // _ToolBarIcon(
        //   icon: "pointer.png",
        //   label: "Select",
        //   isSelected: toolState is SelectToolState,
        //   onTap: () => context.read<BuildingPageViewModel>().setTool(SelectToolState()),
        // ),
      ],
    );
  }
}
