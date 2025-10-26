import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

import '../../../../core/models/products_data.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../widgets/common_devices_section_widget.dart';
import '../widgets/expandable_zone_widget.dart';
import '../widgets/hardware_item_card.dart';
import '../widgets/common_reorderable_list_view.dart';

class SchematicsListingview extends StatefulWidget {
  const SchematicsListingview({super.key});

  @override
  State<SchematicsListingview> createState() => _SchematicsListingviewState();
}

class _SchematicsListingviewState extends State<SchematicsListingview> {
  List<Speaker> _reorderableSpeakers = <Speaker>[];

  static const double _speakersWidthRatio = 0.25; // 25% of available width
  static const double _normalColumnWidthRatio = 0.1875; // 18.75% each (4 columns = 75%)

  // Get ProjectViewModel instance
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _projectViewModel.clearSelections();
    super.dispose();
  }

  /// Get location name from listeningAreaId
  String? getLocationName(String? listeningAreaId) {
    if (listeningAreaId == null) return null;

    final ListeningArea area = serviceLocator<ProjectViewModel>().getListeningArea(areaId: listeningAreaId);

    return area.name;
  }

  /// Get zone data from hardwareId
  Zone? getZoneData(String hardwareId) {
    return serviceLocator<ProjectViewModel>().getZoneForHardware(hardwareId: hardwareId);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;

        /// Calculate column widths proportionally to prevent overflow
        final double speakersColumnWidth = availableWidth * _speakersWidthRatio;
        final double normalColumnWidth = availableWidth * _normalColumnWidthRatio;

        return Container(
          color: Colors.white,
          child: Row(
            children: <Widget>[
              /// Sources & Endpoints
              CommonDevicesSectionWidget(
                title: "Sources & Endpoints",
                width: normalColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.grey[200]!,
                sectionContent: Container(), // Not used when expandable is enabled
                enableExpandable: true,
                expandableSections: <ExpandableSection>[
                  ExpandableSection(
                    title: "Sources",
                    content: _buildSourcesContent(),
                    initiallyExpanded: true,
                  ),
                  ExpandableSection(
                    title: "Endpoints",
                    content: _buildEndpointsContent(),
                    initiallyExpanded: true,
                  ),
                ],
                listeningAreas: _projectViewModel.listeningAreas,
                // zones: _zones,
                selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.source ? _projectViewModel.selectedDevice?.id : null,
                onTapAddDevice: (dynamic item, String areaId, String floorId) {
                  /// Sources [onTapAddDevice]
                  if (item is SourceData) {
                    final Source source = Source(
                      name: item.name,
                      pos: null,
                      type: item.type,
                      assetImagePath: item.assetPath,
                      locationEntity: LocationModel(listeningAreaId: areaId, floorId: floorId),
                      sku: item.id,
                      price: item.price,
                      portData: HardwarePortData(
                        inputPorts: 5,
                        outputPorts: 5,
                        inputPortType: PortType.analogInput,
                        outputPortType: PortType.analogOutput,
                        compatibleInputTypes: <PortType>[PortType.analogInput, PortType.digitalInput],
                        compatibleOutputTypes: <PortType>[PortType.analogOutput, PortType.digitalOutput],
                        portPosition: PortPosition.topLeft,
                      ),
                      communicationPorts: <PortData>[
                        PortData(
                          name: 'Wifi',
                          position: PortPosition.footerRight,
                          portNumber: 1,
                          type: PortType.wifi,
                          compatibleTypes: <PortType>[PortType.wifi],
                          description: '',
                        ),
                        PortData(
                          name: 'USB',
                          position: PortPosition.footerRight,
                          portNumber: 2,
                          type: PortType.usb,
                          compatibleTypes: <PortType>[PortType.usb],
                          description: '',
                        ),
                        PortData(
                          name: 'ble',
                          position: PortPosition.footerRight,
                          portNumber: 3,
                          type: PortType.ble,
                          compatibleTypes: <PortType>[PortType.ble],
                          description: '',
                        ),
                      ],
                    );
                    serviceLocator<ProjectViewModel>().addHardware(hardware: source);
                    FusionToast.success(
                      context,
                      message: "Source \"${item.name}\" added",
                    );
                  }
                  /// Endpoints [onTapAddDevice]
                  else if (item is ProductQueryModel) {
                    final HardwareComponent hardware = serviceLocator<ProjectViewModel>().fromProductQueryModel(
                      item,
                      locationEntity: LocationModel(listeningAreaId: areaId, floorId: floorId),
                      pos: Offset.zero,
                    );

                    serviceLocator<ProjectViewModel>().addHardware(hardware: hardware);
                    FusionToast.show(
                      context,
                      message: "Endpoint \"${item.name}\" added",
                      icon: Icons.check_circle_outline,
                      backgroundColor: Colors.green[600],
                    );
                  }
                },
              ),

              /// Processors & Amplifiers
              CommonDevicesSectionWidget(
                title: "Processors & Amplifiers",
                width: normalColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.grey[200]!,
                sectionContent: Container(), // Not used when expandable is enabled
                enableExpandable: true,
                expandableSections: <ExpandableSection>[
                  ExpandableSection(
                    title: "Fusion Devices",
                    content: _buildProcessorsContent(),
                    initiallyExpanded: true,
                  ),
                  ExpandableSection(
                    title: "Amplifiers",
                    content: _buildAmplifiersContent(),
                    initiallyExpanded: true,
                  ),
                ],
                listeningAreas: _projectViewModel.listeningAreas,
                // zones: _zones,
                selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.processor ? _projectViewModel.selectedDevice?.id : null,
                onTapAddDevice: (dynamic item, String areaId, String floorId) {
                  print("Adding hardware of type: ${item.type}");

                  if (item is ProductQueryModel) {
                    final HardwareComponent hardware = serviceLocator<ProjectViewModel>().fromProductQueryModel(
                      item,
                      locationEntity: LocationModel(listeningAreaId: areaId, floorId: floorId),
                      pos: Offset.zero,
                    );
                    if (item.type == ProductType.dsps) {
                      serviceLocator<ProjectViewModel>().addHardware(hardware: hardware);
                      FusionToast.success(
                        context,
                        message: "Processors \"${item.name}\" added",
                      );
                    } else {
                      serviceLocator<ProjectViewModel>().addHardware(hardware: hardware);
                      FusionToast.success(
                        context,
                        message: "Amplifier \"${item.name}\" added",
                      );
                      return;
                    }
                  }
                },
              ),

              /// Speakers
              CommonDevicesSectionWidget(
                title: "Speakers",
                width: speakersColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.white,
                sectionContent: _buildSpeakersContent(),
                listeningAreas: _projectViewModel.listeningAreas,
                // zones: _projectViewModel.zones,
                selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.zone ? _projectViewModel.selectedDevice?.id : null,
                onTapAddDevice: (dynamic item, String areaId, String floorId) {
                  // if (item is ProductQueryModel) {
                  //   final Map<String, dynamic> newZone = <String, dynamic>{
                  //     'id': 'zone_${DateTime.now().millisecondsSinceEpoch}',
                  //     'name': 'New Zone',
                  //     'color': Colors.lightBlueAccent[100],
                  //   };
                  //   setState(() {
                  //     _reorderableZones.add(newZone);
                  //   });
                  // }
                },
              ),

              /// Controllers
              CommonDevicesSectionWidget(
                title: "Controllers",
                width: normalColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.grey[200]!,
                sectionContent: Container(), // Not used when expandable is enabled
                enableExpandable: true,
                expandableSections: <ExpandableSection>[
                  ExpandableSection(
                    title: "Controllers",
                    content: _buildControllersList(),
                    initiallyExpanded: true,
                  ),
                ],
                listeningAreas: _projectViewModel.listeningAreas,
                // zones: _zones,
                selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.controller ? _projectViewModel.selectedDevice?.id : null,
                onTapAddDevice: (dynamic item, String areaId, String floorId) {
                  if (item is ProductQueryModel) {
                    final HardwareComponent hardware = serviceLocator<ProjectViewModel>().fromProductQueryModel(
                      item,
                      locationEntity: LocationModel(listeningAreaId: areaId, floorId: floorId),
                      pos: Offset.zero,
                    );

                    serviceLocator<ProjectViewModel>().addHardware(hardware: hardware);
                    FusionToast.show(
                      context,
                      message: "Controller \"${item.name}\" added",
                      icon: Icons.check_circle_outline,
                      backgroundColor: Colors.green[600],
                    );
                  }
                },
              ),

              /// Accessories
              CommonDevicesSectionWidget(
                title: "Accessories",
                width: normalColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.grey[200]!,
                sectionContent: Container(), // Not used when expandable is enabled
                enableExpandable: true,
                expandableSections: <ExpandableSection>[
                  ExpandableSection(
                    title: "Racks",
                    content: _buildRacksContent(),
                    initiallyExpanded: true,
                  ),
                  ExpandableSection(
                    title: "Switches",
                    content: _buildSwitchesContent(),
                    initiallyExpanded: true,
                  ),
                ],
                listeningAreas: _projectViewModel.listeningAreas,
                // zones: _zones,
                selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.racks ? _projectViewModel.selectedDevice?.id : null,
                onTapAddDevice: (dynamic item, String areaId, String floorId) {
                  if (item is RackData) {
                    final HardwareRack hardwareRack = HardwareRack(
                      locationEntity: LocationModel(listeningAreaId: areaId, floorId: floorId),
                      name: item.name,
                      pos: Offset.zero,
                      assetImagePath: item.assetPath,
                      price: item.price,
                      hardwareName: item.name,
                    );
                    serviceLocator<ProjectViewModel>().addHardware(hardware: hardwareRack);
                    FusionToast.success(
                      context,
                      message: "Hardware Rack \"${item.name}\" added",
                    );
                  } else if (item is SwitchData) {
                    final NetworkSwitch networkSwitch = NetworkSwitch(
                      locationEntity: LocationModel(listeningAreaId: areaId, floorId: floorId),
                      name: item.name,
                      pos: Offset.zero,
                      assetImagePath: item.assetPath,
                      price: item.price,
                      hardwareName: item.name,
                    );
                    serviceLocator<ProjectViewModel>().addHardware(hardware: networkSwitch);
                    FusionToast.success(
                      context,
                      message: "Switch \"${item.name}\" added",
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Create a simple controllers list without expandable wrapper
  Widget _buildControllersList() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        return CommonReorderableListView<FusionController>(
          items: _projectViewModel.fusionControllers,
          emptyMessage: "No controllers added yet",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String hwToMove = _projectViewModel.fusionControllers[oldIndex].id;
            final String hwAtNewIndex = _projectViewModel.fusionControllers[newIndex].id;
            _projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
            _projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.controller);
          },
          keyExtractor: (FusionController controller) => controller.id,
          itemBuilder: (BuildContext context, FusionController controller, int index) {
            final bool isSelected = selectedDevice?.id == controller.id && selectedDevice?.type == SelectedItemType.controller;

            return HardwareItemCard(
              name: controller.name,
              assetImagePath: controller.assetImagePath,
              itemId: controller.id,
              zone: getZoneData(controller.id),
              location: getLocationName(controller.locationEntity.listeningAreaId) ?? "Add Location",
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(controller.id, SelectedItemType.controller),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);
                FusionToast.error(
                  context,
                  message: 'Controller "${controller.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename controller $id'),
              onDuplicate: (String id) => print('Duplicate controller $id'),
            );
          },
        );
      },
    );
  }

  /// Optimized Sources content using CommonReorderableListView
  Widget _buildSourcesContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        return CommonReorderableListView<Source>(
          items: _projectViewModel.sources,
          emptyMessage: "No sources added yet",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String hwToMove = _projectViewModel.sources[oldIndex].id;
            final String hwAtNewIndex = _projectViewModel.sources[newIndex].id;
            _projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
            _projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.source);
          },
          keyExtractor: (Source source) => source.id,
          itemBuilder: (BuildContext context, Source source, int index) {
            final bool isSelected = selectedDevice?.id == source.id && selectedDevice?.type == SelectedItemType.source;

            return HardwareItemCard(
              name: source.name,
              assetImagePath: source.assetImagePath,
              itemId: source.id,
              zone: getZoneData(source.id),
              location: getLocationName(source.locationEntity.listeningAreaId) ?? "Add Location",
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(source.id, SelectedItemType.source),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);
                FusionToast.error(
                  context,
                  message: 'Source "${source.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename source $id'),
              onDuplicate: (String id) => print('Duplicate source $id'),
            );
          },
        );
      },
    );
  }

  /// Endpoints content using CommonReorderableListView
  Widget _buildEndpointsContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        return CommonReorderableListView<FusionEndpoints>(
          items: _projectViewModel.fusionEndpoints,
          emptyMessage: "No endpoints added yet",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String hwToMove = _projectViewModel.fusionEndpoints[oldIndex].id;
            final String hwAtNewIndex = _projectViewModel.fusionEndpoints[newIndex].id;
            _projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
            _projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.endpoint);
          },
          keyExtractor: (FusionEndpoints endpoint) => endpoint.id,
          itemBuilder: (BuildContext context, FusionEndpoints endpoint, int index) {
            final bool isSelected = selectedDevice?.id == endpoint.id && selectedDevice?.type == SelectedItemType.endpoint;

            return HardwareItemCard(
              name: endpoint.name,
              assetImagePath: endpoint.assetImagePath,
              itemId: endpoint.id,
              zone: getZoneData(endpoint.id),
              location: getLocationName(endpoint.locationEntity.listeningAreaId) ?? "Add Location",
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(endpoint.id, SelectedItemType.endpoint),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);
                FusionToast.error(
                  context,
                  message: 'Endpoint "${endpoint.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename endpoint $id'),
              onDuplicate: (String id) => print('Duplicate endpoint $id'),
            );
          },
        );
      },
    );
  }

  ///  Processors content using CommonReorderableListView
  Widget _buildProcessorsContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        return CommonReorderableListView<FusionDsp>(
          items: _projectViewModel.fusionDsps,
          emptyMessage: "No processors added yet",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String hwToMove = _projectViewModel.fusionDsps[oldIndex].id;
            final String hwAtNewIndex = _projectViewModel.fusionDsps[newIndex].id;
            _projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
            _projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.processor);
          },
          keyExtractor: (FusionDsp processor) => processor.id,
          itemBuilder: (BuildContext context, FusionDsp processor, int index) {
            final bool isSelected = selectedDevice?.id == processor.id && selectedDevice?.type == SelectedItemType.processor;

            return HardwareItemCard(
              name: processor.name,
              assetImagePath: processor.assetImagePath,
              itemId: processor.id,
              location: getLocationName(processor.locationEntity.listeningAreaId) ?? "Add Location",
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(processor.id, SelectedItemType.processor),
              onDelete: (String id) {
                FusionToast.error(
                  context,
                  message: 'Processor "${processor.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename processor $id'),
              onDuplicate: (String id) => print('Duplicate processor $id'),
            );
          },
        );
      },
    );
  }

  /// Racks content using CommonReorderableListView
  Widget _buildRacksContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        return CommonReorderableListView<HardwareRack>(
          items: _projectViewModel.hardwareRacks,
          emptyMessage: "No processors added yet",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String hwToMove = _projectViewModel.hardwareRacks[oldIndex].id;
            final String hwAtNewIndex = _projectViewModel.hardwareRacks[newIndex].id;
            _projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
            _projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.racks);
          },
          keyExtractor: (HardwareRack hardwareRack) => hardwareRack.id,
          itemBuilder: (BuildContext context, HardwareRack hardwareRack, int index) {
            final bool isSelected = selectedDevice?.id == hardwareRack.id && selectedDevice?.type == SelectedItemType.racks;

            return HardwareItemCard(
              name: hardwareRack.name,
              assetImagePath: hardwareRack.assetImagePath,
              itemId: hardwareRack.id,
              location: getLocationName(hardwareRack.locationEntity.listeningAreaId) ?? "Add Location",
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(hardwareRack.id, SelectedItemType.racks),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);

                FusionToast.error(
                  context,
                  message: 'Racks "${hardwareRack.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename processor $id'),
              onDuplicate: (String id) => print('Duplicate processor $id'),
            );
          },
        );
      },
    );
  }

  /// Amplifiers content using CommonReorderableListView
  Widget _buildAmplifiersContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        return CommonReorderableListView<Amplifier>(
          items: _projectViewModel.amplifiers,
          emptyMessage: "No processors added yet",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String hwToMove = _projectViewModel.amplifiers[oldIndex].id;
            final String hwAtNewIndex = _projectViewModel.amplifiers[newIndex].id;
            _projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
            _projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.amplifier);
          },
          keyExtractor: (Amplifier amplifier) => amplifier.id,
          itemBuilder: (BuildContext context, Amplifier amplifier, int index) {
            final bool isSelected = selectedDevice?.id == amplifier.id && selectedDevice?.type == SelectedItemType.amplifier;

            return HardwareItemCard(
              name: amplifier.name,
              assetImagePath: amplifier.assetImagePath,
              itemId: amplifier.id,
              location: getLocationName(amplifier.locationEntity.listeningAreaId) ?? "Add Location",
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(amplifier.id, SelectedItemType.amplifier),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);
                FusionToast.error(
                  context,
                  message: 'Amplifier "${amplifier.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename processor $id'),
              onDuplicate: (String id) => print('Duplicate processor $id'),
            );
          },
        );
      },
    );
  }

  /// Accessories content using CommonReorderableListView
  Widget _buildSwitchesContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        return CommonReorderableListView<NetworkSwitch>(
          items: _projectViewModel.networkSwitches,
          emptyMessage: "No accessories added yet",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String hwToMove = _projectViewModel.networkSwitches[oldIndex].id;
            final String hwAtNewIndex = _projectViewModel.networkSwitches[newIndex].id;
            _projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
            _projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.switchs);
          },
          keyExtractor: (NetworkSwitch networkSwitch) => networkSwitch.id,
          itemBuilder: (BuildContext context, NetworkSwitch networkSwitch, int index) {
            final bool isSelected = selectedDevice?.id == networkSwitch.id && selectedDevice?.type == SelectedItemType.switchs;

            return HardwareItemCard(
              name: networkSwitch.name,
              assetImagePath: networkSwitch.assetImagePath,
              itemId: networkSwitch.id,
              // zone: getZoneData(accessoryId),
              location: getLocationName(networkSwitch.locationEntity.listeningAreaId) ?? "Add Location",
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(networkSwitch.id, SelectedItemType.switchs),

              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);

                FusionToast.error(
                  context,
                  message: 'Accessory "${networkSwitch.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename accessory $id'),
              onDuplicate: (String id) => print('Duplicate accessory $id'),
            );
          },
        );
      },
    );
  }

  Widget _buildSpeakersContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        if (_projectViewModel.zones.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FusionAppText(
                text: "No zones added yet",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }

        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _projectViewModel.zones.length,
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String zoneToMove = _projectViewModel.zones[oldIndex].id;
            final String zoneAtNewIndex = _projectViewModel.zones[newIndex].id;
            _projectViewModel.reorderZones(zoneIdToMove: zoneToMove, zoneIdAtNewIndex: zoneAtNewIndex);
            _projectViewModel.setSelectedDevice(zoneToMove, SelectedItemType.zone);
          },
          itemBuilder: (BuildContext context, int index) {
            final Zone zoneData = _projectViewModel.zones[index];
            return ReorderableDragStartListener(
              key: ValueKey<String>(zoneData.id),
              index: index,
              child: ExpandableZoneWidget(
                zoneName: zoneData.name,
                assetImagePath: 'assets/speaker.png',
                zoneId: zoneData.id,
                bgColor: zoneData.color,
                initiallyExpanded: false,
                zoneCircuits: _projectViewModel.getCircuitsInZone(zoneData.id),
                subZones: _projectViewModel.getSubZonesForZone(parentZoneId: zoneData.id),
                onSubZoneReorder: (String zoneId, int oldIndex, int newIndex) {
                  // setState(() {
                  //   final List<Map<String, dynamic>>? subZones = _reorderableSubZones[zoneId];
                  //   if (subZones != null) {
                  //     if (newIndex > oldIndex) newIndex -= 1;
                  //     final Map<String, dynamic> item = subZones.removeAt(oldIndex);
                  //     subZones.insert(newIndex, item);
                  //   }
                  // });
                },
                onDeviceReorder: (String subZoneId, int oldIndex, int newIndex) {
                  // setState(() {
                  //   final List<Map<String, dynamic>>? devices = _reorderableDevices[subZoneId];
                  //   if (devices != null) {
                  //     if (newIndex > oldIndex) newIndex -= 1;
                  //     final Map<String, dynamic> item = devices.removeAt(oldIndex);
                  //     devices.insert(newIndex, item);
                  //   }
                  // });
                },
                onDelete: (String id) {
                  serviceLocator<ProjectViewModel>().removeZone(zoneId: zoneData.id);
                  FusionToast.error(
                    context,
                    message: 'Zone "${zoneData.name}" deleted',
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
