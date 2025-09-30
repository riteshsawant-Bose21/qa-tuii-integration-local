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

  @override
  void dispose() {
    _hoveredSourceId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        final double spacing = 0.0;
        final double usableWidth = availableWidth - (spacing * 2);

        /// Force 2x2 layout (2 columns, 2 rows) by default
        double containerWidth;
        final double minContainerWidth = 180.0;
        int containersPerRow = 2;

        /// Always start with 2 columns

        /// Only allow single column if space is extremely tight
        if (usableWidth < (minContainerWidth * 2 + spacing)) {
          containersPerRow = 1;
        }

        /// Calculate container width based on columns
        if (containersPerRow == 1) {
          containerWidth = usableWidth.clamp(minContainerWidth, double.infinity);
        } else {
          /// For 2 columns, distribute width evenly
          containerWidth = (usableWidth - spacing) / 2;
          containerWidth = containerWidth.clamp(minContainerWidth, double.infinity);
        }

        /// Calculate container height for 2x2 grid (2 rows)
        final int rows = 2; // Force 2 rows for 2x2 layout
        final double totalVerticalSpacing = spacing * (rows + 1); // Top, bottom, and between rows
        final double containerHeight = ((availableHeight - totalVerticalSpacing) / rows).clamp(250.0, double.infinity);

        final List<String> sections = <String>["Sources", "Processors & Amplifiers", "End Points", "Other Devices"];

        return SingleChildScrollView(
          padding: EdgeInsets.all(spacing),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: <Widget>[
              /// Sources Section
              CommonDevicesSectionWidget(
                title: "Sources",
                width: containerWidth,
                height: containerHeight,
                sectionContent: _buildSectionContent(sectionTitle: "Sources"),
                addButtonWidget: const SizedBox(), // Empty widget since we handle it in CommonDevicesSectionWidget
              ),

              /// Processors & Amplifiers Section
              CommonDevicesSectionWidget(
                title: "Processors & Amplifiers",
                width: containerWidth,
                height: containerHeight,
                sectionContent: _buildSectionContent(sectionTitle: "Processors & Amplifiers"),
                addButtonWidget: const SizedBox(), // Empty widget since we handle it in CommonDevicesSectionWidget
              ),

              /// End Points Section
              CommonDevicesSectionWidget(
                title: "End Points",
                width: containerWidth,
                height: containerHeight,
                sectionContent: _buildSectionContent(sectionTitle: "End Points"),
                addButtonWidget: const SizedBox(), // Empty widget since we handle it in CommonDevicesSectionWidget
              ),

              /// Other Devices Section
              CommonDevicesSectionWidget(
                title: "Other Devices",
                width: containerWidth,
                height: containerHeight,
                sectionContent: _buildSectionContent(sectionTitle: "Other Devices"),
                addButtonWidget: const SizedBox(), // Empty widget since we handle it in CommonDevicesSectionWidget
              ),
            ],
          ),
        );
      },
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
          // onEnter: (_) {
          //   _hoveredSourceId.value = sourceId;
          // },
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
                // add FusionImage
                FusionImage.asset(assetImagePath, width: 18, height: 18, fit: BoxFit.contain),
                const SizedBox(width: 6),
                Expanded(
                  child: FusionAppText(
                    text: name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ),
                // Show delete icon on hover
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

  Widget _buildProcessorItem(String name, bool isActive, [List<String>? zones]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // decoration: BoxDecoration(
      //   color: isActive ? Colors.grey[200] : Colors.white,
      //   border: Border.all(color: Colors.grey[300]!),
      //   borderRadius: BorderRadius.circular(4),
      // ),
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
