import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/schematic_amplifier_viewmodel.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/schematic_fusion_dsp_viewmodel.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/schematic_hardware_rack_viewmodel.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/schematic_zone_viewmodel.dart';
import 'package:fusion_launcher/features/schematics/views/widgets/forms/schematic_add_device_form.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/products_data.dart';
import '../../../../core/service_locator.dart';
import '../../../add_source_popup/view/add_source_popup.dart' show AddSourcePopup;
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../create_zone_popup/view/create_zone_popup.dart';
import '../../../product_query/presentation/pages/product_query.dart';
import '../../../projects/viewmodel/eql_products_vm.dart';
import '../../../projects/widget/building/side_panel_widgets/equipment_location/equipment_location_dialog.dart';
import '../../state/device_listing_state.dart';
import '../../viewmodel/endpoints_viewmodel.dart';
import '../../viewmodel/schematic_fusion_controller_viewmodel.dart';
import '../../viewmodel/schematic_network_switch_viewmodel.dart';
import '../../viewmodel/schematic_sources_viewmodel.dart';
import '../../viewmodel/search_control_viewmodel.dart';
import '../../views/widgets/schematic_hardware_listing.dart';
import '../../views/widgets/schematic_listing_section.dart';
import '../../views/widgets/schematic_section.dart';
import '../widgets/add_device_expandable_popup_menu_widget.dart';
import '../widgets/expandable_zone_widget.dart';

class SchematicsListingview extends StatefulWidget {
  const SchematicsListingview({super.key});

  @override
  State<SchematicsListingview> createState() => _SchematicsListingviewState();
}

