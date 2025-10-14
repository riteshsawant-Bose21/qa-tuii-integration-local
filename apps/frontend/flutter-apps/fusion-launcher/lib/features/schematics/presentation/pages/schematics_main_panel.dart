import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../widgets/common_devices_section_widget.dart';
import '../widgets/hardware_item_card.dart';
import '../widgets/common_reorderable_list_view.dart';

class SchematicsMainPanel extends StatefulWidget {
  const SchematicsMainPanel({super.key});

  @override
  State<SchematicsMainPanel> createState() => _SchematicsMainPanelState();
}

class _SchematicsMainPanelState extends State<SchematicsMainPanel> {
  final ValueNotifier<String?> _hoveredDeviceId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _selectedDeviceId = ValueNotifier<String?>(null);

  // Reorderable lists for each section
  List<Source> _reorderableSources = <Source>[];
  List<Map<String, dynamic>> _reorderableProcessors = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reorderableSpeakers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reorderableControllers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reorderableAccessories = <Map<String, dynamic>>[];

  static const double _speakersWidthRatio = 0.25; // 25% of available width
  static const double _normalColumnWidthRatio = 0.1875; // 18.75% each (4 columns = 75%)

  @override
  void initState() {
    super.initState();
    _initializeReorderableLists();
  }

  void _initializeReorderableLists() {
    // Initialize sources from the view model
    _reorderableSources = List<Source>.from(serviceLocator<ProjectViewModel>().sources);

    // Initialize processors
    _reorderableProcessors = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Fusion Mini 6', 'isActive': false, 'zones': null},
      <String, dynamic>{
        'name': 'PowerSmart PSM-8300 (2)',
        'isActive': true,
        'zones': <String>["Z1", "Z2", "Z3", "Z4", "GF"],
      },
      <String, dynamic>{
        'name': 'PowerSmart PSM-8300 (1)',
        'isActive': false,
        'zones': <String>["Z1", "Z2", "Z3", "Z4"],
      },
    ];

