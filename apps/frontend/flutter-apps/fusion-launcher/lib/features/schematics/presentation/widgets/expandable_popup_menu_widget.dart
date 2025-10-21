import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/models/products_data.dart';
import '../../../product_query/presentation/pages/product_query.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'listening_area_dropdown_widget.dart';

class ExpandablePopupMenuWidget extends StatefulWidget {
  final String sectionTitle;
  final void Function(dynamic item, String areaId, String floorId)? onTapAddDevice;
  final List<ListeningArea> listeningAreas;
  final List<Zone> zones;

  const ExpandablePopupMenuWidget({
    super.key,
    required this.sectionTitle,
    this.onTapAddDevice,
    this.listeningAreas = const <ListeningArea>[],
    this.zones = const <Zone>[],
  });

  @override
  State<ExpandablePopupMenuWidget> createState() => _ExpandablePopupMenuWidgetState();
}

class _ExpandablePopupMenuWidgetState extends State<ExpandablePopupMenuWidget> {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  /// Single variable to track which section is currently expanded
  String? _expandedSection;

  /// Local state for popup menu selections
  dynamic _selectedPopupDevice;
  List<String> _selectedListeningAreaIds = <String>[];

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

  void _addDeviceToSelectedAreas() {
    final FloorModel? floorData = projectViewModel.getFloorForListeningArea(areaId: _selectedListeningAreaIds.first);

    print('Add device called - Device: $_selectedPopupDevice, Areas: $_selectedListeningAreaIds'); // Debug print
    if (_selectedPopupDevice != null && _selectedListeningAreaIds.isNotEmpty) {
      widget.onTapAddDevice?.call(_selectedPopupDevice, _selectedListeningAreaIds.first, floorData?.id ?? "");
      setState(() {
        _selectedPopupDevice = null;
        _selectedListeningAreaIds.clear();
      });
      Navigator.of(context).pop();
    }
  }

  /// Toggle expansion state for a section
  void _toggleSection(String sectionKey, StateSetter setMenuState) {
    _expandedSection = _expandedSection == sectionKey ? null : sectionKey;
    setMenuState(() {});
  }

