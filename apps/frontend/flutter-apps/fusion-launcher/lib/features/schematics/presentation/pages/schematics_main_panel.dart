import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../widgets/common_devices_section_widget.dart';
import '../widgets/expandable_zone_widget.dart';
import '../widgets/hardware_item_card.dart';
import '../widgets/common_reorderable_list_view.dart';

class SchematicsMainPanel extends StatefulWidget {
  const SchematicsMainPanel({super.key});

  @override
  State<SchematicsMainPanel> createState() => _SchematicsMainPanelState();
}

class _SchematicsMainPanelState extends State<SchematicsMainPanel> {
  List<Source> _reorderableSources = <Source>[];
  List<Map<String, dynamic>> _reorderableEndpoints = <Map<String, dynamic>>[];
  List<GenericHardwareComponent> _reorderableProcessors = <GenericHardwareComponent>[];
  List<Map<String, dynamic>> _reorderableSpeakers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reorderableControllers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reorderableAccessories = <Map<String, dynamic>>[];

  // Add reorderable lists for zones, subzones, and devices
  List<Map<String, dynamic>> _reorderableZones = <Map<String, dynamic>>[];
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
    // Initialize sources from the view model
    _reorderableSources = List<Source>.from(serviceLocator<ProjectViewModel>().sources);

