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
  Map<String, double> _sectionHeights = <String, double>{};
  static const double _minSectionHeight = 150.0;

  /// Define section pairs for responsive resizing
  static const Map<String, String> _sectionPairs = <String, String>{
    "Sources": "End Points",
    "End Points": "Sources",
    "Processors & Amplifiers": "Other Devices",
    "Other Devices": "Processors & Amplifiers",
  };

  @override
  void dispose() {
    _hoveredSourceId.dispose();
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
            final List<Source> sources = serviceLocator<ProjectViewModel>().sources;

            if (sources.isEmpty) {
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

            return Column(
              children:
                  sources.map((Source source) {
                    return _buildSourceItem(
                      name: source.name,
                      assetImagePath: source.assetImagePath,
                      sourceId: source.id,
                      onDelete: (String sourceId) {
                        serviceLocator<ProjectViewModel>().removeHardware(sourceId);
                      },
                    );
                  }).toList(),
            );
          },
        );

      case "Processors & Amplifiers":
        return Column(
          children: <Widget>[
            _buildProcessorItem("Fusion Mini 6", false),
            const SizedBox(height: 4),
            _buildProcessorItem("PowerSmart PSM-8300 (2)", true, <String>[
              "Z1",
              "Z2",
              "Z3",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "Z4",
              "GF",
            ]),
            const SizedBox(height: 4),
            _buildProcessorItem("PowerSmart PSM-8300 (1)", false, <String>["Z1", "Z2", "Z3", "Z4", "GF"]),
          ],
        );

      case "End Points":
        return Column(
          children: <Widget>[
            _buildSourceItem(name: "BluePaL", assetImagePath: "assets/icons/lising_view_icon.png", sourceId: "endpoint_1"),
            _buildSourceItem(name: "XLRPaL (2)", assetImagePath: "assets/icons/lising_view_icon.png", sourceId: "endpoint_2"),
            _buildSourceItem(name: "XLRPaL (1)", assetImagePath: "assets/icons/lising_view_icon.png", sourceId: "endpoint_3"),
          ],
        );

      case "Other Devices":
        return Column(
          children: <Widget>[
            _buildSourceItem(name: "BluePaL", assetImagePath: "assets/icons/lising_view_icon.png", sourceId: "other_1"),
            _buildSourceItem(name: "XLRPaL (2)", assetImagePath: "assets/icons/lising_view_icon.png", sourceId: "other_2"),
          ],
        );

      default:
        return Container();
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
        final bool isHovered = (hoveredId == sourceId);

        return MouseRegion(
          onHover: (_) {
            _hoveredSourceId.value = sourceId;
          },
          onExit: (_) {
            _hoveredSourceId.value = null;
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
                if (isHovered && sourceId != null)
                  GestureDetector(
                    onTap: () {
                      onDelete!(sourceId);
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
            ),
          ),
        );
      },
    );
  }

  /// Build individual processor item with zones
  Widget _buildProcessorItem(String name, bool isActive, [List<String>? zones]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
