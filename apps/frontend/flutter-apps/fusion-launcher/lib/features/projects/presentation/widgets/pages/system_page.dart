import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/dock_item_config.dart';

import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../schematics/presentation/pages/schematics_page.dart';
import '../../../../schematics/presentation/widgets/cost_calculator_widget.dart';
import '../../../../wiring_design/view/wiring_device_list_view.dart';
import '../../../widget/building/side_panel_widgets/schematic_properties.dart';

class SystemPage extends StatelessWidget {
  const SystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
        final bool isListingViewMode = context.read<ProjectViewModel>().currentProjectMode == ProjectMode.systemListingMode;
        return FusionDockableArea(
          tabKey: "schematics_tab",
          showLeft: isListingViewMode ? false : true,
          showRight: true,
          mainArea: const SchematicsPage(),
          dockItemList: <DockItemConfig>[
            DockItemConfig(
              id: "11",
              title: "PROPERTIES",
              side: "right",
              initiallyExpanded: true,
              allowUndock: false,
              isCollapsibleSection: false,
              dockItemWidget: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        projectViewModel.setProjectMode(ProjectMode.systemListingMode);
                      },
                      child: SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.listingViewIcon),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isListingViewMode ? context.colorScheme.elevation3 : Colors.transparent,
                          ),
                          child: FusionIcon.svg(
                            AssetSvg.listingViewIcon,
                            size: 40,
                            color: context.colorScheme.primaryWhite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        projectViewModel.setProjectMode(ProjectMode.systemWiringMode);
                      },
                      child: SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.wiringViewIcon),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isListingViewMode ? Colors.transparent : context.colorScheme.elevation3,
                          ),
                          child: FusionIcon.svg(
                            AssetSvg.wiringViewIcon,
                            size: 40,
                            color: context.colorScheme.primaryWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const DockItemConfig(
              id: "5",
              title: "PROPERTIES",
              side: "right",
              initiallyExpanded: true,
              allowUndock: false,
              dockItemWidget: SchematicProperties(),
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
            // DockItemConfig(
            //   id: "8",
            //   title: "PRODUCT QUERY",
            //   side: "right",
            //   dockItemWidget: () => const ProductQueryView(),
            // ),
            const DockItemConfig(
              id: "10",
              title: "PRODUCT LIST",
              side: "left",
              initiallyExpanded: true,
              dockItemWidget: WiringDeviceListView(),
            ),
          ],
        );
      },
    );
  }
}