    // Initialize speakers
    _reorderableSpeakers = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'DM55E', 'assetPath': 'assets/images/speakers/DM_pendant.png'},
      <String, dynamic>{'name': 'DM85E', 'assetPath': 'assets/images/speakers/DM_pendant.png'},
      <String, dynamic>{'name': 'FreeSpace DS 16F', 'assetPath': 'assets/images/speakers/DM_pendant.png'},
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
  }

  @override
  void dispose() {
    _hoveredDeviceId.dispose();
    _selectedDeviceId.dispose();
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
                sectionContent: _buildSourcesContent(),
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

  /// Optimized Sources content using CommonReorderableListView
  Widget _buildSourcesContent() {
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

        return ValueListenableBuilder<String?>(
          valueListenable: _hoveredDeviceId,
          builder: (BuildContext context, String? hoveredId, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: _selectedDeviceId,
              builder: (BuildContext context, String? selectedId, _) {
                return CommonReorderableListView<Source>(
                  items: _reorderableSources,
                  emptyMessage: "No sources added yet",
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final Source item = _reorderableSources.removeAt(oldIndex);
                      _reorderableSources.insert(newIndex, item);
                      _selectedDeviceId.value = item.id;
                    });
                  },
                  keyExtractor: (Source source) => source.id,
                  itemBuilder: (BuildContext context, Source source, int index) {
                    return HardwareItemCard(
                      name: source.name,
                      assetImagePath: source.assetImagePath,
                      itemId: source.id,
                      location: "Eqp Loc.",
                      isHovered: hoveredId == source.id,
                      isSelected: selectedId == source.id,
                      onTap: () => _selectedDeviceId.value = source.id,
                      onHover: () => _hoveredDeviceId.value = source.id,
                      onExit: () => _hoveredDeviceId.value = null,
                      onDelete: (String id) {
                        setState(() {
                          _reorderableSources.removeWhere((Source s) => s.id == id);
                        });
                        serviceLocator<ProjectViewModel>().removeHardware(id);
                      },
                      onRename: (String id) => print('Rename source $id'),
                      onDuplicate: (String id) => print('Duplicate source $id'),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Optimized Processors content using CommonReorderableListView
  Widget _buildProcessorsContent() {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredDeviceId,
      builder: (BuildContext context, String? hoveredId, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: _selectedDeviceId,
          builder: (BuildContext context, String? selectedId, _) {
            return CommonReorderableListView<Map<String, dynamic>>(
              items: _reorderableProcessors,
              emptyMessage: "No processors added yet",
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final Map<String, dynamic> item = _reorderableProcessors.removeAt(oldIndex);
                  _reorderableProcessors.insert(newIndex, item);
                  _selectedDeviceId.value = 'processor_$newIndex';
                });
              },
              keyExtractor: (Map<String, dynamic> processor) => 'processor_${processor['name']}',
              itemBuilder: (BuildContext context, Map<String, dynamic> processor, int index) {
                final String processorId = 'processor_$index';
                return HardwareItemCard(
                  name: processor['name'] as String,
                  assetImagePath: 'assets/icons/lising_view_icon.png',
                  itemId: processorId,
                  location: "Eqp Loc.",
                  isHovered: hoveredId == processorId,
                  isSelected: selectedId == processorId,
                  onTap: () => _selectedDeviceId.value = processorId,
                  onHover: () => _hoveredDeviceId.value = processorId,
                  onExit: () => _hoveredDeviceId.value = null,
                  onDelete: (String id) {
                    setState(() {
                      _reorderableProcessors.removeAt(index);
                    });
                  },
                  onRename: (String id) => print('Rename processor $id'),
                  onDuplicate: (String id) => print('Duplicate processor $id'),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Optimized Controllers content using CommonReorderableListView
  Widget _buildControllersContent() {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredDeviceId,
      builder: (BuildContext context, String? hoveredId, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: _selectedDeviceId,
          builder: (BuildContext context, String? selectedId, _) {
            return CommonReorderableListView<Map<String, dynamic>>(
              items: _reorderableControllers,
              emptyMessage: "No controllers added yet",
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final Map<String, dynamic> item = _reorderableControllers.removeAt(oldIndex);
                  _reorderableControllers.insert(newIndex, item);
                  // Fix: Use the correct controller ID format instead of the name
                  _selectedDeviceId.value = 'controller_$newIndex';
                });
              },
              keyExtractor: (Map<String, dynamic> controller) => 'controller_${controller['name']}',
              itemBuilder: (BuildContext context, Map<String, dynamic> controller, int index) {
                final String controllerId = 'controller_$index';
                return HardwareItemCard(
                  name: controller['name'] as String,
                  assetImagePath: controller['assetPath'] as String,
                  itemId: controllerId,
                  location: "Eqp Loc.",
                  isHovered: hoveredId == controllerId,
                  isSelected: selectedId == controllerId,
                  onTap: () => _selectedDeviceId.value = controllerId,
                  onHover: () => _hoveredDeviceId.value = controllerId,
                  onExit: () => _hoveredDeviceId.value = null,
                  onDelete: (String id) {
                    setState(() {
                      _reorderableControllers.removeAt(index);
                    });
                  },
                  onRename: (String id) => print('Rename controller $id'),
                  onDuplicate: (String id) => print('Duplicate controller $id'),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Optimized Accessories content using CommonReorderableListView
  Widget _buildAccessoriesContent() {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredDeviceId,
      builder: (BuildContext context, String? hoveredId, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: _selectedDeviceId,
          builder: (BuildContext context, String? selectedId, _) {
            return CommonReorderableListView<Map<String, dynamic>>(
              items: _reorderableAccessories,
              emptyMessage: "No accessories added yet",
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final Map<String, dynamic> item = _reorderableAccessories.removeAt(oldIndex);
                  _reorderableAccessories.insert(newIndex, item);
                  _selectedDeviceId.value = 'accessory_$newIndex';
                });
              },
              keyExtractor: (Map<String, dynamic> accessory) => 'accessory_${accessory['name']}',
              itemBuilder: (BuildContext context, Map<String, dynamic> accessory, int index) {
                final String accessoryId = 'accessory_$index';
                return HardwareItemCard(
                  name: accessory['name'] as String,
                  assetImagePath: accessory['assetPath'] as String,
                  itemId: accessoryId,
                  location: "Eqp Loc.",
                  isHovered: hoveredId == accessoryId,
                  isSelected: selectedId == accessoryId,
                  onTap: () => _selectedDeviceId.value = accessoryId,
                  onHover: () => _hoveredDeviceId.value = accessoryId,
                  onExit: () => _hoveredDeviceId.value = null,
                  onDelete: (String id) {
                    setState(() {
                      _reorderableAccessories.removeAt(index);
                    });
                  },
                  onRename: (String id) => print('Rename accessory $id'),
                  onDuplicate: (String id) => print('Duplicate accessory $id'),
                );
              },
            );
          },
        );
      },
    );
  }

  // Keep the speakers content as is since it has different design
  Widget _buildSpeakersContent() {
    return CommonReorderableListView<Map<String, dynamic>>(
      items: _reorderableSpeakers,
      emptyMessage: "No speakers added yet",
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final Map<String, dynamic> item = _reorderableSpeakers.removeAt(oldIndex);
          _reorderableSpeakers.insert(newIndex, item);
        });
      },
      keyExtractor: (Map<String, dynamic> speaker) => 'speaker_${speaker['name']}',
      itemBuilder: (BuildContext context, Map<String, dynamic> speaker, int index) {
        return _buildSpeakerItem(
          name: speaker['name'] as String,
          assetImagePath: speaker['assetPath'] as String,
          speakerId: 'speaker_$index',
          onDelete: (String speakerId) {
            setState(() {
              _reorderableSpeakers.removeAt(index);
            });
          },
        );
      },
    );
  }

  Widget _buildSpeakerItem({
    required String name,
    required String assetImagePath,
    String? speakerId,
    dynamic Function(String)? onDelete,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredDeviceId,
      builder: (BuildContext context, String? hoveredId, Widget? child) {
        final bool isHovered = (hoveredId == speakerId) && speakerId != null;

        return MouseRegion(
          onHover: (_) {
            if (speakerId != null) {
              _hoveredDeviceId.value = speakerId;
            }
          },
          onExit: (_) {
            if (speakerId != null) {
              _hoveredDeviceId.value = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isHovered ? Colors.grey[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                FusionImage.asset(assetImagePath, width: 18, height: 18, fit: BoxFit.contain),
                const SizedBox(width: 6),
                Expanded(
                  child: FusionAppText(
                    text: name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ),
                if (isHovered && speakerId != null) ...<Widget>[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Rename'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'duplicate',
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.copy, size: 16),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (String value) {
                      switch (value) {
                        case 'rename':
                          print('Rename $speakerId');
                          break;
                        case 'duplicate':
                          print('Duplicate $speakerId');
                          break;
                        case 'delete':
                          if (onDelete != null) onDelete(speakerId);
                          break;
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
