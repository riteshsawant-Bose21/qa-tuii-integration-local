import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../widgets/common_devices_section_widget.dart';

class SchematicsLeftPanel extends StatefulWidget {
  final double panelWidth;

  const SchematicsLeftPanel({super.key, required this.panelWidth});

  @override
  State<SchematicsLeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<SchematicsLeftPanel> {
  final ValueNotifier<String?> _hoveredSourceId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _hoveredProcessorId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _hoveredEndPointId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _hoveredOtherDeviceId = ValueNotifier<String?>(null);
  Map<String, double> _sectionHeights = <String, double>{};
  static const double _minSectionHeight = 150.0;

  // Add reorderable lists for each section
  List<Source> _reorderableSources = <Source>[];
  List<Map<String, dynamic>> _reorderableProcessors = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reorderableEndPoints = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reorderableOtherDevices = <Map<String, dynamic>>[];

  /// Define section pairs for responsive resizing
  static const Map<String, String> _sectionPairs = <String, String>{
    "Sources": "End Points",
    "End Points": "Sources",
    "Processors & Amplifiers": "Other Devices",
    "Other Devices": "Processors & Amplifiers",
  };

  @override
  void initState() {
    super.initState();
    _initializeReorderableLists();
  }

  void _initializeReorderableLists() {
    // Initialize sources from the view model
    _reorderableSources = List<Source>.from(serviceLocator<ProjectViewModel>().sources);

    // Initialize processors with original data structure
    _reorderableProcessors = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Fusion Mini 6', 'isActive': false, 'zones': null},
      <String, dynamic>{
        'name': 'PowerSmart PSM-8300 (2)',
        'isActive': true,
        'zones': <String>["Z1", "Z2", "Z3", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "GF"],
      },
      <String, dynamic>{
        'name': 'PowerSmart PSM-8300 (1)',
        'isActive': false,
        'zones': <String>["Z1", "Z2", "Z3", "Z4", "GF"],
      },
    ];

    // Initialize endpoints with original data
    _reorderableEndPoints = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'BluePaL', 'assetPath': 'assets/icons/lising_view_icon.png'},
      <String, dynamic>{'name': 'XLRPaL (2)', 'assetPath': 'assets/icons/lising_view_icon.png'},
      <String, dynamic>{'name': 'XLRPaL (1)', 'assetPath': 'assets/icons/lising_view_icon.png'},
    ];

    // Initialize other devices with original data
    _reorderableOtherDevices = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'BluePaL', 'assetPath': 'assets/icons/lising_view_icon.png'},
      <String, dynamic>{'name': 'XLRPaL (2)', 'assetPath': 'assets/icons/lising_view_icon.png'},
    ];
  }

  @override
  void dispose() {
    _hoveredSourceId.dispose();
    _hoveredProcessorId.dispose();
    _hoveredEndPointId.dispose();
    _hoveredOtherDeviceId.dispose();
    super.dispose();
  }

  void _updateSectionHeight(String sectionTitle, double newHeight) {
    final String? pairedSection = _sectionPairs[sectionTitle];
    if (pairedSection == null) {
      /// No paired section, just update current section
      setState(() {
        _sectionHeights[sectionTitle] = newHeight.clamp(_minSectionHeight, double.infinity);
      });
      return;
    }

    /// Get current heights
    final double currentHeight = _sectionHeights[sectionTitle] ?? _minSectionHeight;
    final double pairedCurrentHeight = _sectionHeights[pairedSection] ?? _minSectionHeight;
    final double totalColumnHeight = currentHeight + pairedCurrentHeight;

    /// Calculate new paired height
    final double newPairedHeight = totalColumnHeight - newHeight;

    /// Check constraints
    if (newHeight < _minSectionHeight || newPairedHeight < _minSectionHeight) {
      /// Don't allow resize if it violates minimum height constraints
      return;
    }

    setState(() {
      _sectionHeights[sectionTitle] = newHeight;
      _sectionHeights[pairedSection] = newPairedHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        final double spacing = 0.0;
        final double usableWidth = availableWidth - (spacing * 2);

        /// Calculate initial container height for 2x2 grid (2 rows)
        final int rows = 2;
        final double totalVerticalSpacing = spacing * (rows + 1);
        final double containerHeight = ((availableHeight - totalVerticalSpacing) / rows).clamp(_minSectionHeight, double.infinity);

        /// Initialize section heights if empty
        if (_sectionHeights.isEmpty) {
          _sectionHeights = <String, double>{
            "Sources": containerHeight,
            "Processors & Amplifiers": containerHeight,
            "End Points": containerHeight,
            "Other Devices": containerHeight,
          };
        }

        /// Force 2x2 layout (2 columns, 2 rows) by default
        double containerWidth;
        final double minContainerWidth = 180.0;
        int containersPerRow = 2;

        /// Only allow single column if space is extremely tight
        if (usableWidth < (minContainerWidth * 2 + spacing)) {
          containersPerRow = 1;
        }

        /// Calculate container dimensions
        if (containersPerRow == 1) {
          containerWidth = usableWidth.clamp(minContainerWidth, double.infinity);
        } else {
          containerWidth = (usableWidth - spacing) / 2;
          containerWidth = containerWidth.clamp(minContainerWidth, double.infinity);
        }

        /// Handle single column layout with scrolling
        if (containersPerRow == 1) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.all(spacing),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: <Widget>[
                /// Single column layout with individual sections
                _buildSection("Sources", containerWidth, enableResize: true),
                _buildSection("Processors & Amplifiers", containerWidth, enableResize: true),
                _buildSection("End Points", containerWidth, enableResize: true),
                _buildSection("Other Devices", containerWidth, enableResize: true),
              ],
            ),
          );
        }

        /// 2x2 layout without scrolling
        return Padding(
          padding: EdgeInsets.all(spacing),
          child: Wrap(
            spacing: spacing,
            runSpacing: 0.0,
            children: <Widget>[
              /// Left Column (Sources + End Points as a single unit)
              SizedBox(
                width: containerWidth,
                child: Column(
                  children: <Widget>[
                    _buildSection("Sources", containerWidth, enableResize: true),
                    SizedBox(height: spacing),
                    _buildSection("End Points", containerWidth, enableResize: false),
                  ],
                ),
              ),

              /// Right Column (Processors + Other Devices as a single unit)
              SizedBox(
                width: containerWidth,
                child: Column(
                  children: <Widget>[
                    _buildSection("Processors & Amplifiers", containerWidth, enableResize: true),
                    SizedBox(height: spacing),
                    _buildSection("Other Devices", containerWidth, enableResize: false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build individual section with optional resizing
  Widget _buildSection(String title, double containerWidth, {bool enableResize = true}) {
    return CommonDevicesSectionWidget(
      title: title,
      width: containerWidth,
      height: _sectionHeights[title]!,
      sectionContent: _buildSectionContent(sectionTitle: title),
      addButtonWidget: const SizedBox(),
      onHeightChanged: enableResize ? (double height) => _updateSectionHeight(title, height) : null,
      minHeight: _minSectionHeight,
      enableResize: enableResize,
    );
  }

  /// Build content for each section based on title
  Widget _buildSectionContent({required String sectionTitle}) {
    switch (sectionTitle) {
      case "Sources":
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            // Update reorderable list when sources change
            final List<Source> currentSources = serviceLocator<ProjectViewModel>().sources;

            // Only update if the list has actually changed
            if (currentSources.length != _reorderableSources.length ||
                !currentSources.every((Source source) => _reorderableSources.any((Source rs) => rs.id == source.id))) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _reorderableSources = List<Source>.from(currentSources);
                });
              });
            }

            if (_reorderableSources.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: FusionAppText(
                    text: "No sources added yet",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }

            return ReorderableListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final Source item = _reorderableSources.removeAt(oldIndex);
                  _reorderableSources.insert(newIndex, item);
                });
              },
              children:
                  _reorderableSources.asMap().entries.map((MapEntry<int, Source> entry) {
                    final int index = entry.key;
                    final Source source = entry.value;
                    return ReorderableDragStartListener(
                      key: ValueKey<String>(source.id),
                      index: index,
                      child: _buildSourceItem(
                        name: source.name,
                        assetImagePath: source.assetImagePath,
                        sourceId: source.id,
                        onDelete: (String sourceId) {
                          setState(() {
                            _reorderableSources.removeWhere((Source s) => s.id == sourceId);
                          });
                          serviceLocator<ProjectViewModel>().removeHardware(sourceId);
                        },
                      ),
                    );
                  }).toList(),
            );
          },
        );

      case "Processors & Amplifiers":
        return ReorderableListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final Map<String, dynamic> item = _reorderableProcessors.removeAt(oldIndex);
              _reorderableProcessors.insert(newIndex, item);
            });
          },
          children:
              _reorderableProcessors.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                final int index = entry.key;
                final Map<String, dynamic> processor = entry.value;
                return ReorderableDragStartListener(
                  key: ValueKey<String>('processor_${processor['name']}'),
                  index: index,
                  child: _buildProcessorItem(
                    processor['name'] as String,
                    processor['isActive'] as bool,
                    processor['zones'] as List<String>?,
                    'processor_$index',
                    (String processorId) {
                      setState(() {
                        _reorderableProcessors.removeWhere((Map<String, dynamic> p) => 'processor_${_reorderableProcessors.indexOf(p)}' == processorId);
                      });
                    },
                  ),
                );
              }).toList(),
        );

      case "End Points":
        return ReorderableListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final Map<String, dynamic> item = _reorderableEndPoints.removeAt(oldIndex);
              _reorderableEndPoints.insert(newIndex, item);
            });
          },
          children:
              _reorderableEndPoints.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                final int index = entry.key;
                final Map<String, dynamic> endPoint = entry.value;
                return ReorderableDragStartListener(
                  key: ValueKey<String>('endpoint_${endPoint['name']}'),
                  index: index,
                  child: _buildEndPointItem(
                    name: endPoint['name'] as String,
                    assetImagePath: endPoint['assetPath'] as String,
                    endPointId: 'endpoint_$index',
                    onDelete: (String endPointId) {
                      setState(() {
                        _reorderableEndPoints.removeWhere((Map<String, dynamic> e) => 'endpoint_${_reorderableEndPoints.indexOf(e)}' == endPointId);
                      });
                    },
                  ),
                );
              }).toList(),
        );

      case "Other Devices":
        return ReorderableListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final Map<String, dynamic> item = _reorderableOtherDevices.removeAt(oldIndex);
              _reorderableOtherDevices.insert(newIndex, item);
            });
          },
          children:
              _reorderableOtherDevices.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                final int index = entry.key;
                final Map<String, dynamic> otherDevice = entry.value;
                return ReorderableDragStartListener(
                  key: ValueKey<String>('other_${otherDevice['name']}'),
                  index: index,
                  child: _buildOtherDeviceItem(
                    name: otherDevice['name'] as String,
                    assetImagePath: otherDevice['assetPath'] as String,
                    otherDeviceId: 'other_$index',
                    onDelete: (String otherDeviceId) {
                      setState(() {
                        _reorderableOtherDevices.removeWhere((Map<String, dynamic> o) => 'other_${_reorderableOtherDevices.indexOf(o)}' == otherDeviceId);
                      });
                    },
                  ),
                );
              }).toList(),
        );

      default:
        return Container();
    }
  }

  List<String>? _getZonesForProcessor(String processor) {
    switch (processor) {
      case "PowerSmart PSM-8300 (2)":
        return <String>["Z1", "Z2", "Z3", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "Z4", "GF"];
      case "PowerSmart PSM-8300 (1)":
        return <String>["Z1", "Z2", "Z3", "Z4", "GF"];
      default:
        return null;
    }
  }

  /// Build individual source item with hover and delete functionality
  Widget _buildSourceItem({
    required String name,
    required String assetImagePath,
    String? sourceId,
    dynamic Function(String)? onDelete,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredSourceId,
      builder: (BuildContext context, String? hoveredId, Widget? child) {
        final bool isHovered = (hoveredId == sourceId) && sourceId != null;

        return MouseRegion(
          onHover: (_) {
            if (sourceId != null) {
              _hoveredSourceId.value = sourceId;
            }
          },
          onExit: (_) {
            if (sourceId != null) {
              _hoveredSourceId.value = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isHovered ? Colors.grey[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              // Only show border for items that have sourceId (Sources section)
              border: isHovered ? Border.all(color: Colors.grey[300]!, width: 1) : Border.all(color: Colors.transparent, width: 1),
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
                if (isHovered && sourceId != null && onDelete != null) ...<Widget>[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      onDelete(sourceId);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build end point item with hover and delete functionality
  Widget _buildEndPointItem({
    required String name,
    required String assetImagePath,
    String? endPointId,
    dynamic Function(String)? onDelete,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredEndPointId,
      builder: (BuildContext context, String? hoveredId, Widget? child) {
        final bool isHovered = (hoveredId == endPointId) && endPointId != null;

        return MouseRegion(
          onHover: (_) {
            if (endPointId != null) {
              _hoveredEndPointId.value = endPointId;
            }
          },
          onExit: (_) {
            if (endPointId != null) {
              _hoveredEndPointId.value = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isHovered ? Colors.grey[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isHovered ? Border.all(color: Colors.grey[300]!, width: 1) : Border.all(color: Colors.transparent, width: 1),
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
                if (isHovered && endPointId != null && onDelete != null) ...<Widget>[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      onDelete(endPointId);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build other device item with hover and delete functionality
  Widget _buildOtherDeviceItem({
    required String name,
    required String assetImagePath,
    String? otherDeviceId,
    dynamic Function(String)? onDelete,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredOtherDeviceId,
      builder: (BuildContext context, String? hoveredId, Widget? child) {
        final bool isHovered = (hoveredId == otherDeviceId) && otherDeviceId != null;

        return MouseRegion(
          onHover: (_) {
            if (otherDeviceId != null) {
              _hoveredOtherDeviceId.value = otherDeviceId;
            }
          },
          onExit: (_) {
            if (otherDeviceId != null) {
              _hoveredOtherDeviceId.value = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isHovered ? Colors.grey[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isHovered ? Border.all(color: Colors.grey[300]!, width: 1) : Border.all(color: Colors.transparent, width: 1),
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
                if (isHovered && otherDeviceId != null && onDelete != null) ...<Widget>[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      onDelete(otherDeviceId);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build individual processor item with zones and delete functionality
  Widget _buildProcessorItem(String name, bool isActive, [List<String>? zones, String? processorId, dynamic Function(String)? onDelete]) {
    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredProcessorId,
      builder: (BuildContext context, String? hoveredId, Widget? child) {
        final bool isHovered = (hoveredId == processorId) && processorId != null;

        return MouseRegion(
          onHover: (_) {
            if (processorId != null) {
              _hoveredProcessorId.value = processorId;
            }
          },
          onExit: (_) {
            if (processorId != null) {
              _hoveredProcessorId.value = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHovered ? Colors.grey[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isHovered ? Border.all(color: Colors.grey[300]!, width: 1) : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 16,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FusionAppText(
                        text: name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                    if (isHovered && processorId != null && onDelete != null) ...<Widget>[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          onDelete(processorId);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.red[400],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (zones != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children:
                        zones
                            .map(
                              (String zone) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getZoneColor(zone),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  zone,
                                  style: const TextStyle(fontSize: 8, color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// color coding for zones
  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'Z1':
        return Colors.teal;
      case 'Z2':
        return Colors.purple;
      case 'Z3':
        return Colors.amber;
      case 'Z4':
        return Colors.red;
      case 'GF':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
