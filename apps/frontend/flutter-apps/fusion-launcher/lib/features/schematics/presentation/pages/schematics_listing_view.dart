import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/schematics/presentation/widgets/filter_section.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/schematic_amplifier_viewmodel.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/schematic_fusion_dsp_viewmodel.dart';
import 'package:fusion_launcher/features/schematics/viewmodel/schematic_zone_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/service_locator.dart';
import '../../../add_source_popup/view/add_source_popup.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../configuration_control/widgets/controllers/add_controller/add_controller_dialog.dart';
import '../../../create_zone_popup/view/create_zone_popup.dart';
import '../../../projects/viewmodel/eql_products_vm.dart';
import '../../../projects/widget/building/side_panel_widgets/equipment_location/equipment_location_dialog.dart';
import '../../../projects/widget/building/side_panel_widgets/equipment_location/parts/endpointdialog.dart';
import '../../state/device_listing_state.dart';
import '../../viewmodel/endpoints_viewmodel.dart';
import '../../viewmodel/filter_view_model.dart';
import '../../viewmodel/schematic_fusion_controller_viewmodel.dart';
import '../../viewmodel/schematic_sources_viewmodel.dart';
import '../../viewmodel/search_control_viewmodel.dart';
import '../../views/widgets/schematic_hardware_listing.dart';
import '../../views/widgets/schematic_listing_section.dart';
import '../../views/widgets/schematic_section.dart';
import '../widgets/expandable_zone_widget.dart';
import '../../state/filter_state.dart';

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
    return BlocProvider<FilterViewModel>(
      create: (_) => FilterViewModel(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SemanticHelper.container(
            testId: SemanticHelper.createTestId(
              SemanticTypes.container,
              "schematic_listing_view_area",
            ),
            child: Container(
              color: context.colorScheme.primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: BlocBuilder<FilterViewModel, FilterViewModelState>(
                builder: (BuildContext context, FilterViewModelState filterState) {
                  return Row(
                    spacing: 6,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // it reads FilterViewModel from the ancestor provider above.
                      const FilterSection(),

                      ///------------------------------------------------------
                      /// 1. Sources & Endpoints
                      ///------------------------------------------------------
                      Expanded(
                        flex: 2,
                        child: SchematicListingSection(
                          sectionTitle: "Sources & Endpoints",
                          sections: <Widget>[
                            SchematicHardwareListing<Source, SchematicSourcesViewModel>(
                              create: (BuildContext context) => SchematicSourcesViewModel(),
                              title: "Sources",
                              filterState: filterState,
                              addAction: AddSourceDrawer(
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
                              create: (BuildContext context) => SchematicEndpointsViewModel(),
                              title: "Endpoints",
                              filterState: filterState,
                              addAction: GestureDetector(
                                onTap:
                                    () => AddEndpointDialog.show(
                                      context: context,
                                      category: EndpointDeviceCategory.endpoint,
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

                      ///------------------------------------------------------
                      /// 2. Processors & Amplifiers
                      ///------------------------------------------------------
                      Expanded(
                        flex: 2,
                        child: SchematicListingSection(
                          sectionTitle: "Processors & Amplifiers",
                          sections: <Widget>[
                            SchematicHardwareListing<FusionDsp, SchematicFusionDeviceViewModel>(
                              create: (BuildContext context) => SchematicFusionDeviceViewModel(),
                              title: "Fusion Devices",
                              filterState: filterState,
                              addAction: FusionArrowPopup(
                                semanticId: 'add_fusion_device_popup',
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
                              create: (BuildContext context) => SchematicAmplifiersViewModel(),
                              title: "Amplifiers",
                              filterState: filterState,
                              addAction: FusionArrowPopup(
                                semanticId: 'add_amplifier_popup',
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

                      ///------------------------------------------------------
                      /// 3. Zones (Speakers)
                      ///------------------------------------------------------
                      Expanded(
                        flex: 3,
                        child: SchematicListingSection(
                          sectionTitle: "Speakers",
                          action: CreateZonePopup(
                            isFromBuildingPage: false,
                            child: SemanticHelper.button(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.button,
                                "add_zone_button_speakers",
                              ),
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
                              create: (BuildContext context) => SchematicZoneViewModel(),
                              builder: (
                                BuildContext context,
                                DeviceListingState<Zone> state,
                              ) {
                                final SearchResultsViewModel read = context.read<SearchResultsViewModel>();
                                final Set<String> zoneIdsOnCheckedFloors = <String>{};
                                if (filterState.checkedFloorIds.isNotEmpty) {
                                  for (final String floorId in filterState.checkedFloorIds) {
                                    final List<ListeningArea> areas = _projectViewModel.getListeningAreasForFloor(floorId: floorId);
                                    for (final ListeningArea area in areas) {
                                      final Zone? zone = _projectViewModel.getZonesForListeningArea(areaId: area.id);
                                      if (zone != null) zoneIdsOnCheckedFloors.add(zone.id);
                                    }
                                  }
                                }

                                // Build set: zone IDs reachable from checked listening areas
                                final Set<String> zoneIdsOnCheckedAreas = <String>{};
                                if (filterState.checkedAreaIds.isNotEmpty) {
                                  for (final String areaId in filterState.checkedAreaIds) {
                                    final Zone? zone = _projectViewModel.getZonesForListeningArea(areaId: areaId);
                                    if (zone != null) zoneIdsOnCheckedAreas.add(zone.id);
                                  }
                                }
                                final Set<String> zoneIdsFromCheckedSubZones = <String>{};
                                if (filterState.checkedSubZoneIds.isNotEmpty) {
                                  for (final Zone zone in _projectViewModel.getAllZones()) {
                                    for (final SubZone sub in _projectViewModel.getSubZonesForZone(parentZoneId: zone.id)) {
                                      if (filterState.checkedSubZoneIds.contains(sub.id)) {
                                        zoneIdsFromCheckedSubZones.add(zone.id);
                                      }
                                    }
                                  }
                                }

                                // ── Union all active sets → OR logic across categories ────────
                                Set<String>? allowedZoneIds;

                                if (filterState.checkedZoneIds.isNotEmpty) {
                                  allowedZoneIds = <String>{...filterState.checkedZoneIds};
                                }
                                if (filterState.checkedSubZoneIds.isNotEmpty) {
                                  allowedZoneIds =
                                      allowedZoneIds == null ? <String>{...zoneIdsFromCheckedSubZones} : allowedZoneIds.union(zoneIdsFromCheckedSubZones);
                                }
                                if (filterState.checkedFloorIds.isNotEmpty) {
                                  allowedZoneIds = allowedZoneIds == null ? <String>{...zoneIdsOnCheckedFloors} : allowedZoneIds.union(zoneIdsOnCheckedFloors);
                                }
                                if (filterState.checkedAreaIds.isNotEmpty) {
                                  allowedZoneIds = allowedZoneIds == null ? <String>{...zoneIdsOnCheckedAreas} : allowedZoneIds.union(zoneIdsOnCheckedAreas);
                                }

                                final List<Zone> allDevices = state.devices;
                                final List<Zone> devices =
                                    allDevices.where((Zone z) {
                                      if (allowedZoneIds == null) return true;
                                      return allowedZoneIds.contains(z.id);
                                    }).toList();

                                read.updateResults(
                                  devices.map((Zone e) => e.id).toList(),
                                );

                                if (devices.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 8,
                                    ),
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
                                    _projectViewModel.reorderZones(
                                      zoneIdToMove: devices[oldIndex].id,
                                      zoneIdAtNewIndex: devices[newIndex].id,
                                    );
                                  },
                                  itemBuilder: (BuildContext context, Zone zone) {
                                    final List<SubZone> allSubZones = _projectViewModel.getSubZonesForZone(parentZoneId: zone.id);
                                    final List<SubZone> visibleSubZones =
                                        filterState.checkedSubZoneIds.isEmpty
                                            ? allSubZones
                                            : allSubZones.where((SubZone sub) => filterState.checkedSubZoneIds.contains(sub.id)).toList();

                                    return ExpandableZoneWidget(
                                      index: devices.indexOf(zone),
                                      zoneName: zone.name,
                                      zoneId: zone.id,
                                      bgColor: zone.color,
                                      initiallyExpanded: true,
                                      zoneCircuits: _projectViewModel.getCircuitsInZone(zone.id),
                                      subZones: visibleSubZones,
                                      onDelete: (String id) {
                                        serviceLocator<ProjectViewModel>().removeZone(
                                          zoneId: zone.id,
                                        );
                                        FusionToast.error(
                                          context,
                                          message: 'Zone "${zone.name}" deleted',
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      ///------------------------------------------------------
                      /// 4. Controllers
                      ///------------------------------------------------------
                      Expanded(
                        flex: 2,
                        child: SchematicListingSection(
                          sectionTitle: "Controllers",
                          action: GestureDetector(
                            onTap:
                                () => AddControllerDialog.show(
                                  context,
                                  onControllerAdded: (String controllerId) {
                                    FusionToast.success(context, message: 'Controller added');
                                  },
                                ),
                            child: SemanticHelper.button(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.button,
                                "add_controller",
                              ),
                              child: Icon(
                                LucideIcons.plus200,
                                size: FusionSizes.iconSize16,
                                color: context.colorScheme.primaryWhite,
                              ),
                            ),
                          ),
                          sections: <Widget>[
                            SchematicHardwareListing<FusionController, SchematicFusionControllerViewModel>(
                              create: (BuildContext context) => SchematicFusionControllerViewModel(),
                              title: "Controllers",
                              filterState: filterState,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