class _SchematicsListingviewState extends State<SchematicsListingview> {
  /// Get ProjectViewModel instance
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  void dispose() {
    _projectViewModel.clearSelections();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "schematic_listing_view_area"),
          child: Container(
            color: context.colorScheme.primaryBlack,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ///------------------------------------------------------------------------------------------------------------------------------------------
                ///
                /// 1. Sources & Endpoints
                ///
                ///------------------------------------------------------------------------------------------------------------------------------------------
                Expanded(
                  flex: 2,
                  child: SchematicListingSection(
                    sectionTitle: "Sources & Endpoints",
                    sections: <Widget>[
                      SchematicHardwareListing<Source, SchematicSourcesViewModel>(
                        create: (BuildContext context) {
                          return SchematicSourcesViewModel();
                        },
                        title: "Sources",
                        addAction: AddSourcePopup(
                          isFromBuildingPage: false,
                          child: Icon(
                            LucideIcons.plus200,
                            size: 16,
                            color: context.colorScheme.primaryWhite,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SchematicHardwareListing<FusionEndpoints, SchematicEndpointsViewModel>(
                        create: (BuildContext context) {
                          return SchematicEndpointsViewModel();
                        },
                        title: "Endpoints",
                        addAction: FusionArrowPopup(
                          content: const EquipmentLocationDialog(
                            currentFilter: EQLDeviceType.endpoint,
                          ),
                          child: Icon(
                            LucideIcons.plus200,
                            size: FusionSizes.iconSize16,
                            color: context.colorScheme.primaryWhite,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                ///------------------------------------------------------------------------------------------------------------------------------------------
                ///
                /// 2. Processors & Amplifiers
                ///
                ///------------------------------------------------------------------------------------------------------------------------------------------
                Expanded(
                  flex: 2,
                  child: SchematicListingSection(
                    sectionTitle: "Processors & Amplifiers",
                    sections: <Widget>[
                      SchematicHardwareListing<FusionDsp, SchematicFusionDeviceViewModel>(
                        create: (BuildContext context) {
                          return SchematicFusionDeviceViewModel();
                        },
                        title: "Fusion Devices",
                        addAction: FusionArrowPopup(
                          content: const EquipmentLocationDialog(
                            currentFilter: EQLDeviceType.processor,
                          ),
                          child: Icon(
                            LucideIcons.plus200,
                            size: FusionSizes.iconSize16,
                            color: context.colorScheme.primaryWhite,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SchematicHardwareListing<Amplifier, SchematicAmplifiersViewModel>(
                        create: (BuildContext context) {
                          return SchematicAmplifiersViewModel();
                        },
                        title: "Amplifiers",
                        addAction: FusionArrowPopup(
                          content: const EquipmentLocationDialog(
                            currentFilter: EQLDeviceType.amplifier,
                          ),
                          child: Icon(
                            LucideIcons.plus200,
                            size: FusionSizes.iconSize16,
                            color: context.colorScheme.primaryWhite,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                ///------------------------------------------------------------------------------------------------------------------------------------------
                ///
                /// 3. Zones
                ///
                ///------------------------------------------------------------------------------------------------------------------------------------------
                Expanded(
                  flex: 3,
                  child: SchematicListingSection(
                    sectionTitle: "Speakers",
                    action: CreateZonePopup(
                      isFromBuildingPage: false,
                      child: SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, "add_zone_button_speakers"),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              LucideIcons.plus200,
                              size: FusionSizes.iconSize12,
                              color: context.colorScheme.iconWhite,
                            ),
                            const SizedBox(width: 6),
                            FusionAppText(
                              text: "Add Zone",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 8,
                                color: Theme.of(context).colorScheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ),
                    sections: <Widget>[
                      SchematicSection<Zone, SchematicZoneViewModel>(
                        create: (BuildContext context) {
                          return SchematicZoneViewModel();
                        },
                        builder: (BuildContext context, DeviceListingState<Zone> state) {
                          final SearchResultsViewModel read = context.read<SearchResultsViewModel>();
                          read.updateResults(state.devices.map((Zone e) => e.id).toList());
                          final List<Zone> devices = state.devices;
                          if (devices.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              child: Center(
                                child: FusionAppText(
                                  text: state is DeviceSearchingState ? "No matching zones found" : "No zones added",
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontSize: FusionSizes.fontSize12,
                                    color: context.colorScheme.textBody,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ReorderableColumn<Zone>(
                            items: devices,
                            onReorder: (int oldIndex, int newIndex) {
                              _projectViewModel.reorderZones(zoneIdToMove: devices[oldIndex].id, zoneIdAtNewIndex: devices[newIndex].id);
                            },
                            itemBuilder: (BuildContext context, Zone zone) {
                              return ExpandableZoneWidget(
                                index: devices.indexOf(zone),
                                zoneName: zone.name,
                                zoneId: zone.id,
                                bgColor: zone.color,
                                initiallyExpanded: true,
                                zoneCircuits: _projectViewModel.getCircuitsInZone(zone.id),
                                subZones: _projectViewModel.getSubZonesForZone(parentZoneId: zone.id),
                                onDelete: (String id) {
                                  serviceLocator<ProjectViewModel>().removeZone(zoneId: zone.id);
                                  FusionToast.error(context, message: 'Zone "${zone.name}" deleted');
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                ///------------------------------------------------------------------------------------------------------------------------------------------
                ///
                /// 4. Controllers
                ///
                ///------------------------------------------------------------------------------------------------------------------------------------------
                Expanded(
                  flex: 2,
                  child: SchematicListingSection(
                    sectionTitle: "Controllers",
                    action: FusionArrowPopup(
                      semanticsId: "add_controller_popup",
                      content: SchematicAddDeviceForm<ProductQueryModel>(
                        semanticsId: "controllers",
                        products: ProductAPI.getControllers(),
                        itemLabel: (ProductQueryModel value) => value.name,
                        itemImage: (ProductQueryModel value) => value.image,
                        onSubmit: (String areaId, String floorId, ProductQueryModel device) {
                          final HardwareComponent hardware = serviceLocator<ProjectViewModel>().fromProductQueryModel(
                            device,
                            locationEntity: LocationModel(
                              listeningAreaId: areaId,
                              floorId: floorId,
                            ),
                            isFromBuildingPage: false,
                          );

                          serviceLocator<ProjectViewModel>().addHardware(
                            hardware: hardware,
                          );
                          FusionToast.success(
                            context,
                            message: "Controller \"${device.name}\" added",
                          );
                          Navigator.of(context).pop();
                          return true;
                        },
                      ),
                      child: SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, "add_controller"),
                        child: Icon(
                          LucideIcons.plus200,
                          size: FusionSizes.iconSize16,
                          color: context.colorScheme.primaryWhite,
                        ),
                      ),
                    ),
                    sections: <Widget>[
                      SchematicHardwareListing<FusionController, SchematicFusionControllerViewModel>(
                        create: (BuildContext context) {
                          return SchematicFusionControllerViewModel();
                        },
                        title: "Controllers",
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                ///------------------------------------------------------------------------------------------------------------------------------------------
                ///
                /// 5. Accessories
                ///
                ///------------------------------------------------------------------------------------------------------------------------------------------
                Expanded(
                  flex: 2,
                  child: SchematicListingSection(
                    sectionTitle: "Accessories",
                    action: AddDeviceExpandablePopupMenuWidget(
                      sectionTitle: "Accessories",
                      listeningAreas: _projectViewModel.listeningAreas,
                      onTapAddDevice: (dynamic item, String areaId, String floorId) {
                        if (item is RackData) {
                          final HardwareRack hardwareRack = HardwareRack(
                            locationEntity: LocationModel(
                              listeningAreaId: areaId,
                              floorId: floorId,
                            ),
                            name: item.name,
                            assetImagePath: item.assetPath,
                            price: item.price,
                            hardwareName: item.name,
                            addedFromBuildingPage: false,
                          );
                          serviceLocator<ProjectViewModel>().addHardware(
                            hardware: hardwareRack,
                          );
                          FusionToast.success(
                            context,
                            message: "Hardware Rack \"${item.name}\" added",
                          );
                        } else if (item is SwitchData) {
                          final NetworkSwitch networkSwitch = NetworkSwitch(
                            locationEntity: LocationModel(
                              listeningAreaId: areaId,
                              floorId: floorId,
                            ),
                            addedFromBuildingPage: false,
                            name: item.name,
                            assetImagePath: item.assetPath,
                            price: item.price,
                            hardwareName: item.name,
                          );
                          serviceLocator<ProjectViewModel>().addHardware(
                            hardware: networkSwitch,
                          );
                          FusionToast.success(
                            context,
                            message: "Switch \"${item.name}\" added",
                          );
                        }
                      },
                    ),
                    sections: <Widget>[
                      SchematicHardwareListing<HardwareRack, SchematicHardwareRacksViewModel>(
                        create: (BuildContext context) {
                          return SchematicHardwareRacksViewModel();
                        },
                        title: "Racks",
                      ),

                      const SizedBox(height: 12),
                      SchematicHardwareListing<NetworkSwitch, SchematicNetworkSwitchesViewModel>(
                        create: (BuildContext context) {
                          return SchematicNetworkSwitchesViewModel();
                        },
                        title: "Switches",
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
