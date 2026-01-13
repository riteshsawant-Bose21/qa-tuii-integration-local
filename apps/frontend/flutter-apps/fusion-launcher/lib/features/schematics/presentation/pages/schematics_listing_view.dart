import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';

import '../../../../core/models/products_data.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../widgets/common_devices_section_widget.dart';
import '../widgets/common_reorderable_list_view.dart';
import '../widgets/expandable_zone_widget.dart';
import '../widgets/hardware_item_card.dart';

class SchematicsListingview extends StatefulWidget {
  const SchematicsListingview({super.key});

  @override
  State<SchematicsListingview> createState() => _SchematicsListingviewState();
}

class _SchematicsListingviewState extends State<SchematicsListingview> {
  static const double _speakersWidthRatio = 0.25; // 25% of available width
  static const double _normalColumnWidthRatio = 0.1875; // 18.75% each (4 columns = 75%)

  /// Get ProjectViewModel instance
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  String _sourcesEndpointsSearchQuery = '';
  DeviceSearchScope? _sourcesEndpointsSearchScope;

  /// Processors & Amplifiers search state
  String _processorsAmplifiersSearchQuery = '';
  DeviceSearchScope? _processorsAmplifiersSearchScope;

  /// Controllers search state
  String _controllersSearchQuery = '';

  /// Accessories search state
  String _accessoriesSearchQuery = '';
  DeviceSearchScope? _accessoriesSearchScope;