    // Initialize endpoints
    _reorderableEndpoints = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Audio Input 1', 'assetPath': 'assets/icons/lising_view_icon.png'},
      <String, dynamic>{'name': 'Audio Input 2', 'assetPath': 'assets/icons/lising_view_icon.png'},
      <String, dynamic>{'name': 'HDMI Input', 'assetPath': 'assets/icons/lising_view_icon.png'},
    ];

    // Initialize processors
    final List<FusionDsp> processors = serviceLocator<ProjectViewModel>().fusionDevices;
    _reorderableProcessors =
        processors
            .map(
              (FusionDsp device) => GenericHardwareComponent(
                id: device.id,
                locationEntity: LocationModel(id: device.location),
                name: device.name,
                sku: device.id,
                type: GenericHardwareComponentType.other,
                assetImagePath: "assets/images/processor_img.webp",
                price: 1000,
                pos: const Offset(0, 0),
              ),
            )
            .toList();

    // Initialize speakers
    _reorderableSpeakers = <Map<String, dynamic>>[
      <String, dynamic>{
        "zones": <Map<String, Object>>[
          <String, Object>{
            "id": "zone_001",
            "name": "Main Hall",
            "processingBlocks": <Map<String, Object>>[
              <String, Object>{
                "id": "pb_001",
                "type": "equalizer",
                "parameters": <String, Object>{"bands": 10, "enabled": true},
              },
              <String, Object>{
                "id": "pb_002",
                "type": "compressor",
                "parameters": <String, num>{"threshold": -20, "ratio": 4.0},
              },
            ],
            "selectedMixIndex": 0,
            "listeningAreasIds": <String>["la_001", "la_002", "la_003"],
            "sourceSetIds": <String>["ss_001", "ss_002"],
            "zoneColor": "#FF5733",
            "subZones": <String>["subzone_001", "subzone_002"],
            "circuits": <String>["circuit_001", "circuit_002", "circuit_003"],
          },
          <String, Object>{
            "id": "zone_002",
            "name": "Conference Room A",
            "processingBlocks": <Map<String, Object>>[
              <String, Object>{
                "id": "pb_003",
                "type": "reverb",
                "parameters": <String, double>{"roomSize": 0.7, "decay": 2.5},
              },
            ],
            "selectedMixIndex": 1,
            "listeningAreasIds": <String>["la_004", "la_005"],
            "sourceSetIds": <String>["ss_003"],
            "zoneColor": "#3498DB",
            "subZones": <String>["subzone_003"],
            "circuits": <String>["circuit_004"],
          },
        ],
        "subZones": <Map<String, Object>>[
          <String, Object>{
            "id": "subzone_001",
            "name": "Stage Area",
            "processingBlocks": <Map<String, Object>>[
              <String, Object>{
                "id": "pb_004",
                "type": "delay",
                "parameters": <String, num>{"delayTime": 50, "feedback": 0.3},
              },
            ],
            "listeningAreasIds": <String>["la_001", "la_002"],
            "circuits": <String>["circuit_001", "circuit_002"],
          },
          <String, Object>{
            "id": "subzone_002",
            "name": "Audience Area",
            "processingBlocks": <dynamic>[],
            "listeningAreasIds": <String>["la_003"],
            "circuits": <String>["circuit_003"],
          },
          <String, Object>{
            "id": "subzone_003",
            "name": "Presentation Zone",
            "processingBlocks": <Map<String, Object>>[
              <String, Object>{
                "id": "pb_005",
                "type": "limiter",
                "parameters": <String, int>{"threshold": -3, "release": 100},
              },
            ],
            "listeningAreasIds": <String>["la_004"],
            "circuits": <String>["circuit_004"],
          },
        ],
        "circuits": <Map<String, Object>>[
          <String, Object>{
            "id": "circuit_001",
            "name": "Front Left Speakers",
            "listeningAreaIds": <String>["la_001"],
          },
          <String, Object>{
            "id": "circuit_002",
            "name": "Front Right Speakers",
            "listeningAreaIds": <String>["la_001", "la_002"],
          },
          <String, Object>{
            "id": "circuit_003",
            "name": "Rear Speakers",
            "listeningAreaIds": <String>["la_003"],
          },
          <String, Object>{
            "id": "circuit_004",
            "name": "Ceiling Speakers",
            "listeningAreaIds": <String>["la_004", "la_005"],
          },
        ],
      },
    ];

    // Initialize controllers
    _reorderableControllers = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Control PAL LT', 'assetPath': 'assets/icons/lising_view_icon.png'},
      <String, dynamic>{'name': 'ControlSpace CC-64', 'assetPath': 'assets/icons/lising_view_icon.png'},
    ];

    // Initialize accessories
    _reorderableAccessories = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Rack 4U', 'assetPath': 'assets/icons/lising_view_icon.png'},
      <String, dynamic>{'name': 'Rack 8U', 'assetPath': 'assets/icons/lising_view_icon.png'},
    ];

    // Initialize zones with subzones and devices
    _reorderableZones = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'zone_1',
        'name': 'Main Hall',
        'color': Colors.lightBlueAccent[100],
      },
      <String, dynamic>{
        'id': 'zone_2',
        'name': 'Conference Room',
        'color': Colors.lightGreenAccent[100],
      },
    ];

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
    // Remove local dispose calls - now handled by ProjectViewModel
    // _hoveredDeviceId.dispose();
    // _selectedDeviceId.dispose();
    super.dispose();
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
                sectionContent: _buildSourcesAndEndpointsContent(),
              ),

              // Processors & Amplifiers
              CommonDevicesSectionWidget(
                title: "Processors & Amplifiers",
                width: normalColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.grey[200]!,
                sectionContent: _buildProcessorsContent(),
              ),

              // Speakers (wider and white background)
              CommonDevicesSectionWidget(
                title: "Speakers",
                width: speakersColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.white,
                sectionContent: _buildSpeakersContent(),
              ),

              // Controllers
              CommonDevicesSectionWidget(
                title: "Controllers",
                width: normalColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.grey[200]!,
                sectionContent: _buildControllersContent(),
              ),

              // Accessories
              CommonDevicesSectionWidget(
                title: "Accessories",
                width: normalColumnWidth,
                height: double.infinity,
                backgroundColor: Colors.grey[200]!,
                sectionContent: _buildAccessoriesContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Combined Sources & Endpoints content with separate sections
  Widget _buildSourcesAndEndpointsContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<Source> currentSources = serviceLocator<ProjectViewModel>().sources;

        if (currentSources.length != _reorderableSources.length ||
            !currentSources.every((Source source) => _reorderableSources.any((Source rs) => rs.id == source.id))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _reorderableSources = List<Source>.from(currentSources);
            });
          });
        }

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
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              _buildSourcesContent(),

              const SizedBox(height: 16),

              // Endpoints Section
              FusionAppText(
                text: "Endpoints",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              _buildEndpointsContent(),
            ],
          ),
        );
      },
    );
  }

  /// Optimized Sources content using CommonReorderableListView
  Widget _buildSourcesContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<Source> currentSources = serviceLocator<ProjectViewModel>().sources;
        final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
        final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

        if (currentSources.length != _reorderableSources.length ||
            !currentSources.every((Source source) => _reorderableSources.any((Source rs) => rs.id == source.id))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _reorderableSources = List<Source>.from(currentSources);
            });
          });
        }

        return CommonReorderableListView<Source>(
          items: _reorderableSources,
          emptyMessage: "No sources added yet",
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final Source item = _reorderableSources.removeAt(oldIndex);
              _reorderableSources.insert(newIndex, item);
              _projectViewModel.setSelectedDevice(item.id, SelectedItemType.source);
            });
          },
          keyExtractor: (Source source) => source.id,
          itemBuilder: (BuildContext context, Source source, int index) {
            final bool isHovered = hoveredDevice?.id == source.id && hoveredDevice?.type == SelectedItemType.source;
            final bool isSelected = selectedDevice?.id == source.id && selectedDevice?.type == SelectedItemType.source;

            return HardwareItemCard(
              name: source.name,
              assetImagePath: source.assetImagePath,
              itemId: source.id,
              location: "Eqp Loc.",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(source.id, SelectedItemType.source),
              onHover: () => _projectViewModel.setHoveredDevice(source.id, SelectedItemType.source),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
              onDelete: (String id) {
                final String sourceName = source.name;
                setState(() {
                  _reorderableSources.removeWhere((Source s) => s.id == id);
                });
                serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);
                FusionToast.show(
                  context,
                  message: 'Source "$sourceName" deleted',
                  icon: Icons.delete_outline,
                  backgroundColor: Colors.red[600],
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

        return CommonReorderableListView<Map<String, dynamic>>(
          items: _reorderableEndpoints,
          emptyMessage: "No endpoints added yet",
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final Map<String, dynamic> item = _reorderableEndpoints.removeAt(oldIndex);
              _reorderableEndpoints.insert(newIndex, item);
              _projectViewModel.setSelectedDevice('endpoint_$newIndex', SelectedItemType.endpoint);
            });
          },
          keyExtractor: (Map<String, dynamic> endpoint) => 'endpoint_${endpoint['name']}',
          itemBuilder: (BuildContext context, Map<String, dynamic> endpoint, int index) {
            final String endpointId = 'endpoint_$index';
            final bool isHovered = hoveredDevice?.id == endpointId && hoveredDevice?.type == SelectedItemType.endpoint;
            final bool isSelected = selectedDevice?.id == endpointId && selectedDevice?.type == SelectedItemType.endpoint;

            return HardwareItemCard(
              name: endpoint['name'] as String,
              assetImagePath: endpoint['assetPath'] as String,
              itemId: endpointId,
              location: "Eqp Loc.",
              isHovered: isHovered,
              isSelected: isSelected,
              onTap: () => _projectViewModel.setSelectedDevice(endpointId, SelectedItemType.endpoint),
              onHover: () => _projectViewModel.setHoveredDevice(endpointId, SelectedItemType.endpoint),
              onExit: () => _projectViewModel.setHoveredDevice(null, null),
              onDelete: (String id) {
                final String endpointName = endpoint['name'] as String;
                setState(() {
                  _reorderableEndpoints.removeAt(index);
                });
                FusionToast.show(
                  context,
                  message: 'Endpoint "$endpointName" deleted',
                  icon: Icons.delete_outline,
                  backgroundColor: Colors.red[600],
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

  /// Optimized Processors content using CommonReorderableListView
  Widget _buildProcessorsContent() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
          final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

          return CommonReorderableListView<GenericHardwareComponent>(
            items: _reorderableProcessors,
            emptyMessage: "No processors added yet",
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final GenericHardwareComponent item = _reorderableProcessors.removeAt(oldIndex);
                _reorderableProcessors.insert(newIndex, item);
                _projectViewModel.setSelectedDevice(item.id, SelectedItemType.processor);
              });
            },
            keyExtractor: (GenericHardwareComponent processor) => 'processor_${processor.name}',
            itemBuilder: (BuildContext context, GenericHardwareComponent processor, int index) {
              final String processorId = 'processor_$index';
              final bool isHovered = hoveredDevice?.id == processorId && hoveredDevice?.type == SelectedItemType.processor;
              final bool isSelected = selectedDevice?.id == processorId && selectedDevice?.type == SelectedItemType.processor;

              return HardwareItemCard(
                name: processor.name,
                assetImagePath: 'assets/icons/lising_view_icon.png',
                itemId: processorId,
                location: ' hbv',
                isHovered: isHovered,
                isSelected: isSelected,
                onTap: () => _projectViewModel.setSelectedDevice(processorId, SelectedItemType.processor),
                onHover: () => _projectViewModel.setHoveredDevice(processorId, SelectedItemType.processor),
                onExit: () => _projectViewModel.setHoveredDevice(null, null),
                onDelete: (String id) {
                  final String processorName = processor.name;
                  setState(() {
                    _reorderableProcessors.removeAt(index);
                  });
                  FusionToast.show(
                    context,
                    message: 'Processor "$processorName" deleted',
                    icon: Icons.delete_outline,
                    backgroundColor: Colors.red[600],
                  );
                },
                onRename: (String id) => print('Rename processor $id'),
                onDuplicate: (String id) => print('Duplicate processor $id'),
              );
            },
          );
        },
      ),
    );
  }

  /// Optimized Controllers content using CommonReorderableListView
  Widget _buildControllersContent() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
          final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

          return CommonReorderableListView<Map<String, dynamic>>(
            items: _reorderableControllers,
            emptyMessage: "No controllers added yet",
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final Map<String, dynamic> item = _reorderableControllers.removeAt(oldIndex);
                _reorderableControllers.insert(newIndex, item);
                _projectViewModel.setSelectedDevice('controller_$newIndex', SelectedItemType.controller);
              });
            },
            keyExtractor: (Map<String, dynamic> controller) => 'controller_${controller['name']}',
            itemBuilder: (BuildContext context, Map<String, dynamic> controller, int index) {
              final String controllerId = 'controller_$index';
              final bool isHovered = hoveredDevice?.id == controllerId && hoveredDevice?.type == SelectedItemType.controller;
              final bool isSelected = selectedDevice?.id == controllerId && selectedDevice?.type == SelectedItemType.controller;

              return HardwareItemCard(
                name: controller['name'] as String,
                assetImagePath: controller['assetPath'] as String,
                itemId: controllerId,
                location: "Eqp Loc.",
                isHovered: isHovered,
                isSelected: isSelected,
                onTap: () => _projectViewModel.setSelectedDevice(controllerId, SelectedItemType.controller),
                onHover: () => _projectViewModel.setHoveredDevice(controllerId, SelectedItemType.controller),
                onExit: () => _projectViewModel.setHoveredDevice(null, null),
                onDelete: (String id) {
                  final String controllerName = controller['name'] as String;
                  setState(() {
                    _reorderableControllers.removeAt(index);
                  });
                  FusionToast.show(
                    context,
                    message: 'Controller "$controllerName" deleted',
                    icon: Icons.delete_outline,
                    backgroundColor: Colors.red[600],
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

  /// Optimized Accessories content using CommonReorderableListView
  Widget _buildAccessoriesContent() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final SelectedItem? hoveredDevice = _projectViewModel.hoveredDevice;
          final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;

          return CommonReorderableListView<Map<String, dynamic>>(
            items: _reorderableAccessories,
            emptyMessage: "No accessories added yet",
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final Map<String, dynamic> item = _reorderableAccessories.removeAt(oldIndex);
                _reorderableAccessories.insert(newIndex, item);
                _projectViewModel.setSelectedDevice('accessory_$newIndex', SelectedItemType.accessory);
              });
            },
            keyExtractor: (Map<String, dynamic> accessory) => 'accessory_${accessory['name']}',
            itemBuilder: (BuildContext context, Map<String, dynamic> accessory, int index) {
              final String accessoryId = 'accessory_$index';
              final bool isHovered = hoveredDevice?.id == accessoryId && hoveredDevice?.type == SelectedItemType.accessory;
              final bool isSelected = selectedDevice?.id == accessoryId && selectedDevice?.type == SelectedItemType.accessory;

              return HardwareItemCard(
                name: accessory['name'] as String,
                assetImagePath: accessory['assetPath'] as String,
                itemId: accessoryId,
                location: "Eqp Loc.",
                isHovered: isHovered,
                isSelected: isSelected,
                onTap: () => _projectViewModel.setSelectedDevice(accessoryId, SelectedItemType.accessory),
                onHover: () => _projectViewModel.setHoveredDevice(accessoryId, SelectedItemType.accessory),
                onExit: () => _projectViewModel.setHoveredDevice(null, null),
                onDelete: (String id) {
                  final String accessoryName = accessory['name'] as String;
                  setState(() {
                    _reorderableAccessories.removeAt(index);
                  });
                  FusionToast.show(
                    context,
                    message: 'Accessory "$accessoryName" deleted',
                    icon: Icons.delete_outline,
                    backgroundColor: Colors.red[600],
                  );
                },
                onRename: (String id) => print('Rename accessory $id'),
                onDuplicate: (String id) => print('Duplicate accessory $id'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSpeakersContent() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        if (_reorderableZones.isEmpty) {
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
          itemCount: _reorderableZones.length,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final Map<String, dynamic> item = _reorderableZones.removeAt(oldIndex);
              _reorderableZones.insert(newIndex, item);
            });
          },
          itemBuilder: (BuildContext context, int index) {
            final Map<String, dynamic> zone = _reorderableZones[index];
            return ReorderableDragStartListener(
              key: ValueKey<String>(zone['id'] as String),
              index: index,
              child: ExpandableZoneWidget(
                name: zone['name'] as String,
                assetImagePath: 'assets/speaker.png',
                speakerId: zone['id'] as String,
                bgColor: zone['color'] as Color,
                initiallyExpanded: false,
                subZones: _reorderableSubZones[zone['id']] ?? <Map<String, dynamic>>[],
                devices: _reorderableDevices,
                onZoneReorder: (String zoneId, int oldIndex, int newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final Map<String, dynamic> item = _reorderableZones.removeAt(oldIndex);
                    _reorderableZones.insert(newIndex, item);
                  });
                },
                onSubZoneReorder: (String zoneId, int oldIndex, int newIndex) {
                  setState(() {
                    final List<Map<String, dynamic>>? subZones = _reorderableSubZones[zoneId];
                    if (subZones != null) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final Map<String, dynamic> item = subZones.removeAt(oldIndex);
                      subZones.insert(newIndex, item);
                    }
                  });
                },
                onDeviceReorder: (String subZoneId, int oldIndex, int newIndex) {
                  setState(() {
                    final List<Map<String, dynamic>>? devices = _reorderableDevices[subZoneId];
                    if (devices != null) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final Map<String, dynamic> item = devices.removeAt(oldIndex);
                      devices.insert(newIndex, item);
                    }
                  });
                },
                onDelete: (String id) {
                  setState(() {
                    _reorderableZones.removeWhere((Map<String, dynamic> zone) => zone['id'] == id);
                    // Also remove associated subzones and devices
                    _reorderableSubZones.remove(id);
                    final List<String> subZoneIds = _reorderableSubZones[id]?.map((Map<String, dynamic> sz) => sz['id'] as String).toList() ?? <String>[];
                    for (final String subZoneId in subZoneIds) {
                      _reorderableDevices.remove(subZoneId);
                    }
                  });
                  FusionToast.show(
                    context,
                    message: 'Zone "${zone['name']}" deleted',
                    icon: Icons.delete_outline,
                    backgroundColor: Colors.red[600],
                  );
                },
                onRename: (String id) => print('Rename zone $id'),
                onDuplicate: (String id) => print('Duplicate zone $id'),
                onAddDevice: () => print('Add device to zone'),
              ),
            );
          },
        );
      },
    );
  }
}
