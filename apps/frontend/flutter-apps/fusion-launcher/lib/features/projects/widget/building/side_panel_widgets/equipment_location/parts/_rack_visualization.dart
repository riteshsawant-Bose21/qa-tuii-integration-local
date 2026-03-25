part of '../equipment_location_dialog.dart';

class _EQLRackPreview extends StatelessWidget {
  const _EQLRackPreview({this.equipmentLocationId});
  final String? equipmentLocationId;
  @override
  Widget build(BuildContext context) {
    return BlocProvider<EquipmentLocationViewmodel>(
      key: ValueKey<String>("rack_$equipmentLocationId"),
      create:
          (BuildContext context) => EquipmentLocationViewmodel(
            BlocProvider.of<ProjectViewModel>(context),
            equipmentLocationId,
          ),
      child: BlocListener<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          if (state is ProjectUpdated) {
            BlocProvider.of<EquipmentLocationViewmodel>(context).refresh();
          }
        },
        child: BlocBuilder<EquipmentLocationViewmodel, EquipmentLocationState>(
          builder: (BuildContext context, EquipmentLocationState? state) {
            if (state is! EquipmentLocationLoaded) {
              return BlocBuilder<EqlProductsVm, EQLProductsState>(
                builder: (BuildContext context, EQLProductsState eqlProductsState) {
                  return const Center(
                    child: FusionAppText(
                      text: "Please select a equipment location to add devices.",
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              );
            }
            final int length = max(10, state.hardwares.length);
            final double height = 32.0;
            return Center(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 250,
                    child: SemanticHelper.container(
                      testId: SemanticHelper.createTestId(SemanticTypes.container, "rack"),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: "Rack $length Units",
                            style: context.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            color: Colors.grey.shade300,

                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              height: (height * (length)),
                              child: ReorderableListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                onReorder: (int oldIndex, int newIndex) {
                                  final int adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
                                  BlocProvider.of<EquipmentLocationViewmodel>(context).reorderHardware(oldIndex, adjustedNewIndex);
                                },
                                itemCount: length,
                                buildDefaultDragHandles: false,
                                itemBuilder: (BuildContext context, int index) {
                                  return Center(
                                    key: ValueKey<int>(index),
                                    child: LayoutBuilder(
                                      builder: (BuildContext context, BoxConstraints constraints) {
                                        return Container(
                                          height: height,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            // border: const Border(
                                            //   bottom: BorderSide(color: Colors.black, width: 2),
                                            // ),
                                          ),
                                          child: Stack(
                                            children: <Widget>[
                                              if (index < length - 1)
                                                Align(
                                                  alignment: Alignment.bottomCenter,
                                                  child: Container(
                                                    width: constraints.maxWidth,
                                                    height: 2,
                                                    color: context.colorScheme.surface,
                                                  ),
                                                ),
                                              Center(
                                                child: Container(
                                                  width: constraints.maxWidth * 0.8,
                                                  height: double.maxFinite,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xfff1a1a18),
                                                    border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade200, width: 5)),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topCenter,
                                                child: Builder(
                                                  builder: (BuildContext context) {
                                                    final HardwareComponent? hardware = state.hardwares[index];
                                                    if (hardware != null) {
                                                      return ReorderableDragStartListener(
                                                        index: index,
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(top: 2),
                                                          child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.center,

                                                            children: <Widget>[
                                                              SizedBox(width: constraints.maxWidth * 0.05),
                                                              Container(
                                                                width: (constraints.maxWidth * 0.05) + 5,
                                                                height: 25,
                                                                color: Colors.black54,
                                                                child: const Icon(Icons.more_vert, color: Colors.white54, size: 12),
                                                              ),

                                                              Container(
                                                                width: constraints.maxWidth * 0.8 - 10,
                                                                color: Colors.black,
                                                                height: 25,
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(4.0),
                                                                  child: HoverWidgetBuilder(
                                                                    builder: (BuildContext context, bool isHovered) {
                                                                      return Row(
                                                                        children: <Widget>[
                                                                          Expanded(
                                                                            child: FusionAppText(
                                                                              text: hardware.name,
                                                                              maxLine: 1,
                                                                              style: context.textTheme.bodySmall?.copyWith(
                                                                                color: Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          if (isHovered)
                                                                            InkWell(
                                                                              onTap: () {
                                                                                BlocProvider.of<ProjectViewModel>(context).removeHardware(
                                                                                  hardwareId: hardware.id,
                                                                                );
                                                                              },
                                                                              child: SemanticHelper.button(
                                                                                testId: SemanticHelper.createTestId(
                                                                                  SemanticTypes.button,
                                                                                  "equipment_location_section_item_remove_button_$index",
                                                                                ),
                                                                                child: const Icon(
                                                                                  LucideIcons.trash2600,
                                                                                  size: 12,
                                                                                  color: Colors.red,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                width: (constraints.maxWidth * 0.05) + 5,
                                                                height: 25,
                                                                color: Colors.black54,
                                                                child: const Icon(Icons.more_vert, color: Colors.white54, size: 12),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    return const SizedBox();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Container(
                                height: 20,
                                width: 30,
                                color: context.colorScheme.strokeLight,
                              ),
                              const SizedBox(),
                              Container(
                                height: 20,
                                width: 30,
                                color: context.colorScheme.strokeLight,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HoverWidgetBuilder extends StatefulWidget {
  const HoverWidgetBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, bool isHovered) builder;
  @override
  State<HoverWidgetBuilder> createState() => _HoverWidgetBuilderState();
}

class _HoverWidgetBuilderState extends State<HoverWidgetBuilder> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (PointerEnterEvent event) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (PointerExitEvent event) {
        setState(() {
          _isHovered = false;
        });
      },
      child: widget.builder(context, _isHovered),
    );
  }
}