  ///Speakers search state
  String _speakersSearchQuery = '';

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
  String? getZoneName(String hardwareId) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    String? zoneName = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.name;
    if (zoneName == null || zoneName.trim().isEmpty) {
      zoneName = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId)?.name;
    }
    return zoneName;
  }

  Color? getZoneColor(String hardwareId) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    Color? zoneColor = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.color;
    if (zoneColor == null) {
      final SubZone? subZone = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId);
      if (subZone != null) zoneColor = projectViewModel.getZoneForSubZone(subZoneId: subZone.id)?.color;
    }
    return zoneColor;
  }

  String? getEquipmentLocationForHardware(String hardwareId) {
    return _projectViewModel.getEquipLocationForHardware(hardwareId: hardwareId)?.name;
  }

  /// sources & endpoints result count
  int _sourcesEndpointsResultCount() {
    if (_sourcesEndpointsSearchQuery.isEmpty) {
      return _projectViewModel.sources.length + _projectViewModel.fusionEndpoints.length;
    }
    final int sources =
        (_sourcesEndpointsSearchScope == DeviceSearchScope.endpoints)
            ? 0
            : _projectViewModel.sources
                .where(
                  (Source s) => s.name.toLowerCase().contains(
                    _sourcesEndpointsSearchQuery,
                  ),
                )
                .length;
    final int endpoints =
        (_sourcesEndpointsSearchScope == DeviceSearchScope.sources)
            ? 0
            : _projectViewModel.fusionEndpoints
                .where(
                  (FusionEndpoints e) => e.name.toLowerCase().contains(
                    _sourcesEndpointsSearchQuery,
                  ),
                )
                .length;
    return sources + endpoints;
  }

  /// processors & amplifiers result count
  int _processorsAmplifiersResultCount() {
    if (_processorsAmplifiersSearchQuery.isEmpty) {
      return _projectViewModel.fusionDsps.length + _projectViewModel.amplifiers.length;
    }
    final int processors =
        (_processorsAmplifiersSearchScope == DeviceSearchScope.amplifiers)
            ? 0
            : _projectViewModel.fusionDsps
                .where(
                  (FusionDsp p) => p.name.toLowerCase().contains(
                    _processorsAmplifiersSearchQuery,
                  ),
                )
                .length;
    final int amplifiers =
        (_processorsAmplifiersSearchScope == DeviceSearchScope.fusionDevices)
            ? 0
            : _projectViewModel.amplifiers
                .where(
                  (Amplifier a) => a.name.toLowerCase().contains(
                    _processorsAmplifiersSearchQuery,
                  ),
                )
                .length;
    return processors + amplifiers;
  }

  /// controllers result count
  int _controllersResultCount() {
    if (_controllersSearchQuery.isEmpty) return _projectViewModel.fusionControllers.length;
    return _projectViewModel.fusionControllers
        .where(
          (FusionController c) => c.name.toLowerCase().contains(_controllersSearchQuery),
        )
        .length;
  }

  /// accessories result count
  int _accessoriesResultCount() {
    if (_accessoriesSearchQuery.isEmpty) {
      return _projectViewModel.hardwareRacks.length + _projectViewModel.networkSwitches.length;
    }
    final int racks =
        (_accessoriesSearchScope == DeviceSearchScope.switches)
            ? 0
            : _projectViewModel.hardwareRacks
                .where(
                  (HardwareRack r) => r.name.toLowerCase().contains(_accessoriesSearchQuery),
                )
                .length;
    final int switches =
        (_accessoriesSearchScope == DeviceSearchScope.racks)
            ? 0
            : _projectViewModel.networkSwitches
                .where(
                  (NetworkSwitch s) => s.name.toLowerCase().contains(_accessoriesSearchQuery),
                )
                .length;
    return racks + switches;
  }

  /// speakers result count
  int _speakersResultCount() {
    if (_speakersSearchQuery.isEmpty) return _projectViewModel.zones.length;
    return _projectViewModel.zones.where((Zone z) => z.name.toLowerCase().contains(_speakersSearchQuery)).length;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;

        /// Calculate column widths proportionally to prevent overflow
        final double speakersColumnWidth = availableWidth * _speakersWidthRatio;
        final double normalColumnWidth = availableWidth * _normalColumnWidthRatio;

        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "schematic_listing_view_area"),
          child: Container(
            color: Colors.white,
            child: Row(
              children: <Widget>[
                /// Sources & Endpoints
                CommonDevicesSectionWidget(
                  title: "Sources & Endpoints",
                  width: normalColumnWidth,
                  height: double.infinity,
                  backgroundColor: Colors.grey[200]!,
                  sectionContent: Container(),
                  enableExpandable: true,
                  searchResultCount: _sourcesEndpointsResultCount(),
                  searchQuery: _sourcesEndpointsSearchQuery,
                  onSearchChanged: (String query) {
                    _projectViewModel.clearSelections();
                    setState(() {
                      _sourcesEndpointsSearchQuery = query.toLowerCase();
                      if (_sourcesEndpointsSearchQuery.isEmpty) {
                        _sourcesEndpointsSearchScope = null;
                        return;
                      }
                      final List<Source> sourceMatches =
                          _projectViewModel.sources
                              .where(
                                (Source s) => s.name.toLowerCase().contains(
                                  _sourcesEndpointsSearchQuery,
                                ),
                              )
                              .toList();
                      final List<FusionEndpoints> endpointMatches =
                          _projectViewModel.fusionEndpoints
                              .where(
                                (FusionEndpoints e) => e.name.toLowerCase().contains(_sourcesEndpointsSearchQuery),
                              )
                              .toList();
                      if (sourceMatches.isNotEmpty && endpointMatches.isEmpty) {
                        _sourcesEndpointsSearchScope = DeviceSearchScope.sources;
                      } else if (endpointMatches.isNotEmpty && sourceMatches.isEmpty) {
                        _sourcesEndpointsSearchScope = DeviceSearchScope.endpoints;
                      } else {
                        _sourcesEndpointsSearchScope = null;
                      }
                    });
                  },
                  expandableSections: <ExpandableSection>[
                    if (_sourcesEndpointsSearchQuery.isEmpty || _sourcesEndpointsSearchScope != DeviceSearchScope.endpoints)
                      ExpandableSection(
                        title: "Sources",
                        content: _buildSourcesContent(),
                        initiallyExpanded: true,
                      ),
                    if (_sourcesEndpointsSearchQuery.isEmpty || _sourcesEndpointsSearchScope != DeviceSearchScope.sources)
                      ExpandableSection(
                        title: "Endpoints",
                        content: _buildEndpointsContent(),
                        initiallyExpanded: true,
                      ),
                  ],
                  listeningAreas: _projectViewModel.listeningAreas,
                  selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.source ? _projectViewModel.selectedDevice?.id : null,
                  onTapAddDevice: (dynamic item, String areaId, String floorId) {
                    /// Sources [onTapAddDevice]
                    if (item is SourceData) {
                      final SourceType type = SourceData.getSourceType(item.id);
                      final SourceConnectionType connectType = SourceData.getSourceConnectionType(item.id);
                      final PortType portType = switch (connectType) {
                        SourceConnectionType.analogInput || SourceConnectionType.aes67input => PortType.analogOutput,
                        SourceConnectionType.bluetooth => PortType.bleOut,
                        SourceConnectionType.usb => PortType.usbOut,
                        SourceConnectionType.audioJack => PortType.audioJackOutput,
                        SourceConnectionType.xlr => PortType.xlrOutput,
                      };
                      final Source source = Source(
                        name: item.name,
                        pos: null,
                        type: item.type,
                        addedFromBuildingPage: false,
                        connectionType: connectType,
                        assetImagePath: item.assetPath,
                        locationEntity: LocationModel(
                          listeningAreaId: areaId,
                          floorId: floorId,
                        ),
                        sku: item.id,
                        price: item.price,
                        portData: HardwarePortData(
                          inputPorts: 0,
                          outputPorts: 1,
                          inputPortType: PortType.analogInput,
                          outputPortType: portType,
                          compatibleInputTypes: <PortType>[],
                          compatibleOutputTypes: switch (connectType) {
                            SourceConnectionType.analogInput || SourceConnectionType.aes67input => <PortType>[
                              PortType.dspAnalogInput,
                              PortType.endpointInput,
                            ],
                            SourceConnectionType.bluetooth => <PortType>[
                              PortType.bleIn,
                            ],
                            SourceConnectionType.usb => <PortType>[PortType.usbIn],
                            SourceConnectionType.audioJack => <PortType>[PortType.audioJackInput],
                            SourceConnectionType.xlr => <PortType>[PortType.xlrInput],
                          },
                          portPosition: PortPosition.topLeft,
                        ),
                      );
                      serviceLocator<ProjectViewModel>().addHardware(
                        hardware: source,
                      );
                      FusionToast.success(
                        context,
                        message: "Source \"${item.name}\" added",
                      );
                    }
                    /// Endpoints [onTapAddDevice]
                    else if (item is ProductQueryModel) {
                      final HardwareComponent hardware = serviceLocator<ProjectViewModel>().fromProductQueryModel(
                        item,
                        locationEntity: LocationModel(
                          listeningAreaId: areaId,
                          floorId: floorId,
                        ),
                        isFromBuildingPage: false,
                      );

                      serviceLocator<ProjectViewModel>().addHardware(
                        hardware: hardware,
                      );
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
                  sectionContent: Container(),
                  enableExpandable: true,
                  searchResultCount: _processorsAmplifiersResultCount(),
                  searchQuery: _processorsAmplifiersSearchQuery,
                  onSearchChanged: (String q) {
                    _projectViewModel.clearSelections();

                    setState(() {
                      _processorsAmplifiersSearchQuery = q.toLowerCase();
                      if (_processorsAmplifiersSearchQuery.isEmpty) {
                        _processorsAmplifiersSearchScope = null;
                        return;
                      }
                      final List<FusionDsp> processorMatches =
                          _projectViewModel.fusionDsps
                              .where(
                                (FusionDsp p) => p.name.toLowerCase().contains(
                                  _processorsAmplifiersSearchQuery,
                                ),
                              )
                              .toList();
                      final List<Amplifier> amplifierMatches =
                          _projectViewModel.amplifiers
                              .where(
                                (Amplifier a) => a.name.toLowerCase().contains(
                                  _processorsAmplifiersSearchQuery,
                                ),
                              )
                              .toList();
                      if (processorMatches.isNotEmpty && amplifierMatches.isEmpty) {
                        _processorsAmplifiersSearchScope = DeviceSearchScope.fusionDevices;
                      } else if (amplifierMatches.isNotEmpty && processorMatches.isEmpty) {
                        _processorsAmplifiersSearchScope = DeviceSearchScope.amplifiers;
                      } else {
                        _processorsAmplifiersSearchScope = null;
                      }
                    });
                  },
                  expandableSections: <ExpandableSection>[
                    if (_processorsAmplifiersSearchQuery.isEmpty || _processorsAmplifiersSearchScope != DeviceSearchScope.amplifiers)
                      ExpandableSection(
                        title: "Fusion Devices",
                        content: _buildProcessorsContent(),
                        initiallyExpanded: true,
                      ),
                    if (_processorsAmplifiersSearchQuery.isEmpty || _processorsAmplifiersSearchScope != DeviceSearchScope.fusionDevices)
                      ExpandableSection(
                        title: "Amplifiers",
                        content: _buildAmplifiersContent(),
                        initiallyExpanded: true,
                      ),
                  ],
                  listeningAreas: _projectViewModel.listeningAreas,
                  selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.processor ? _projectViewModel.selectedDevice?.id : null,
                  // onTapAddDevice: (dynamic item, String areaId, String floorId) {
                  //   print("Adding hardware of type: ${item.type}");
                  //
                  //   if (item is ProductQueryModel) {
                  //     final HardwareComponent hardware = serviceLocator<ProjectViewModel>().fromProductQueryModel(
                  //       item,
                  //       locationEntity: LocationModel(
                  //         listeningAreaId: areaId,
                  //         floorId: floorId,
                  //       ),
                  //       isFromBuildingPage: false,
                  //     );
                  //     if (item.type == ProductType.dsps) {
                  //       serviceLocator<ProjectViewModel>().addHardware(
                  //         hardware: hardware,
                  //       );
                  //       FusionToast.success(
                  //         context,
                  //         message: "Processors \"${item.name}\" added",
                  //       );
                  //     } else {
                  //       serviceLocator<ProjectViewModel>().addHardware(
                  //         hardware: hardware,
                  //       );
                  //       FusionToast.success(
                  //         context,
                  //         message: "Amplifier \"${item.name}\" added",
                  //       );
                  //       return;
                  //     }
                  //   }
                  // },
                ),

                /// Speakers
                CommonDevicesSectionWidget(
                  title: "Speakers",
                  width: speakersColumnWidth,
                  height: double.infinity,
                  backgroundColor: Colors.white,
                  sectionContent: _buildSpeakersContent(),
                  listeningAreas: _projectViewModel.listeningAreas,
                  selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.zone ? _projectViewModel.selectedDevice?.id : null,
                  onSearchChanged: (String q) {
                    _projectViewModel.clearSelections();
                    setState(() {
                      _speakersSearchQuery = q.toLowerCase();
                    });
                  },
                  searchResultCount: _speakersResultCount(),
                  searchQuery: _speakersSearchQuery,
                ),

                /// Controllers
                CommonDevicesSectionWidget(
                  title: "Controllers",
                  width: normalColumnWidth,
                  height: double.infinity,
                  backgroundColor: Colors.grey[200]!,
                  sectionContent: Container(),
                  enableExpandable: true,
                  searchResultCount: _controllersResultCount(),
                  searchQuery: _controllersSearchQuery,
                  onSearchChanged: (String q) {
                    _projectViewModel.clearSelections();
                    setState(() {
                      _controllersSearchQuery = q.toLowerCase();
                    });
                  },
                  expandableSections: <ExpandableSection>[
                    ExpandableSection(
                      title: "Controllers",
                      content: _buildControllersList(),
                      initiallyExpanded: true,
                    ),
                  ],
                  listeningAreas: _projectViewModel.listeningAreas,
                  selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.controller ? _projectViewModel.selectedDevice?.id : null,
                  onTapAddDevice: (dynamic item, String areaId, String floorId) {
                    if (item is ProductQueryModel) {
                      final HardwareComponent hardware = serviceLocator<ProjectViewModel>().fromProductQueryModel(
                        item,
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
                        message: "Controller \"${item.name}\" added",
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
                  sectionContent: Container(),
                  enableExpandable: true,
                  searchResultCount: _accessoriesResultCount(),
                  searchQuery: _accessoriesSearchQuery,
                  onSearchChanged: (String q) {
                    _projectViewModel.clearSelections();
                    setState(() {
                      _accessoriesSearchQuery = q.toLowerCase();
                      if (_accessoriesSearchQuery.isEmpty) {
                        _accessoriesSearchScope = null;
                        return;
                      }
                      final List<HardwareRack> rackMatches =
                          _projectViewModel.hardwareRacks
                              .where(
                                (HardwareRack r) => r.name.toLowerCase().contains(
                                  _accessoriesSearchQuery,
                                ),
                              )
                              .toList();
                      final List<NetworkSwitch> switchMatches =
                          _projectViewModel.networkSwitches
                              .where(
                                (NetworkSwitch s) => s.name.toLowerCase().contains(_accessoriesSearchQuery),
                              )
                              .toList();
                      if (rackMatches.isNotEmpty && switchMatches.isEmpty) {
                        _accessoriesSearchScope = DeviceSearchScope.racks;
                      } else if (switchMatches.isNotEmpty && rackMatches.isEmpty) {
                        _accessoriesSearchScope = DeviceSearchScope.switches;
                      } else {
                        _accessoriesSearchScope = null;
                      }
                    });
                  },
                  expandableSections: <ExpandableSection>[
                    if (_accessoriesSearchQuery.isEmpty || _accessoriesSearchScope != DeviceSearchScope.switches)
                      ExpandableSection(
                        title: "Racks",
                        content: _buildRacksContent(),
                        initiallyExpanded: true,
                      ),
                    if (_accessoriesSearchQuery.isEmpty || _accessoriesSearchScope != DeviceSearchScope.racks)
                      ExpandableSection(
                        title: "Switches",
                        content: _buildSwitchesContent(),
                        initiallyExpanded: true,
                      ),
                  ],
                  listeningAreas: _projectViewModel.listeningAreas,
                  selectedDeviceId: _projectViewModel.selectedDevice?.type == SelectedItemType.racks ? _projectViewModel.selectedDevice?.id : null,
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
              ],
            ),
          ),
        );
      },
    );
  }

  /// Create a simple controllers list without expandable wrapper
  Widget _buildControllersList() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final List<FusionController> filteredControllers =
            _projectViewModel.fusionControllers
                .where(
                  (FusionController c) => _controllersSearchQuery.isEmpty || c.name.toLowerCase().contains(_controllersSearchQuery),
                )
                .toList();
        return CommonReorderableListView<FusionController>(
          items: filteredControllers,
          emptyMessage: _controllersSearchQuery.isEmpty ? "No controllers added yet" : "No controllers match search",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String hwToMove = filteredControllers[oldIndex].id;
            final String hwAtNewIndex = filteredControllers[newIndex].id;
            _projectViewModel.reOrderHardware(
              hardwareIdToMove: hwToMove,
              hardwareAtNewIndex: hwAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              hwToMove,
              SelectedItemType.controller,
            );
          },
          keyExtractor: (FusionController controller) => controller.id,
          itemBuilder: (
            BuildContext context,
            FusionController controller,
            int index,
          ) {
            final bool isSelected = selectedDevice?.id == controller.id && selectedDevice?.type == SelectedItemType.controller;
            return HardwareItemCard(
              index: index,
              name: controller.name,
              highlightQuery: _controllersSearchQuery,
              assetImagePath: controller.assetImagePath,
              itemId: controller.id,
              zoneName: getZoneName(controller.id),
              zoneColor: getZoneColor(controller.id),
              location: getLocationName(controller.locationEntity.listeningAreaId) ?? "Add location",

              equipmentLocation: getEquipmentLocationForHardware(controller.id),
              isSelected: isSelected,
              onTap:
                  () => _projectViewModel.setSelectedDevice(
                    controller.id,
                    SelectedItemType.controller,
                  ),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(
                  hardwareId: id,
                );
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
    if (_sourcesEndpointsSearchQuery.isNotEmpty && _sourcesEndpointsSearchScope == DeviceSearchScope.endpoints) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final List<Source> filteredSources =
            _projectViewModel.sources
                .where(
                  (Source s) =>
                      _sourcesEndpointsSearchQuery.isEmpty ||
                      s.name.toLowerCase().contains(
                        _sourcesEndpointsSearchQuery,
                      ),
                )
                .toList();

        return CommonReorderableListView<Source>(
          items: filteredSources,
          emptyMessage: _sourcesEndpointsSearchQuery.isEmpty ? "No sources added yet" : "No sources match search",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String hwToMove = filteredSources[oldIndex].id;
            final String hwAtNewIndex = filteredSources[newIndex].id;
            _projectViewModel.reOrderHardware(
              hardwareIdToMove: hwToMove,
              hardwareAtNewIndex: hwAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              hwToMove,
              SelectedItemType.source,
            );
          },
          keyExtractor: (Source source) => source.id,
          itemBuilder: (BuildContext context, Source source, int index) {
            final bool isSelected = selectedDevice?.id == source.id && selectedDevice?.type == SelectedItemType.source;
            return HardwareItemCard(
              index: index,
              name: source.name,
              highlightQuery: _sourcesEndpointsSearchQuery,
              assetImagePath: source.assetImagePath,
              itemId: source.id,
              zoneName: getZoneName(source.id),
              zoneColor: getZoneColor(source.id),
              location: getLocationName(source.locationEntity.listeningAreaId) ?? "Add location",
              equipmentLocation: getEquipmentLocationForHardware(source.id),
              isSelected: isSelected,
              onTap:
                  () => _projectViewModel.setSelectedDevice(
                    source.id,
                    SelectedItemType.source,
                  ),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(
                  hardwareId: id,
                );
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
    if (_sourcesEndpointsSearchQuery.isNotEmpty && _sourcesEndpointsSearchScope == DeviceSearchScope.sources) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final List<FusionEndpoints> filteredEndpoints =
            _projectViewModel.fusionEndpoints
                .where(
                  (FusionEndpoints e) =>
                      _sourcesEndpointsSearchQuery.isEmpty ||
                      e.name.toLowerCase().contains(
                        _sourcesEndpointsSearchQuery,
                      ),
                )
                .toList();

        return CommonReorderableListView<FusionEndpoints>(
          items: filteredEndpoints,
          emptyMessage: _sourcesEndpointsSearchQuery.isEmpty ? "No endpoints added yet" : "No endpoints match search",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String hwToMove = filteredEndpoints[oldIndex].id;
            final String hwAtNewIndex = filteredEndpoints[newIndex].id;
            _projectViewModel.reOrderHardware(
              hardwareIdToMove: hwToMove,
              hardwareAtNewIndex: hwAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              hwToMove,
              SelectedItemType.endpoint,
            );
          },
          keyExtractor: (FusionEndpoints endpoint) => endpoint.id,
          itemBuilder: (
            BuildContext context,
            FusionEndpoints endpoint,
            int index,
          ) {
            final bool isSelected = selectedDevice?.id == endpoint.id && selectedDevice?.type == SelectedItemType.endpoint;
            return HardwareItemCard(
              index: index,
              name: endpoint.name,
              highlightQuery: _sourcesEndpointsSearchQuery, // new
              assetImagePath: endpoint.assetImagePath,
              itemId: endpoint.id,
              zoneName: getZoneName(endpoint.id),
              zoneColor: getZoneColor(endpoint.id),
              location: getLocationName(endpoint.locationEntity.listeningAreaId) ?? "Add location",
              equipmentLocation: getEquipmentLocationForHardware(endpoint.id),

              isSelected: isSelected,
              onTap:
                  () => _projectViewModel.setSelectedDevice(
                    endpoint.id,
                    SelectedItemType.endpoint,
                  ),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(
                  hardwareId: id,
                );
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
    if (_processorsAmplifiersSearchQuery.isNotEmpty && _processorsAmplifiersSearchScope == DeviceSearchScope.amplifiers) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final List<FusionDsp> filteredProcessors =
            _projectViewModel.fusionDsps
                .where(
                  (FusionDsp p) =>
                      _processorsAmplifiersSearchQuery.isEmpty ||
                      p.name.toLowerCase().contains(
                        _processorsAmplifiersSearchQuery,
                      ),
                )
                .toList();
        return CommonReorderableListView<FusionDsp>(
          items: filteredProcessors,
          emptyMessage: _processorsAmplifiersSearchQuery.isEmpty ? "No processors added yet" : "No processors match search",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String hwToMove = filteredProcessors[oldIndex].id;
            final String hwAtNewIndex = filteredProcessors[newIndex].id;
            _projectViewModel.reOrderHardware(
              hardwareIdToMove: hwToMove,
              hardwareAtNewIndex: hwAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              hwToMove,
              SelectedItemType.processor,
            );
          },
          keyExtractor: (FusionDsp processor) => processor.id,
          itemBuilder: (BuildContext context, FusionDsp processor, int index) {
            final bool isSelected = selectedDevice?.id == processor.id && selectedDevice?.type == SelectedItemType.processor;

            return HardwareItemCard(
              index: index,
              name: processor.name,
              highlightQuery: _processorsAmplifiersSearchQuery,
              assetImagePath: processor.assetImagePath,
              itemId: processor.id,
              zoneName: getZoneName(processor.id),
              zoneColor: getZoneColor(processor.id),
              location: getLocationName(processor.locationEntity.listeningAreaId) ?? "Add location",
              equipmentLocation: getEquipmentLocationForHardware(processor.id),

              isSelected: isSelected,
              onTap:
                  () => _projectViewModel.setSelectedDevice(
                    processor.id,
                    SelectedItemType.processor,
                  ),
              onDelete: (String id) {
                _projectViewModel.removeHardware(hardwareId: processor.id);
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

  /// Amplifiers content using CommonReorderableListView
  Widget _buildAmplifiersContent() {
    if (_processorsAmplifiersSearchQuery.isNotEmpty && _processorsAmplifiersSearchScope == DeviceSearchScope.fusionDevices) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final List<Amplifier> filteredAmplifiers =
            _projectViewModel.amplifiers
                .where(
                  (Amplifier a) =>
                      _processorsAmplifiersSearchQuery.isEmpty ||
                      a.name.toLowerCase().contains(
                        _processorsAmplifiersSearchQuery,
                      ),
                )
                .toList();
        return CommonReorderableListView<Amplifier>(
          items: filteredAmplifiers,
          emptyMessage: _processorsAmplifiersSearchQuery.isEmpty ? "No amplifiers added yet" : "No amplifiers match search",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String hwToMove = filteredAmplifiers[oldIndex].id;
            final String hwAtNewIndex = filteredAmplifiers[newIndex].id;
            _projectViewModel.reOrderHardware(
              hardwareIdToMove: hwToMove,
              hardwareAtNewIndex: hwAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              hwToMove,
              SelectedItemType.amplifier,
            );
          },
          keyExtractor: (Amplifier amplifier) => amplifier.id,
          itemBuilder: (BuildContext context, Amplifier amplifier, int index) {
            final bool isSelected = selectedDevice?.id == amplifier.id && selectedDevice?.type == SelectedItemType.amplifier;

            return HardwareItemCard(
              index: index,
              name: amplifier.name,
              highlightQuery: _processorsAmplifiersSearchQuery, // new
              assetImagePath: amplifier.assetImagePath,
              itemId: amplifier.id,
              zoneName: getZoneName(amplifier.id),
              zoneColor: getZoneColor(amplifier.id),
              location: getLocationName(amplifier.locationEntity.listeningAreaId) ?? "Add location",
              equipmentLocation: getEquipmentLocationForHardware(amplifier.id),
              isSelected: isSelected,
              onTap:
                  () => _projectViewModel.setSelectedDevice(
                    amplifier.id,
                    SelectedItemType.amplifier,
                  ),
              onDelete: (String id) {
                _projectViewModel.removeHardware(hardwareId: amplifier.id);
                FusionToast.error(
                  context,
                  message: 'Amplifier "${amplifier.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename amplifier $id'),
              onDuplicate: (String id) => print('Duplicate amplifier $id'),
            );
          },
        );
      },
    );
  }

  /// Racks content using CommonReorderableListView
  Widget _buildRacksContent() {
    if (_accessoriesSearchQuery.isNotEmpty && _accessoriesSearchScope == DeviceSearchScope.switches) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final List<HardwareRack> filteredRacks =
            _projectViewModel.hardwareRacks
                .where(
                  (HardwareRack r) => _accessoriesSearchQuery.isEmpty || r.name.toLowerCase().contains(_accessoriesSearchQuery),
                )
                .toList();
        return CommonReorderableListView<HardwareRack>(
          items: filteredRacks,
          emptyMessage: _accessoriesSearchQuery.isEmpty ? "No racks added yet" : "No racks match search",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String hwToMove = filteredRacks[oldIndex].id;
            final String hwAtNewIndex = filteredRacks[newIndex].id;
            _projectViewModel.reOrderHardware(
              hardwareIdToMove: hwToMove,
              hardwareAtNewIndex: hwAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              hwToMove,
              SelectedItemType.racks,
            );
          },
          keyExtractor: (HardwareRack hardwareRack) => hardwareRack.id,
          itemBuilder: (
            BuildContext context,
            HardwareRack hardwareRack,
            int index,
          ) {
            final bool isSelected = selectedDevice?.id == hardwareRack.id && selectedDevice?.type == SelectedItemType.racks;

            return HardwareItemCard(
              index: index,
              name: hardwareRack.name,
              highlightQuery: _accessoriesSearchQuery, // new
              assetImagePath: hardwareRack.assetImagePath,
              itemId: hardwareRack.id,
              zoneName: getZoneName(hardwareRack.id),
              zoneColor: getZoneColor(hardwareRack.id),
              location:
                  getLocationName(
                    hardwareRack.locationEntity.listeningAreaId,
                  ) ??
                  "Add location",
              equipmentLocation: getEquipmentLocationForHardware(hardwareRack.id),

              isSelected: isSelected,
              onTap:
                  () => _projectViewModel.setSelectedDevice(
                    hardwareRack.id,
                    SelectedItemType.racks,
                  ),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(
                  hardwareId: id,
                );
                FusionToast.error(
                  context,
                  message: 'Rack "${hardwareRack.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename rack $id'),
              onDuplicate: (String id) => print('Duplicate rack $id'),
            );
          },
        );
      },
    );
  }

  /// Accessories content using CommonReorderableListView
  Widget _buildSwitchesContent() {
    if (_accessoriesSearchQuery.isNotEmpty && _accessoriesSearchScope == DeviceSearchScope.racks) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
        final List<NetworkSwitch> filteredSwitches =
            _projectViewModel.networkSwitches
                .where(
                  (NetworkSwitch s) => _accessoriesSearchQuery.isEmpty || s.name.toLowerCase().contains(_accessoriesSearchQuery),
                )
                .toList();
        return CommonReorderableListView<NetworkSwitch>(
          items: filteredSwitches,
          emptyMessage: _accessoriesSearchQuery.isEmpty ? "No switches added yet" : "No switches match search",
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String hwToMove = filteredSwitches[oldIndex].id;
            final String hwAtNewIndex = filteredSwitches[newIndex].id;
            _projectViewModel.reOrderHardware(
              hardwareIdToMove: hwToMove,
              hardwareAtNewIndex: hwAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              hwToMove,
              SelectedItemType.switchs,
            );
          },
          keyExtractor: (NetworkSwitch networkSwitch) => networkSwitch.id,
          itemBuilder: (
            BuildContext context,
            NetworkSwitch networkSwitch,
            int index,
          ) {
            final bool isSelected = selectedDevice?.id == networkSwitch.id && selectedDevice?.type == SelectedItemType.switchs;
            return HardwareItemCard(
              index: index,
              name: networkSwitch.name,
              highlightQuery: _accessoriesSearchQuery, // new
              assetImagePath: networkSwitch.assetImagePath,
              itemId: networkSwitch.id,
              zoneName: getZoneName(networkSwitch.id),
              zoneColor: getZoneColor(networkSwitch.id),
              location:
                  getLocationName(
                    networkSwitch.locationEntity.listeningAreaId,
                  ) ??
                  "Add location",
              equipmentLocation: getEquipmentLocationForHardware(networkSwitch.id),

              isSelected: isSelected,
              onTap:
                  () => _projectViewModel.setSelectedDevice(
                    networkSwitch.id,
                    SelectedItemType.switchs,
                  ),
              onDelete: (String id) {
                serviceLocator<ProjectViewModel>().removeHardware(
                  hardwareId: id,
                );
                FusionToast.error(
                  context,
                  message: 'Switch "${networkSwitch.name}" deleted',
                );
              },
              onRename: (String id) => print('Rename switch $id'),
              onDuplicate: (String id) => print('Duplicate switch $id'),
            );
          },
        );
      },
    );
  }

  Widget _buildSpeakersContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<Zone> filteredZones =
            _projectViewModel.zones
                .where(
                  (Zone z) => _speakersSearchQuery.isEmpty || z.name.toLowerCase().contains(_speakersSearchQuery),
                )
                .toList();

        if (filteredZones.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FusionAppText(
                text: _speakersSearchQuery.isEmpty ? "No zones added yet" : "No zones match search",
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
          itemCount: filteredZones.length,
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final String zoneToMove = filteredZones[oldIndex].id;
            final String zoneAtNewIndex = filteredZones[newIndex].id;
            _projectViewModel.reorderZones(
              zoneIdToMove: zoneToMove,
              zoneIdAtNewIndex: zoneAtNewIndex,
            );
            _projectViewModel.setSelectedDevice(
              zoneToMove,
              SelectedItemType.zone,
            );
          },
          itemBuilder: (BuildContext context, int index) {
            final Zone zoneData = filteredZones[index];
            return ReorderableDragStartListener(
              key: ValueKey<String>(zoneData.id),
              index: index,
              child: ExpandableZoneWidget(
                index: index,
                zoneName: zoneData.name,
                zoneId: zoneData.id,
                bgColor: zoneData.color,
                initiallyExpanded: true,
                zoneCircuits: _projectViewModel.getCircuitsInZone(zoneData.id),
                subZones: _projectViewModel.getSubZonesForZone(
                  parentZoneId: zoneData.id,
                ),
                onDelete: (String id) {
                  serviceLocator<ProjectViewModel>().removeZone(
                    zoneId: zoneData.id,
                  );
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
