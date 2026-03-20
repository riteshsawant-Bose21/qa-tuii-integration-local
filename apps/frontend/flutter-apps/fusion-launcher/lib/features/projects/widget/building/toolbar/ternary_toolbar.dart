part of 'canvas_toolbar.dart';

class _TernaryToolbar extends StatelessWidget {
  const _TernaryToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final BuildingPageToolState currentMode = context.watch<BuildingPageViewModel>().state.toolState;
    final List<Widget> children = <Widget>[
      ...switch (currentMode) {
        ListeningAreaToolState() => <Widget>[
          _ToolBarIcon(
            icon: "pencil.png",
            label: "Draw",
            isSelected: currentMode is DrawingListeningAreaState,
            onTap: () {
              context.read<BuildingPageViewModel>().setTool(DrawingListeningAreaState());
            },
          ),
          _ToolBarIcon(
            icon: "pointer.png",
            label: "Select",
            isSelected: currentMode is SelectToolState,
            onTap: () {
              context.read<BuildingPageViewModel>().setTool(SelectToolState());
            },
          ),
        ],
        MeasuringToolState() => <Widget>[
          BlocBuilder<FusionCanvasToolViewModel, FusionToolState>(
            builder: (BuildContext context, FusionToolState state) {
              final FusionToolState toolState = state;
              if (state is! MeasureToolState) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Row(
                  spacing: 8,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.colorScheme.primary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FusionAppText(
                        semanticId: "measure_value_text",
                        text: switch (state) {
                          DrawingMeasureToolState(
                            :final Offset start,
                            :final Offset end,
                          ) =>
                            ((start - end).distance / 100).toStringAsFixed(2),
                          _ => "0.00",
                        },
                      ),
                    ),
                    FusionAppText(
                      text: "M",
                      semanticId: "measure_unit_text",
                      style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.textGrey),
                    ),
                    const SizedBox(
                      width: 1,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        _ => <Widget>[],
      },
    ];
    if (children.isEmpty) {
      return const SizedBox();
    }
    return FusionFlatContainer(
      semanticsId: "ternary_system_toolbar",
      padding: const EdgeInsets.all(5),
      child: Row(
        children: children,
      ),
    );
  }
}
