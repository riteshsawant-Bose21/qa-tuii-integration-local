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

  final Map<String, List<Map<String, dynamic>>> _reorderableSubZones = <String, List<Map<String, dynamic>>>{};
  final Map<String, List<Map<String, dynamic>>> _reorderableDevices = <String, List<Map<String, dynamic>>>{};

  static const double _speakersWidthRatio = 0.25; // 25% of available width
  static const double _normalColumnWidthRatio = 0.1875; // 18.75% each (4 columns = 75%)

  // Get ProjectViewModel instance
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  @override
  void initState() {
    super.initState();
    _initializeReorderableLists();
  }

  void _initializeReorderableLists() {
    // Initialize subzones for each zone
    _reorderableSubZones['zone_1'] = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'subzone_1_1', 'name': 'Stage Area', 'zoneId': 'zone_1'},
      <String, dynamic>{'id': 'subzone_1_2', 'name': 'Audience Area', 'zoneId': 'zone_1'},
      <String, dynamic>{'id': 'subzone_1_3', 'name': 'VIP Section', 'zoneId': 'zone_1'},
    ];

    _reorderableSubZones['zone_2'] = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'subzone_2_1', 'name': 'Presentation Area', 'zoneId': 'zone_2'},
      <String, dynamic>{'id': 'subzone_2_2', 'name': 'Seating Area', 'zoneId': 'zone_2'},
    ];

    // Initialize devices for each subzone
    _reorderableDevices['subzone_1_1'] = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'device_1_1_1', 'name': 'Speaker 1', 'position': 'Front Left', 'subZoneId': 'subzone_1_1'},
      <String, dynamic>{'id': 'device_1_1_2', 'name': 'Speaker 2', 'position': 'Front Right', 'subZoneId': 'subzone_1_1'},
    ];

    _reorderableDevices['subzone_1_2'] = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'device_1_2_1', 'name': 'Speaker 3', 'position': 'Center', 'subZoneId': 'subzone_1_2'},
      <String, dynamic>{'id': 'device_1_2_2', 'name': 'Speaker 4', 'position': 'Rear', 'subZoneId': 'subzone_1_2'},
    ];

    _reorderableDevices['subzone_1_3'] = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'device_1_3_1', 'name': 'Speaker 5', 'position': 'Left Side', 'subZoneId': 'subzone_1_3'},
    ];

    _reorderableDevices['subzone_2_1'] = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'device_2_1_1', 'name': 'Speaker 6', 'position': 'Front Center', 'subZoneId': 'subzone_2_1'},
    ];

    _reorderableDevices['subzone_2_2'] = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'device_2_2_1', 'name': 'Speaker 7', 'position': 'Back Left', 'subZoneId': 'subzone_2_2'},
      <String, dynamic>{'id': 'device_2_2_2', 'name': 'Speaker 8', 'position': 'Back Right', 'subZoneId': 'subzone_2_2'},
    ];
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

  List<Zone> get _zones => <Zone>[
    Zone(
      id: 'zone_1',
      name: 'Zone 1',
    ),
    Zone(
      id: 'zone_2',
      name: 'Zone 2',
    ),
  ];

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
                sectionContent: _buildSourcesAndEndpointsContent(),
                listeningAreas: _projectViewModel.listeningAreas,
                zones: _zones,
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
                sectionContent: _buildProcessorsAndAmplifiers(),
                listeningAreas: _projectViewModel.listeningAreas,
                zones: _zones,
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
                zones: _projectViewModel.zones,
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
                sectionContent: _buildControllersContent(),
                listeningAreas: _projectViewModel.listeningAreas,
                zones: _zones,
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
                sectionContent: _buildAccessories(),
                listeningAreas: _projectViewModel.listeningAreas,
                zones: _zones,
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

  /// Combined Sources & Endpoints content with separate sections
  Widget _buildSourcesAndEndpointsContent() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Sources Section
          FusionAppText(
            text: "Sources",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          /// Sources List
          _buildSourcesContent(),

          const SizedBox(height: 16),

          /// Endpoints Section
          FusionAppText(
            text: "Endpoints",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          /// Endpoints List
          _buildEndpointsContent(),
        ],
      ),
    );
  }

  /// Combined Processors & Amplifiers content with separate sections
  Widget _buildProcessorsAndAmplifiers() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Processors Section
          FusionAppText(
            text: "Fusion Devices",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          /// Processors List
          _buildProcessorsContent(),

          const SizedBox(height: 16),

          /// Amplifiers Section
          FusionAppText(
            text: "Amplifiers",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          /// Amplifiers List
          _buildAmplifiersContent(),
        ],
      ),
    );
  }

  /// Amplifiers content using CommonReorderableListView
  Widget _buildAccessories() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Processors Section
          FusionAppText(
            text: "Racks",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          /// Processors List
          _buildRacksContent(),

          const SizedBox(height: 16),

          /// Amplifiers Section
          FusionAppText(
            text: "Switches",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          /// Amplifiers List
          _buildSwitchesContent(),
        ],
      ),
    );
  }

  /// Optimized Sources content using CommonReorderableListView
  Widget _buildSourcesContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
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
            final bool isHovered = hoveredDevice?.id == source.id && hoveredDevice?.type == SelectedItemType.source;
            final bool isSelected = selectedDevice?.id == source.id && selectedDevice?.type == SelectedItemType.source;
            // print("Sourceeeeee ${source.id} is in location: $locationName, zone: ${zoneData?.name ?? "No Zone"}");

            return HardwareItemCard(
              name: source.name,
              assetImagePath: source.assetImagePath,
              itemId: source.id,
              zone: getZoneData(source.id),
              location: getLocationName(source.locationEntity.listeningAreaId) ?? "Add Location",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(source.id, SelectedItemType.source),
              onHover: () => _projectViewModel.setHoveredDevice(source.id, SelectedItemType.source),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
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
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
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
            final bool isHovered = hoveredDevice?.id == endpoint.id && hoveredDevice?.type == SelectedItemType.endpoint;
            final bool isSelected = selectedDevice?.id == endpoint.id && selectedDevice?.type == SelectedItemType.endpoint;

            return HardwareItemCard(
              name: endpoint.name,
              assetImagePath: endpoint.assetImagePath,
              itemId: endpoint.id,
              zone: getZoneData(endpoint.id),
              location: getLocationName(endpoint.locationEntity.listeningAreaId) ?? "Add Location",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(endpoint.id, SelectedItemType.endpoint),
              onHover: () => _projectViewModel.setHoveredDevice(endpoint.id, SelectedItemType.endpoint),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
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
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
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
            final bool isHovered = hoveredDevice?.id == processor.id && hoveredDevice?.type == SelectedItemType.processor;
            final bool isSelected = selectedDevice?.id == processor.id && selectedDevice?.type == SelectedItemType.processor;

            return HardwareItemCard(
              name: processor.name,
              assetImagePath: processor.assetImagePath,
              itemId: processor.id,
              // zone: getZoneData(processor.id),
              location: getLocationName(processor.locationEntity.listeningAreaId) ?? "Add Location",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(processor.id, SelectedItemType.processor),
              onHover: () => _projectViewModel.setHoveredDevice(processor.id, SelectedItemType.processor),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
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
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
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
            final bool isHovered = hoveredDevice?.id == hardwareRack.id && hoveredDevice?.type == SelectedItemType.racks;
            final bool isSelected = selectedDevice?.id == hardwareRack.id && selectedDevice?.type == SelectedItemType.racks;

            return HardwareItemCard(
              name: hardwareRack.name,
              assetImagePath: hardwareRack.assetImagePath,
              itemId: hardwareRack.id,
              // zone: getZoneData(processor.id),
              location: getLocationName(hardwareRack.locationEntity.listeningAreaId) ?? "Add Location",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(hardwareRack.id, SelectedItemType.racks),
              onHover: () => _projectViewModel.setHoveredDevice(hardwareRack.id, SelectedItemType.racks),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
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
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
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
            final bool isHovered = hoveredDevice?.id == amplifier.id && hoveredDevice?.type == SelectedItemType.amplifier;
            final bool isSelected = selectedDevice?.id == amplifier.id && selectedDevice?.type == SelectedItemType.amplifier;

            return HardwareItemCard(
              name: amplifier.name,
              assetImagePath: amplifier.assetImagePath,
              itemId: amplifier.id,
              // zone: getZoneData(amplifier.id),
              location: getLocationName(amplifier.locationEntity.listeningAreaId) ?? "Add Location",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(amplifier.id, SelectedItemType.amplifier),
              onHover: () => _projectViewModel.setHoveredDevice(amplifier.id, SelectedItemType.amplifier),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
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

  /// Controllers content using CommonReorderableListView
  Widget _buildControllersContent() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
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
              final bool isHovered = hoveredDevice?.id == controller.id && hoveredDevice?.type == SelectedItemType.controller;
              final bool isSelected = selectedDevice?.id == controller.id && selectedDevice?.type == SelectedItemType.controller;

              return HardwareItemCard(
                name: controller.name,
                assetImagePath: controller.assetImagePath,
                itemId: controller.id,
                zone: getZoneData(controller.id),
                location: getLocationName(controller.locationEntity.listeningAreaId) ?? "Add Location",
                isHovered: isHovered,
                isSelected: isSelected,
                onTap: () => _projectViewModel.setSelectedDevice(controller.id, SelectedItemType.controller),
                onHover: () => _projectViewModel.setHoveredDevice(controller.id, SelectedItemType.controller),
                onExit: () => _projectViewModel.setHoveredDevice(null, null),
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
      ),
    );
  }

  /// Accessories content using CommonReorderableListView
  Widget _buildSwitchesContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        return CommonReorderableListView<NetworkSwitch>(
          items: _projectViewModel.networkSwitches,
          emptyMessage: "No accessories added yet",
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final NetworkSwitch item = _projectViewModel.networkSwitches.removeAt(oldIndex);
              _projectViewModel.networkSwitches.insert(newIndex, item);
              _projectViewModel.setSelectedDevice('accessory_$newIndex', SelectedItemType.switchs);
            });
          },
          keyExtractor: (NetworkSwitch networkSwitch) => networkSwitch.id,
          itemBuilder: (BuildContext context, NetworkSwitch networkSwitch, int index) {
            final bool isHovered = hoveredDevice?.id == networkSwitch.id && hoveredDevice?.type == SelectedItemType.switchs;
            final bool isSelected = selectedDevice?.id == networkSwitch.id && selectedDevice?.type == SelectedItemType.switchs;

            return HardwareItemCard(
              name: networkSwitch.name,
              assetImagePath: networkSwitch.assetImagePath,
              itemId: networkSwitch.id,
              // zone: getZoneData(accessoryId),
              location: getLocationName(networkSwitch.locationEntity.listeningAreaId) ?? "Add Location",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(networkSwitch.id, SelectedItemType.switchs),
              onHover: () => _projectViewModel.setHoveredDevice(networkSwitch.id, SelectedItemType.switchs),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
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
            // setState(() {
            //   if (newIndex > oldIndex) newIndex -= 1;
            //   final Map<String, dynamic> item = _reorderableZones.removeAt(oldIndex);
            //   _reorderableZones.insert(newIndex, item);
            // });
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
                onZoneReorder: (String zoneId, int oldIndex, int newIndex) {
                  // setState(() {
                  //   if (newIndex > oldIndex) newIndex -= 1;
                  //   final Map<String, dynamic> item = _reorderableZones.removeAt(oldIndex);
                  //   _reorderableZones.insert(newIndex, item);
                  // });
                },
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
                  FusionToast.success(
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