  /// Check if a section is expanded
  bool _isSectionExpanded(String sectionKey) {
    return _expandedSection == sectionKey;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<dynamic>(
      onCanceled: () {
        /// Clear selections when menu is closed without adding
        setState(() {
          _selectedPopupDevice = null;
          _selectedListeningAreaIds.clear();
          _expandedSection = null;
        });
      },
      tooltip: getSectionToolTip(),
      constraints: const BoxConstraints(
        maxHeight: 550,
        maxWidth: 300,
      ),
      color: Colors.white,
      itemBuilder: (BuildContext context) {
        return <PopupMenuItem<dynamic>>[
          PopupMenuItem<dynamic>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              width: 300,
              constraints: const BoxConstraints(
                maxHeight: 520,
                maxWidth: 300,
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

  /// Build add device expandable sections based on the section title
  List<Widget> _buildSectionsForTitle(StateSetter setMenuState) {
    switch (widget.sectionTitle) {
      case "Sources & Endpoints":
        return <Widget>[
          _buildExpandableSection<SourceData>(
            title: 'MICROPHONES',
            sectionKey: 'MICROPHONES',
            items: SourceData.microphoneItems,
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<SourceData>(
            title: 'MEDIA SOURCES',
            sectionKey: 'MEDIA_SOURCES',
            items: SourceData.mediaSourceItems,
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<ProductQueryModel>(
            title: 'END POINTS',
            sectionKey: 'END_POINTS',
            items: ProductAPI.getEndpoints(),
            setMenuState: setMenuState,
          ),
        ];

      case "Processors & Amplifiers":
        return <Widget>[
          _buildExpandableSection<ProductQueryModel>(
            title: 'PROCESSORS',
            sectionKey: 'PROCESSORS',
            items: ProductAPI.getControllers(),
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<ProductQueryModel>(
            title: 'AMPLIFIERS',
            sectionKey: 'AMPLIFIERS',
            items: ProductAPI.getAmplifierProducts(),
            setMenuState: setMenuState,
          ),
        ];

      case "Speakers":
        return <Widget>[
          _buildCreateZoneSection<ProductQueryModel>(
            title: 'SPEAKERS',
            sectionKey: 'SPEAKERS',
            items: ProductAPI.getSpeakerProducts(),
            setMenuState: setMenuState,
          ),
        ];

      case "Controllers":
        return <Widget>[
          _buildExpandableSection<ProductQueryModel>(
            title: 'CONTROLLERS',
            sectionKey: 'CONTROLLERS',
            items: ProductAPI.getControllers(),
            setMenuState: setMenuState,
          ),
        ];

      case "Accessories":
        return <Widget>[
          _buildExpandableSection<String>(
            title: 'RACKS',
            sectionKey: 'RACKS',
            items: <String>['4U', '8U', '12U', '24U'],
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<SourceData>(
            title: 'OTHER DEVICES',
            sectionKey: 'OTHER_DEVICES',
            items: SourceData.microphoneItems,
            setMenuState: setMenuState,
          ),
        ];

      default:
        return <Widget>[];
    }
  }

  /// Helper method to check if a device is selected
  bool _isDeviceSelected(dynamic selectedDevice, dynamic item) {
    if (selectedDevice == null || item == null) return false;

    /// For SourceData, use ID comparison
    if (selectedDevice is SourceData && item is SourceData) {
      return selectedDevice.id == item.id;
    }

    /// For ProductQueryModel, compare by NAME instead of ID
    if (selectedDevice is ProductQueryModel && item is ProductQueryModel) {
      return selectedDevice.name == item.name;
    }

    /// For String items (like racks)
    if (selectedDevice is String && item is String) {
      return selectedDevice == item;
    }

    /// If different types, compare by name if available
    final String? selectedName = _getDeviceName(selectedDevice);
    final String? itemName = _getDeviceName(item);

    return selectedName != null && itemName != null && selectedName == itemName;
  }

  /// Helper method to get device name
  String? _getDeviceName(dynamic item) {
    if (item is SourceData) {
      return item.name;
    } else if (item is ProductQueryModel) {
      return item.name;
    } else if (item is String) {
      return item;
    }
    return item?.toString();
  }

  /// Builds an expandable section with a header and items
  Widget _buildExpandableSection<T>({
    required String title,
    required String sectionKey,
    required List<T> items,
    required StateSetter setMenuState,
  }) {
    final bool isExpanded = _isSectionExpanded(sectionKey);
    final bool canAddDevice = _selectedPopupDevice != null && _selectedListeningAreaIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Section Header
        InkWell(
          onTap: () => _toggleSection(sectionKey, setMenuState),
          child: Container(
            height: 40,
            width: 300,
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
        if (isExpanded) ...<Widget>[
          ...items.map(
            (T item) => InkWell(
              onTap: () {
                setState(() {
                  _selectedPopupDevice = item;
                });
                setMenuState(() {});
              },
              child: Container(
                height: 30,
                width: 268,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isDeviceSelected(_selectedPopupDevice, item) ? Colors.blue : Theme.of(context).colorScheme.grey,
                    width: _isDeviceSelected(_selectedPopupDevice, item) ? 2 : 1,
                  ),
                  color: _isDeviceSelected(_selectedPopupDevice, item) ? Colors.blue[100] : null,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _isDeviceSelected(_selectedPopupDevice, item) ? Colors.blue[800] : null,
                          fontWeight: _isDeviceSelected(_selectedPopupDevice, item) ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                    if (_isDeviceSelected(_selectedPopupDevice, item))
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                  ],
                ),
              ),
            ),
          ),

          /// Listening Area Selection Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FusionAppText(
                  text: "Select Listening Area",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ListeningAreaDropdownWidget(
                    listeningAreas: widget.listeningAreas,
                    zones: widget.zones,
                    selectedListeningAreaIds: _selectedListeningAreaIds,
                    onSelectionChanged: (List<String> selectedIds, String floorId) {
                      setState(() {
                        _selectedListeningAreaIds = selectedIds;
                      });
                      setMenuState(() {}); // Update popup menu UI
                      print('Listening areas selected: $selectedIds'); // Debug print
                    },
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: FusionButton(
                label: "Add Device",
                isActive: canAddDevice,
                onTap: () {
                  print('Add device button pressed'); // Debug print
                  _addDeviceToSelectedAreas();
                },
              ),
            ),
          ),

          const SizedBox(height: 4),
        ],
      ],
    );
  }

  /// Builds a create zone section for speakers
  Widget _buildCreateZoneSection<T>({
    required String title,
    required String sectionKey,
    required List<T> items,
    required StateSetter setMenuState,
  }) {
    final bool isExpanded = _isSectionExpanded(sectionKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Section Header
        InkWell(
          onTap: () => _toggleSection(sectionKey, setMenuState),
          child: Container(
            height: 40,
            width: 300,
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
        if (isExpanded) ...<Widget>[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: FusionAppText(
              text: "Speakers require zone creation. Please create a zone first.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.orange[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
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

  /// Get default image path for product types
  String _getDefaultImageForProductType(ProductType type) {
    switch (type) {
      case ProductType.speaker:
        return 'assets/images/speakers/default_speaker.png';
      case ProductType.amplifier:
        return 'assets/images/amplifiers/default_amplifier.png';
      case ProductType.dsps:
        return 'assets/images/processors/default_processor.png';
      case ProductType.controllers:
        return 'assets/images/controllers/default_controller.png';
      default:
        return 'assets/images/default_device.png';
    }
  }
}
