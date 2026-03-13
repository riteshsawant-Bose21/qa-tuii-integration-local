import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/schematics/presentation/widgets/cost_calculator_widget.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/dock_item_config.dart';
import 'package:nested/nested.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../wiring_design/view/port_connection/port_connection_overlay.dart';
import '../../../view_model/spl_viewmodel.dart';
import '../../../viewmodel/building_page_viewmodel.dart';
import '../../../widget/building/building_canvas.dart';
import '../../../widget/building/side_panel_widgets/building_plan.dart';
import '../../../widget/building/side_panel_widgets/equipment_location/equipment_location_section.dart';
import '../../../widget/building/side_panel_widgets/listening_areas_panel.dart';
import '../../../widget/building/side_panel_widgets/properties_panel.dart';
import '../../../widget/building/side_panel_widgets/zone_and_listening_area.dart';
import '../../../widget/building/speaker_selection_section/side_speaker_section.dart';

class BuildingPage extends StatelessWidget {
  const BuildingPage({super.key, required this.floorCanvasController, required this.appBarHeight});
  final FloorCanvasController floorCanvasController;
  final double appBarHeight;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<BuildingPageViewModel>(
          create: (BuildContext context) => BuildingPageViewModel(),
        ),
      ],
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final ToolbarMode toolbarMode = context.watch<BuildingPageViewModel>().state.toolbarMode;
          final String? currentSelectedListeningAreaId = context.watch<ProjectViewModel>().currentSelectedListeningAreaId;

          return SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.buildingCanvas),
            child: BlocBuilder<SplViewModel, SplState>(
              builder: (BuildContext context, SplState state) {
                final SplViewModel viewModel = context.read<SplViewModel>();
                return BuildingCanvas(
                  splRangeController: viewModel.splRangeController,
                  onSplStateChanged: (bool value) {
                    // if (value) {
                    //   splController.expand();
                    // } else {
                    //   splController.collapse();
                    // }
                  },
                  floorCanvasController: floorCanvasController,
                  onCalculateSpl: () => viewModel.calculateSPL(),
                  splPanelData: state.panelData,
                  rightPanel: Builder(
                    builder: (BuildContext context) {
                      final List<DockItemConfig> createBuildingDockItems = _createBuildingDockItems(toolbarMode, floorCanvasController);
                      return Padding(
                        padding: EdgeInsets.only(top: appBarHeight, bottom: 20),
                        child: FusionFlatContainer(
                          semanticsId: "building_plan_right_panel",
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            constraints: BoxConstraints(maxHeight: context.screenHeight - appBarHeight - 20),
                            width: 237,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: createBuildingDockItems.length,
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                              itemBuilder: (BuildContext context, int index) => _DockItemPanel(dockItem: createBuildingDockItems[index]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  leftPanel: Padding(
                    padding: EdgeInsets.only(top: appBarHeight, bottom: 20),
                    child: FusionFlatContainer(
                      padding: const EdgeInsets.all(0),
                      child: SizedBox(
                        height: context.screenHeight - appBarHeight - 20,
                        width: 237,
                        child: FusionResizableSidebar(
                          sections: <FusionResizableSidebarSection>[
                            FusionResizableSidebarSection(
                              sementicId: 'building_plan_floors_list',
                              enableExpandCollapse: false,
                              stickToTop: true,
                              builder: (BuildContext context, bool isExpanded, VoidCallback toggleExpand, Animation<double> expandAnimation) {
                                return const BuildingPlan();
                              },
                            ),
                            FusionResizableSidebarSection(
                              sementicId: 'building_plan_listening_areas_zones_lists',
                              builder: (BuildContext context, bool isExpanded, VoidCallback toggleExpand, Animation<double> expandAnimation) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    FusionSidebarSectionHeader(
                                      title: toolbarMode == ToolbarMode.acoustics ? "LISTENING AREAS" : "ZONES",
                                      isExpanded: isExpanded,
                                      onTap: toggleExpand,
                                    ),
                                    Flexible(
                                      child: SizeTransition(
                                        sizeFactor: expandAnimation,
                                        child: switch (toolbarMode) {
                                          ToolbarMode.acoustics => ListeningAreasPanel(floorCanvasController: floorCanvasController),
                                          ToolbarMode.system => ZoneAndListeningAreaPanel(floorCanvasController: floorCanvasController),
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            if (toolbarMode == ToolbarMode.system)
                              FusionResizableSidebarSection(
                                sementicId: 'building_plan_equipment_location',
                                enableExpandCollapse: false,
                                stickToBottom: true,
                                builder: (BuildContext context, bool isExpanded, VoidCallback toggleExpand, Animation<double> expandAnimation) {
                                  return const EquipmentLocationSection();
                                },
                              ),

                            if (toolbarMode == ToolbarMode.acoustics && currentSelectedListeningAreaId != null)
                              FusionResizableSidebarSection(
                                sementicId: 'building_plan_equipment_location',
                                enableExpandCollapse: false,
                                stickToBottom: true,
                                builder: (BuildContext context, bool isExpanded, VoidCallback toggleExpand, Animation<double> expandAnimation) {
                                  return const SpeakerSelectionWidget();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<DockItemConfig> _createBuildingDockItems(ToolbarMode toolbarMode, FloorCanvasController floorCanvasController) {
    return <DockItemConfig>[
      // const DockItemConfig(
      //   id: "1",
      //   title: "FLOORS",
      //   side: "left",
      //   allowUndock: true,
      //   isCollapsibleSection: false,
      //   dockItemWidget: BuildingPlan(),
      // ),
      DockItemConfig(
        id: "5",
        title: "PROPERTIES",
        side: "right",
        initiallyExpanded: false,
        dockItemWidget: Builder(
          builder: (BuildContext context) {
            return PropertiesPanel(
              onSpeakerUpdated: () {
                context.read<SplViewModel>().calculateSPL();
              },
              onSpeakerDeleted: () {
                context.read<SplViewModel>().calculateSPL();
              },
            );
          },
        ),
      ),
      DockItemConfig(
        id: "6",
        title: "COST CALCULATOR",
        side: "right",
        allowUndock: true,
        dockItemWidget: CostCalculatorScreen(
          speakers: serviceLocator<ProjectViewModel>().speakers,
          sources: serviceLocator<ProjectViewModel>().sources,
          controllers: serviceLocator<ProjectViewModel>().fusionControllers,
          racks:
              serviceLocator<ProjectViewModel>().genericHardwareComponents
                  .where(
                    (GenericHardwareComponent component) => component.type == GenericHardwareComponentType.rack,
                  )
                  .toList(),
          amplifiers: <Amplifier>[],
          fusionDevices: <FusionDsp>[],
          others:
              serviceLocator<ProjectViewModel>().genericHardwareComponents
                  .where(
                    (HardwareComponent component) => component is GenericHardwareComponent && component.type == GenericHardwareComponentType.other,
                  )
                  .toList(),
        ),
      ),

      DockItemConfig(
        id: "9",
        title: "SPL MAPPING",
        side: "right",
        // controller: splController,
        dockItemWidget: BlocBuilder<SplViewModel, SplState>(
          builder: (BuildContext context, SplState state) {
            final SplViewModel viewModel = context.read<SplViewModel>();
            return SplPanel(
              controller: viewModel.splRangeController,
              initialData: state.panelData,
              onChanged: (SplPanelData value) {
                viewModel.updatePanelData(value);
              },
            );
          },
        ),
      ),
    ];
  }
}

class _DockItemPanel extends StatelessWidget {
  const _DockItemPanel({
    super.key,
    required this.dockItem,
  });

  final DockItemConfig dockItem;

  @override
  Widget build(BuildContext context) {
    return FusionExpansionPanel(
      semanticsId: "dock_${dockItem.id}",
      initiallyExpanded: false,
      content: dockItem.dockItemWidget,
      titleBuilder:
          (BuildContext context, bool isOpen) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      dockItem.title,
                      style: context.textTheme.l1Regular,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 250),
                  turns: isOpen ? 0.25 : 0.0,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
