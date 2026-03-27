part of 'canvas_toolbar.dart';

class SystemToolbar extends StatelessWidget {
  const SystemToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuildingPageViewModel, BuildingPageState>(
      builder: (BuildContext context, BuildingPageState state) {
        final BuildingPageToolState toolState = state.toolState;
        final BuildingPageViewModel buildingPageViewModel = context.read<BuildingPageViewModel>();
        final List<Widget> children = <Widget>[
          if (buildingPageViewModel.state.selectedListeningAreaId != null)
            SemanticHelper.button(
              testId: SemanticHelper.createTestId(
                SemanticTypes.button,
                "add_sources",
              ),
              child: const AddSourcePopup(
                isFromBuildingPage: true,
                child: _ToolBarIcon(
                  icon: "source.png",
                  label: "Add Source",
                  isSelected: false,
                  onTap: null,
                ),
              ),
            ),
          // _ToolBarIcon(
          //   icon: "fit_to_screen.png",
          //   label: "Fit to Screen",
          //   isSelected: false,
          //   onTap: () {
          //     context.read<FusionCanvasStateViewModel>().fitToScreen();
          //   },
          // ),
        ];
        if (children.isEmpty) return const SizedBox();
        return Row(
          children: children,
        );
      },
    );
  }
}
