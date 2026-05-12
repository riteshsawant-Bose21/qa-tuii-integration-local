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
          SemanticHelper.button(
            testId: SemanticHelper.createTestId(
              SemanticTypes.button,
              "add_sources",
            ),
            child: const AddSourceDrawer(
              isFromBuildingPage: true,
              child: _ToolBarIcon(
                icon: "source.png",
                label: "Add Source",
                isSelected: false,
                onTap: null,
              ),
            ),
          ),
          _ToolBarIcon(
            icon: "endpoint.png",
            label: "Add EndPoint",
            isSelected: false,
            onTap: () {
              AddEndpointDialog.show(
                context: context,
                category: EndpointDeviceCategory.endpoint,
              );
              // context.read<FusionCanvasStateViewModel>().fitToScreen();
            },
          ),
          _ToolBarIcon(
            icon: "wall_controller.png",
            label: "Add Controller",
            isSelected: false,
            onTap: () {
              AddControllerDialog.show(context);
              // context.read<FusionCanvasStateViewModel>().fitToScreen();
            },
          ),
        ];
        if (children.isEmpty) return const SizedBox();
        return Row(
          children: children,
        );
      },
    );
  }
}
