import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/models/products_data.dart';
import '../../../product_query/presentation/pages/product_query.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'create_new_location_widget.dart';
import 'listening_area_dropdown_widget.dart';

class AddDeviceExpandablePopupMenuWidget extends StatefulWidget {
  final String sectionTitle;
  final void Function(dynamic item, String areaId, String floorId)? onTapAddDevice;
  final List<ListeningArea> listeningAreas;
  // final List<Zone> zones;

  const AddDeviceExpandablePopupMenuWidget({
    super.key,
    required this.sectionTitle,
    this.onTapAddDevice,
    this.listeningAreas = const <ListeningArea>[],
    // this.zones = const <Zone>[],
  });

  @override
  State<AddDeviceExpandablePopupMenuWidget> createState() => _AddDeviceExpandablePopupMenuWidgetState();
}

class _AddDeviceExpandablePopupMenuWidgetState extends State<AddDeviceExpandablePopupMenuWidget> {
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
  final TextEditingController _zoneNameController = TextEditingController();

  /// Single variable to track which section is currently expanded
  String? _expandedSection;

  /// Local state for popup menu selections
  dynamic _selectedPopupDevice;
  List<String> _selectedListeningAreaIds = <String>[];
  String? _selectedColorHex;

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
    print('Add device added - Device: $_selectedPopupDevice, Areas: $_selectedListeningAreaIds');

    if (_selectedPopupDevice == null) {
      FusionToast.error(context, message: "Please select a device first");
      return;
    }

    if (_selectedListeningAreaIds.isEmpty) {
      FusionToast.error(context, message: "Please select a location first");
      return;
    }

    try {
      final FloorModel? floorData = projectViewModel.getFloorForListeningArea(areaId: _selectedListeningAreaIds.first);

      if (floorData == null) {
        FusionToast.error(context, message: "Floor not found for selected location");
        return;
      }

      widget.onTapAddDevice?.call(_selectedPopupDevice, _selectedListeningAreaIds.first, floorData.id);

      /// Clear selections and close popup - only setState here since popup is closing
      setState(() {
        _selectedPopupDevice = null;
        _selectedListeningAreaIds.clear();
      });
      Navigator.of(context).pop();
    } catch (e) {
      FusionToast.error(context, message: "Failed to add device: $e");
      print('Error adding device: $e');
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
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        maxHeight: 500,
        maxWidth: 300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Theme.of(context).colorScheme.white,
      menuPadding: EdgeInsets.zero,

      itemBuilder: (BuildContext context) {
        return <PopupMenuItem<dynamic>>[
          PopupMenuItem<dynamic>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              width: 300,
              constraints: const BoxConstraints(
                maxHeight: 460,
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
      child:
          widget.sectionTitle == "Speakers"
              ? Row(
                children: <Widget>[
                  Icon(Icons.add_sharp, size: 12, color: Theme.of(context).colorScheme.greyDark),
                  const SizedBox(width: 2),
                  FusionAppText(
                    text: "Add Zone",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 8,
                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                    ),
                  ),
                ],
              )
              : IconButton(
                icon: Icon(Icons.add_sharp, size: 16, color: Theme.of(context).colorScheme.greyDark),
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
            items: ProductAPI.getDeviceProducts(),
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
          _buildCreateZoneSection(setMenuState),
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
          _buildExpandableSection<RackData>(
            title: 'RACKS',
            sectionKey: 'RACKS',
            items: RackData.demoRacks,
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<SwitchData>(
            title: 'SWITCHES',
            sectionKey: 'SWITCHES',
            items: SwitchData.demoSwitchs,
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

    /// For RackData, compare by name and ensure both are RackData
    if (selectedDevice is RackData && item is RackData) {
      return selectedDevice.id == item.id;
    }

    /// for SwitchData, compare by name and ensure both are SwitchData
    if (selectedDevice is SwitchData && item is SwitchData) {
      return selectedDevice.id == item.id;
    }

    /// If same types, compare by name if available
    final String itemName = _getDisplayName(item);

    return selectedDevice == itemName;
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
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isDeviceSelected(_selectedPopupDevice, item) ? Colors.black : Theme.of(context).colorScheme.grey,
                    width: _isDeviceSelected(_selectedPopupDevice, item) ? 1 : 1,
                  ),
                  color: _isDeviceSelected(_selectedPopupDevice, item) ? Theme.of(context).colorScheme.grey : null,
                ),
                child: Row(
                  children: <Widget>[
                    if (item is SourceData)
                      Image.asset(
                        item.assetPath,
                        height: 14,
                        width: 14,
                      )
                    else if (item is RackData)
                      Image.asset(
                        item.assetPath,
                        height: 14,
                        width: 14,
                      )
                    else if (item is SwitchData)
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
                          fontSize: 11,
                          fontWeight: _isDeviceSelected(_selectedPopupDevice, item) ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                    if (_isDeviceSelected(_selectedPopupDevice, item))
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.black,
                      ),
                  ],
                ),
              ),
            ),
          ),

