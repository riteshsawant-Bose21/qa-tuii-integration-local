import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/models/project_entities/location_model.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';

import '../../../../core/models/products_data.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class ExpandablePopupMenuWidget extends StatefulWidget {
  final String sectionTitle;

  const ExpandablePopupMenuWidget({super.key, required this.sectionTitle});

  @override
  State<ExpandablePopupMenuWidget> createState() => _ExpandablePopupMenuWidgetState();
}

class _ExpandablePopupMenuWidgetState extends State<ExpandablePopupMenuWidget> {
  bool _microphoneExpanded = false;
  bool _mediaSourceExpanded = false;
  bool _processorsExpanded = false;
  bool _racksExpanded = false;
  bool _endPointsExpanded = false;
  bool _otherDevicesExpanded = false;

  /// Returns tooltip text based on the section title
  String getSectionToolTip() {
    switch (widget.sectionTitle) {
      case "Sources":
        return "Add Source";
      case "Processors & Amplifiers":
        return "Add Processor or Amplifier";
      case "End Points":
        return "Add End Point";
      case "Other Devices":
        return "Add Other Device";
      default:
        return "Add Device";
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SourceData>(
      tooltip: getSectionToolTip(),
      constraints: const BoxConstraints(
        maxHeight: 500,
        maxWidth: 250,
      ),
      onSelected: (SourceData selectedBlock) {
        final Source source = Source(
          name: selectedBlock.name,
          pos: null,
          type: selectedBlock.type,
          assetImagePath: selectedBlock.assetPath,
          locationEntity: LocationModel(),
          sku: selectedBlock.id,
          price: selectedBlock.price,
        );
        serviceLocator<ProjectViewModel>().addHardware(source);
      },
      color: Colors.white,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<SourceData>>[
          PopupMenuItem<SourceData>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              width: 250,
              constraints: const BoxConstraints(
                maxHeight: 480,
                maxWidth: 250,
              ),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setMenuState) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: _buildSectionsForTitle(setMenuState),
                    ),
                  );
                },
              ),
            ),
          ),
        ];
      },
      child: IconButton(
        icon: Icon(Icons.add, size: 20, color: Theme.of(context).colorScheme.fusionTextViewColor),
        onPressed: null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  /// Builds sections based on the provided section title
  List<Widget> _buildSectionsForTitle(StateSetter setMenuState) {
    switch (widget.sectionTitle) {
      case "Sources":
        return <Widget>[
          /// Microphones Section
          _buildExpandableSection<SourceData>(
            title: 'MICROPHONES',
            isExpanded: _microphoneExpanded,
            onTap: () => setMenuState(() => _microphoneExpanded = !_microphoneExpanded),
            items: SourceData.microphoneItems,
          ),

          /// Media Sources Section
          _buildExpandableSection<SourceData>(
            title: 'MEDIA SOURCES',
            isExpanded: _mediaSourceExpanded,
            onTap: () => setMenuState(() => _mediaSourceExpanded = !_mediaSourceExpanded),
            items: SourceData.mediaSourceItems,
          ),
        ];

      case "Processors & Amplifiers":
        return <Widget>[
          /// Processors & Amplifiers Section
          _buildExpandableSection<SourceData>(
            title: 'PROCESSORS & AMPLIFIERS',
            isExpanded: _processorsExpanded,
            onTap: () => setMenuState(() => _processorsExpanded = !_processorsExpanded),
            items: SourceData.microphoneItems, // Replace with actual processor items when available
          ),
        ];

      case "End Points":
        return <Widget>[
          /// End Points Section
          _buildExpandableSection<SourceData>(
            title: 'END POINTS',
            isExpanded: _endPointsExpanded,
            onTap: () => setMenuState(() => _endPointsExpanded = !_endPointsExpanded),
            items: SourceData.microphoneItems, // Replace with actual endpoint items when available
          ),
        ];

      case "Other Devices":
        return <Widget>[
          /// Racks Section
          _buildExpandableSection<String>(
            title: 'RACKS',
            isExpanded: _racksExpanded,
            onTap: () => setMenuState(() => _racksExpanded = !_racksExpanded),
            items: <String>[
              '4U',
              '8U',
              '12U',
              '24U',
            ], // Replace with actual rack items when available
          ),

          /// Other Devices Section
          _buildExpandableSection<SourceData>(
            title: 'OTHER DEVICES',
            isExpanded: _otherDevicesExpanded,
            onTap: () => setMenuState(() => _otherDevicesExpanded = !_otherDevicesExpanded),
            items: SourceData.microphoneItems, // Replace with actual other device items when available
          ),
        ];

      default:
        return <Widget>[
          /// Show all sections if no specific match
          _buildExpandableSection<SourceData>(
            title: 'MICROPHONES',
            isExpanded: _microphoneExpanded,
            onTap: () => setMenuState(() => _microphoneExpanded = !_microphoneExpanded),
            items: SourceData.microphoneItems,
          ),

          /// Media Sources Section
          _buildExpandableSection<SourceData>(
            title: 'MEDIA SOURCES',
            isExpanded: _mediaSourceExpanded,
            onTap: () => setMenuState(() => _mediaSourceExpanded = !_mediaSourceExpanded),
            items: SourceData.mediaSourceItems,
          ),
        ];
    }
  }

  /// Builds an expandable section with a header and items
  Widget _buildExpandableSection<T>({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<T> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Section Header
        InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(
                  isExpanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                  size: 22,
                  color: Theme.of(context).colorScheme.fusionTextViewColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FusionAppText(
                    text: title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Section Items (conditionally shown)
        if (isExpanded)
          ...items.map(
            (T item) => InkWell(
              onTap: () {
                Navigator.of(context).pop();
                if (item is SourceData) {
                  final Source source = Source(
                    name: item.name,
                    pos: null,
                    type: item.type,
                    assetImagePath: item.assetPath,
                    locationEntity: LocationModel(),
                    sku: item.id,
                    price: item.price,
                  );
                  serviceLocator<ProjectViewModel>().addHardware(source);
                }
                // Add more type checks and logic for other models as needed
              },
              child: Container(
                height: 30,
                width: 218,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).colorScheme.grey, width: 1),
                ),
                child: Row(
                  children: <Widget>[
                    if (item is SourceData)
                      Image.asset(
                        item.assetPath,
                        height: 14,
                        width: 14,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FusionAppText(
                        text: item is SourceData ? item.name : item.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
