import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/models/project_entities/location_model.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';

import '../../../../core/models/products_data.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../product_query/presentation/pages/product_query.dart';

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
  bool _amplifiersExpanded = false;
  bool _speakersExpanded = false;
  bool _controllersExpanded = false;
  bool _racksExpanded = false;
  bool _endPointsExpanded = false;
  bool _otherDevicesExpanded = false;

  /// Returns tooltip text based on the section title
  String getSectionToolTip() {
    switch (widget.sectionTitle) {
      case "Sources & Endpoints":
        return "Add Source or Endpoint";
      case "Processors & Amplifiers":
        return "Add Processor or Amplifier";
      case "Speakers":
        return "Add Speaker";
      case "Controllers":
        return "Add Controller";
      case "Accessories":
        return "Add Accessory";
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
      onSelected: (DeviceComponent selectedBlock) {
        if (selectedBlock is SourceData) {
          final Source source = Source(
            name: selectedBlock.name,
            pos: null,
            type: selectedBlock.type,
            assetImagePath: selectedBlock.assetPath,
            locationEntity: LocationModel(),
            sku: selectedBlock.id,
            price: selectedBlock.price,
          );
          serviceLocator<ProjectViewModel>().addHardware(hardware: source);
        }
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
      case "Sources & Endpoints":
        return <Widget>[
          _buildExpandableSection<SourceData>(
            title: 'MICROPHONES',
            isExpanded: _microphoneExpanded,
            onTap: () => setMenuState(() => _microphoneExpanded = !_microphoneExpanded),
            items: SourceData.microphoneItems,
          ),
          _buildExpandableSection<SourceData>(
            title: 'MEDIA SOURCES',
            isExpanded: _mediaSourceExpanded,
            onTap: () => setMenuState(() => _mediaSourceExpanded = !_mediaSourceExpanded),
            items: SourceData.mediaSourceItems,
          ),
          _buildExpandableSection<ProductQueryModel>(
            title: 'END POINTS',
            isExpanded: _endPointsExpanded,
            onTap: () => setMenuState(() => _endPointsExpanded = !_endPointsExpanded),
            items: ProductAPI.getEndpoints(),
          ),
        ];

      case "Processors & Amplifiers":
        return <Widget>[
          _buildExpandableSection<ProductQueryModel>(
            title: 'PROCESSORS',
            isExpanded: _processorsExpanded,
            onTap: () => setMenuState(() => _processorsExpanded = !_processorsExpanded),
            items: ProductAPI.getControllers(),
          ),
          _buildExpandableSection<ProductQueryModel>(
            title: 'AMPLIFIERS',
            isExpanded: _amplifiersExpanded,
            onTap: () => setMenuState(() => _amplifiersExpanded = !_amplifiersExpanded),
            items: ProductAPI.getAmplifierProducts(),
          ),
        ];

      case "Speakers":
        return <Widget>[
          _buildExpandableSection<ProductQueryModel>(
            title: 'SPEAKERS',
            isExpanded: _speakersExpanded,
            onTap: () => setMenuState(() => _speakersExpanded = !_speakersExpanded),
            items: ProductAPI.getSpeakerProducts(),
          ),
        ];

      case "Controllers":
        return <Widget>[
          _buildExpandableSection<ProductQueryModel>(
            title: 'CONTROLLERS',
            isExpanded: _controllersExpanded,
            onTap: () => setMenuState(() => _controllersExpanded = !_controllersExpanded),
            items: ProductAPI.getControllers(),
          ),
        ];

      case "Accessories":
        return <Widget>[
          _buildExpandableSection<String>(
            title: 'RACKS',
            isExpanded: _racksExpanded,
            onTap: () => setMenuState(() => _racksExpanded = !_racksExpanded),
            items: <String>['4U', '8U', '12U', '24U'],
          ),
          _buildExpandableSection<SourceData>(
            title: 'OTHER DEVICES',
            isExpanded: _otherDevicesExpanded,
            onTap: () => setMenuState(() => _otherDevicesExpanded = !_otherDevicesExpanded),
            items: SourceData.microphoneItems,
          ),
        ];

      default:
        return <Widget>[];
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
                  serviceLocator<ProjectViewModel>().addHardware(hardware: source);
                } else if (item is FusionDsp) {
                  // final FusionDevice fusionDevice = FusionDevice(
                  //   name: item.name,
                  //   price: item.price,
                  //   location: 'EqpLoc.',
                  //   status: FusionDeviceSetupStatus.notStarted,
                  // );
                  // serviceLocator<ProjectViewModel>().addHardware(fusionDevice);
                }
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
                      )
                    else if (item is ProductQueryModel)
                      FusionImage.asset(
                        item.image.isNotEmpty ? item.image : _getDefaultImageForProductType(item.type),
                        height: 14,
                        width: 14,
                        fit: BoxFit.contain,
                      )
                    else
                      Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FusionAppText(
                        text: _getDisplayName(item),
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

  /// Get display name for different item types
  String _getDisplayName(dynamic item) {
    if (item is SourceData) {
      return item.name;
    } else if (item is ProductQueryModel) {
      return item.name;
    } else if (item is String) {
      return item;
    }
    return item.toString();
  }

  /// Get default image for ProductType
  String _getDefaultImageForProductType(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return "assets/images/speakers/DM_pendant.png";
      case ProductType.amplifier:
        return "assets/images/amps/default_amp.png";
      case ProductType.dsps:
      case ProductType.endpoints:
        return "assets/images/devices/default_device.png";
      case ProductType.sources:
        return "assets/images/products/mic1.png";
      case ProductType.controllers:
        return "assets/images/products/bose_dsp.png";
      case ProductType.racks:
        return "assets/images/products/rack.png";
    }
  }
}