          /// Location Selection Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FusionAppText(
                  text: "Select Location",
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
                    // zones: widget.zones,
                    selectedListeningAreaIds: _selectedListeningAreaIds,
                    onSelectionChanged: (List<String> selectedIds, String floorId) {
                      _selectedListeningAreaIds = selectedIds;
                      setMenuState(() {}); // Update popup menu UI
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
  Widget _buildCreateZoneSection(StateSetter setMenuState) {
    bool isCreateAreaExpanded = false;
    final String selectedFloor = '';
    final String selectedFloorId = '';
    final TextEditingController areaNameController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FusionAppText(
                text: "Create Zone",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.fusionTextViewColor,
              ),
            ],
          ),
          Divider(
            color: Theme.of(context).colorScheme.dividerColor,
            thickness: 1,
          ),
          const SizedBox(height: 4),

          /// Zone Name Field
          FusionAppText(
            text: "Zone Name",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FusionTextField(
            controller: _zoneNameController,
            hintText: "Enter zone name",
            decoration: FusionInputDecoration.fusionDense(
              colorScheme: Theme.of(context).colorScheme,
              hintText: 'Enter zone name',
            ),
            onChanged: (String value) {},
          ),

          const SizedBox(height: 18),

          /// Location Dropdown
          FusionAppText(
            text: "Location",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          /// Location selection popup
          Container(
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: PopupMenuButton<String>(
              onCanceled: () {
                // Handle popup close if needed
              },
              constraints: const BoxConstraints(
                maxHeight: 500,
                maxWidth: 280,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Theme.of(context).colorScheme.white,
              offset: const Offset(0, 35),
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setPopupState) {
                        return Container(
                          width: 280,
                          constraints: const BoxConstraints(maxHeight: 460),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              /// Header with close button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: "Select Locations",
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.fusionTextViewColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// Scrollable list of listening areas
                              Flexible(
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Column(
                                    children:
                                        serviceLocator<ProjectViewModel>().getAllListeningAreas().map((ListeningArea area) {
                                          /// Get available areas for the current zone/sub-zone context
                                          final List<ListeningArea> availableListeningAreas = projectViewModel.getAvailableListeningAreasForZone(
                                            // zoneId: "",
                                          );
                                          final FloorModel? floorName = projectViewModel.getFloorForListeningArea(areaId: area.id);
                                          final Zone? zoneData = projectViewModel.getZonesForListeningArea(areaId: area.id);

                                          /// Check if this area is in the available list
                                          final bool isAvailable = availableListeningAreas.any((ListeningArea availableArea) => availableArea.id == area.id);

                                          return InkWell(
                                            onTap:
                                                isAvailable
                                                    ? () {
                                                      if (_selectedListeningAreaIds.contains(area.id)) {
                                                        _selectedListeningAreaIds.remove(area.id);
                                                      } else {
                                                        _selectedListeningAreaIds.add(area.id);
                                                      }

                                                      /// 2 state setters to update both popup and menu states
                                                      setPopupState(() {});
                                                      setMenuState(() {});
                                                    }
                                                    : null,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

                                              child: Row(
                                                children: <Widget>[
                                                  /// Checkbox for selection
                                                  SizedBox(
                                                    width: 14,
                                                    height: 4,
                                                    child: Checkbox(
                                                      value: !isAvailable ? true : _selectedListeningAreaIds.contains(area.id),
                                                      activeColor: Theme.of(context).colorScheme.greyDark,
                                                      onChanged:
                                                          isAvailable
                                                              ? (bool? checked) {
                                                                if (checked == true) {
                                                                  _selectedListeningAreaIds.add(area.id);
                                                                } else {
                                                                  _selectedListeningAreaIds.remove(area.id);
                                                                }
                                                                setPopupState(() {});
                                                                setMenuState(() {});
                                                              }
                                                              : null,
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      visualDensity: VisualDensity.compact,
                                                      shape: const RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.zero,
                                                        side: BorderSide(width: 0.5),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),

                                                  /// Area and zone names
                                                  Expanded(
                                                    child: FusionAppText(
                                                      text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Area',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 10,
                                                        color: isAvailable ? Theme.of(context).textTheme.bodySmall?.color : Colors.grey[400],
                                                      ),
                                                    ),
                                                  ),
                                                  FusionAppText(
                                                    text: zoneData?.name ?? "No zone",
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontSize: 9,
                                                      color: isAvailable ? Theme.of(context).colorScheme.greyDark : Theme.of(context).colorScheme.grey,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),

                              /// Create New Location Section
                              CreateNewLocationWidget(
                                areaNameController: areaNameController,
                                isCreateAreaExpanded: isCreateAreaExpanded,
                                setDropdownState: setPopupState,
                                selectedFloor: selectedFloor,
                                selectedFloorId: selectedFloorId,
                                onCreateNewArea: ({required String floorId}) {
                                  if (areaNameController.text.trim().isNotEmpty && floorId.isNotEmpty) {
                                    // todo: Replace with actual area creation logic (e.g., user-defined vertices)
                                    final ListeningArea newListeningArea = ListeningArea(
                                      name: areaNameController.text.trim(),
                                      vertices: <Offset>[
                                        const Offset(0, 0),
                                        const Offset(100, 0),
                                        const Offset(100, 100),
                                        const Offset(0, 100),
                                      ],
                                    );

                                    try {
                                      serviceLocator<ProjectViewModel>().addListeningArea(area: newListeningArea, floorId: floorId);

                                      /// Clear form and close expansion
                                      areaNameController.clear();
                                      setState(() {
                                        isCreateAreaExpanded = false;
                                      });

                                      /// Show success message
                                      FusionToast.success(
                                        context,
                                        message: "Listening area '${newListeningArea.name}' created successfully",
                                      );

                                      /// Automatically select the newly created area
                                      // widget.onSelectionChanged(<String>[newListeningArea.id], floorId);
                                      // Navigator.of(context).pop();
                                    } catch (e) {
                                      FusionToast.error(
                                        context,
                                        message: "Failed to create listening area: $e",
                                      );
                                    }
                                  } else {
                                    FusionToast.error(
                                      context,
                                      message: "Please enter location name and select a floor",
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ];
              },
              child: Container(
                height: 29,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text:
                            _selectedListeningAreaIds.isEmpty
                                ? "Select Location"
                                : "${_selectedListeningAreaIds.length} location${_selectedListeningAreaIds.length > 1 ? '(s)' : ''} selected",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _selectedListeningAreaIds.isEmpty ? Theme.of(context).colorScheme.greyDark : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).colorScheme.greyDark,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// Color Picker Placeholder
          FusionAppText(
            text: "Color",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          /// Color Grid
          SizedBox(
            height: 90,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: Zone.zoneColors.length,
              itemBuilder: (BuildContext context, int index) {
                final String hexCode = Zone.zoneColors[index];
                final Color color = hexToColor(hexCode);
                final bool isSelected = _selectedColorHex == hexCode;

                return GestureDetector(
                  onTap: () {
                    setMenuState(() {
                      _selectedColorHex = hexCode;
                    });
                    print('Selected color: $hexCode');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          isSelected
                              ? Border.all(
                                color: Theme.of(context).colorScheme.greyDark,
                                width: 2,
                              )
                              : null,
                    ),
                    child:
                        isSelected
                            ? Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.greyDark.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                            : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: FusionOutlinedButton(
                  width: double.infinity,
                  label: "Cancel",
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectedColorHex = "";
                    _zoneNameController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FusionButton(
                  width: double.infinity,
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.fusionButtonTextColor),

                  label: "Save",
                  isActive: _zoneNameController.text.isNotEmpty && _selectedColorHex != null && _selectedListeningAreaIds.isNotEmpty,
                  onTap: () {
                    final Zone newZone = Zone(
                      id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
                      name: _zoneNameController.text,
                      selectedMixIndex: 0,
                      zoneColor: _selectedColorHex,
                    );
                    serviceLocator<ProjectViewModel>().addZone(zone: newZone, autoSave: false);
                    serviceLocator<ProjectViewModel>().updateListeningAreasInZone(zoneId: newZone.id, listeningAreaIds: _selectedListeningAreaIds);
                    Navigator.of(context).pop();
                    _selectedColorHex = "";
                    _zoneNameController.clear();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Convert hex string to Color
  Color hexToColor(String hexString) {
    final StringBuffer buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Get display name for different item types
  String _getDisplayName(dynamic item) {
    if (item is SourceData || item is RackData || item is SwitchData || item is ProductQueryModel) {
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
