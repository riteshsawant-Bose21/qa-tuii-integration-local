import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/create_zone_popup.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_state.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/spl/building_spl_panel.dart';
import 'package:fusion_launcher/features/schematics/presentation/widgets/cost_calculator_widget.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nested/nested.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../speaker_selection_popup/views/widgets/side_speaker_section.dart';
import '../../../../wiring_design/view/port_connection/port_connection_overlay.dart';
import '../../../view_model/spl_viewmodel.dart';
import '../../../viewmodel/building_page_viewmodel.dart';
import '../../../widget/building/building_canvas.dart';
import '../../../widget/building/side_panel_widgets/side_panel_widgets.dart';

class BuildingPage extends StatelessWidget {
  const BuildingPage({super.key, required this.floorCanvasController, required this.appBarHeight});
  final FloorCanvasController floorCanvasController;
  final double appBarHeight;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<BuildingPageViewModel>(
          create:
              (BuildContext context) => BuildingPageViewModel(
                projectViewModel: context.read<ProjectViewModel>(),
              ),
        ),
      ],
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          return SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.buildingCanvas),
            child: BlocBuilder<SplViewModel, SplState>(
              builder: (BuildContext context, SplState state) {
                final SplViewModel viewModel = context.read<SplViewModel>();
                return BuildingCanvas(
                  splRangeController: viewModel.splRangeController,
                  onSplStateChanged: (bool value) {},
                  onCalculateSpl: () => viewModel.autoCalculateSpl(),
                  splPanelData: state.panelData,
                  rightPanel: Builder(
                    builder: (BuildContext context) {
                      return Padding(
                        padding: EdgeInsets.only(top: appBarHeight, bottom: 20),
                        child: FusionFlatContainer(
                          color: Colors.transparent,
                          borderColor: Colors.transparent,
                          semanticsId: "building_plan_right_panel",
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: Container(
                            constraints: BoxConstraints(maxHeight: context.screenHeight - appBarHeight - 20),
                            width: 237,
                            child: const _RightPanel(),
                          ),
                        ),
                      );
                    },
                  ),
                  leftPanel: Padding(
                    padding: EdgeInsets.only(top: appBarHeight, bottom: 20),
                    child: _LeftPanel(
                      appBarHeight: appBarHeight,
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
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    super.key,
    required this.appBarHeight,
  });

  final double appBarHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final BuildingPageState buildingPageState = context.watch<BuildingPageViewModel>().state;
        final ToolbarMode toolbarMode = buildingPageState.toolbarMode;
        final String? currentSelectedListeningAreaId = buildingPageState.selectedListeningAreaId;
        return FusionFlatContainer(
          semanticsId: 'building_left_side_panel',
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
                          isExpanded: true,
                          showChevron: false,
                          // onTap: toggleExpand,
                          trailing: Builder(
                            builder: (BuildContext context) {
                              if (toolbarMode == ToolbarMode.acoustics) return const SizedBox();

                              return GuideShowcaseWrapper(
                                semanticId: 'zone_and_listening_area',
                                step: GuideShowCaseSteps.addZone,
                                // onHighlightedSpotTap: (TapDownDetails details) => _addNewZone(),
                                child: CreateZonePopup(
                                  isFromBuildingPage: true,
                                  child: Icon(
                                    LucideIcons.plus200,
                                    size: 16,
                                    color: context.colorScheme.iconWhite,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Flexible(
                          child: SizeTransition(
                            sizeFactor: expandAnimation,
                            child: switch (toolbarMode) {
                              ToolbarMode.acoustics => const ListeningAreasPanel(),
                              ToolbarMode.system => const ZoneAndListeningAreaPanel(),
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
                    sementicId: 'building_plan_speaker_selection',
                    enableExpandCollapse: false,
                    stickToBottom: true,
                    builder: (BuildContext context, bool isExpanded, VoidCallback toggleExpand, Animation<double> expandAnimation) {
                      return const SpeakerSelectionWidget();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DockItemPanel extends StatelessWidget {
  const _DockItemPanel({super.key, this.action, required this.id, required this.title, required this.content});
  final String title;
  final String id;
  final Widget? action;
  final Widget content;
  @override
  Widget build(BuildContext context) {
    return FusionFlatContainer(
      padding: const EdgeInsets.all(0),
      child: FusionExpansionPanel(
        semanticsId: "dock_$id",
        initiallyExpanded: false,
        content: Column(
          children: <Widget>[
            const Divider(),
            content,
          ],
        ),
        titleBuilder:
            (BuildContext context, bool isOpen) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    turns: isOpen ? 0 : -0.25,
                    child: Icon(
                      Icons.arrow_drop_down_rounded,
                      // size: 12,
                      size: 25,
                      color: context.colorScheme.iconWhite,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        title,
                        style: context.textTheme.l1Regular,
                      ),
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const _DockItemPanel(
          title: "COST CALCULATOR",
          id: "cost_calculator",
          content: CostCalculatorScreen(),
        ),
        _DockItemPanel(
          id: "properties",
          title: "PROPERTIES",
          content: Builder(
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
        // BlocBuilder<SplViewModel, SplState>(
        //   builder: (BuildContext context, SplState state) {
        //     final SplViewModel viewModel = context.read<SplViewModel>();
        //     return _DockItemPanel(
        //       title: "SPL MAPPING",
        //       id: "spl_mapping",
        //       content: SplPanel(
        //         controller: viewModel.splRangeController,
        //         initialData: state.panelData,
        //         onChanged: (SplPanelData value) {
        //           viewModel.updatePanelData(value);
        //         },
        //       ),
        //     );
        //   },
        // ),
        BlocBuilder<SplViewModel, SplState>(
          builder: (BuildContext context, SplState state) {
            final SplViewModel viewModel = context.read<SplViewModel>();
            return FusionSubMenu(
              child: Builder(
                builder: (BuildContext context) {
                  return _DockItemPanel(
                    title: "SPL MAPPING",
                    id: "spl_mapping",
                    action: Row(
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            FusionSubMenu.of(context).showMenu(
                              content: SizedBox(
                                width: 300,
                                child: BlocProvider<SplViewModel>.value(value: viewModel, child: const FusionFlatContainer(child: SplSettingPanel())),
                              ),
                            );
                          },
                          child: const Icon(
                            LucideIcons.settings,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    content: const BuildingSplPanel(),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
