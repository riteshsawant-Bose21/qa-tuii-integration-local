import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/models/products_data.dart';
import '../../../product_query/presentation/pages/product_query.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'listening_area_dropdown_widget.dart';

class ExpandablePopupMenuWidget extends StatefulWidget {
  final String sectionTitle;
  final void Function(dynamic item)? onItemTap;
  final List<ListeningArea> listeningAreas;
  final List<Zone> zones;
  final Function(String deviceId, List<String> listeningAreaIds)? onAddDeviceToAreas;

  const ExpandablePopupMenuWidget({
    super.key,
    required this.sectionTitle,
    this.onItemTap,
    this.listeningAreas = const <ListeningArea>[],
    this.zones = const <Zone>[],
    this.onAddDeviceToAreas,
  });

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

  void _addDeviceToSelectedAreas() {
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final dynamic selectedDevice = projectViewModel.selectedPopupDevice;
    final List<String> selectedAreas = projectViewModel.selectedListeningAreaIds;

    print('Add device called - Device: $selectedDevice, Areas: $selectedAreas'); // Debug print
    if (selectedDevice != null && selectedAreas.isNotEmpty) {
      widget.onItemTap?.call(selectedDevice);
      projectViewModel.clearPopupSelections();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SourceData>(
      onCanceled: () {
        /// Clear selections when menu is closed without adding
        context.read<ProjectViewModel>().clearPopupSelections();
      },
      tooltip: getSectionToolTip(),
      constraints: const BoxConstraints(
        maxHeight: 500,
        maxWidth: 300,
      ),
      onSelected: (SourceData selectedBlock) {
        context.read<ProjectViewModel>().setPopupDeviceSelection(selectedBlock);
      },
      color: Colors.white,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<SourceData>>[
          PopupMenuItem<SourceData>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              width: 300,
              constraints: const BoxConstraints(
                maxHeight: 480,
                maxWidth: 300,
              ),
              child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                builder: (BuildContext context, ProjectViewModelState state) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setMenuState) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: _buildSectionsForTitle(setMenuState),
                        ),
                      );
                    },
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
            onTap: () {
              _microphoneExpanded = !_microphoneExpanded;
              setMenuState(() {});
            },
            items: SourceData.microphoneItems,
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<SourceData>(
            title: 'MEDIA SOURCES',
            isExpanded: _mediaSourceExpanded,
            onTap: () {
              _mediaSourceExpanded = !_mediaSourceExpanded;
              setMenuState(() {});
            },
            items: SourceData.mediaSourceItems,
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<ProductQueryModel>(
            title: 'END POINTS',
            isExpanded: _endPointsExpanded,
            onTap: () {
              _endPointsExpanded = !_endPointsExpanded;
              setMenuState(() {});
            },
            items: ProductAPI.getEndpoints(),
            setMenuState: setMenuState,
          ),
        ];

      case "Processors & Amplifiers":
        return <Widget>[
          _buildExpandableSection<ProductQueryModel>(
            title: 'PROCESSORS',
            isExpanded: _processorsExpanded,
            onTap: () {
              _processorsExpanded = !_processorsExpanded;
              setMenuState(() {});
            },
            items: ProductAPI.getControllers(),
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<ProductQueryModel>(
            title: 'AMPLIFIERS',
            isExpanded: _amplifiersExpanded,
            onTap: () {
              _amplifiersExpanded = !_amplifiersExpanded;
              setMenuState(() {});
            },
            items: ProductAPI.getAmplifierProducts(),
            setMenuState: setMenuState,
          ),
        ];

      case "Speakers":
        return <Widget>[
          _buildCreateZoneSection<ProductQueryModel>(
            title: 'SPEAKERS',
            isExpanded: _speakersExpanded,
            onTap: () {
              _speakersExpanded = !_speakersExpanded;
              setMenuState(() {});
            },
            items: ProductAPI.getSpeakerProducts(),
          ),
        ];

      case "Controllers":
        return <Widget>[
          _buildExpandableSection<ProductQueryModel>(
            title: 'CONTROLLERS',
            isExpanded: _controllersExpanded,
            onTap: () {
              _controllersExpanded = !_controllersExpanded;
              setMenuState(() {});
            },
            items: ProductAPI.getControllers(),
            setMenuState: setMenuState,
          ),
        ];

      case "Accessories":
        return <Widget>[
          _buildExpandableSection<String>(
            title: 'RACKS',
            isExpanded: _racksExpanded,
            onTap: () {
              _racksExpanded = !_racksExpanded;
              setMenuState(() {});
            },
            items: <String>['4U', '8U', '12U', '24U'],
            setMenuState: setMenuState,
          ),
          _buildExpandableSection<SourceData>(
            title: 'OTHER DEVICES',
            isExpanded: _otherDevicesExpanded,
            onTap: () {
              _otherDevicesExpanded = !_otherDevicesExpanded;
              setMenuState(() {});
            },
            items: SourceData.microphoneItems,
            setMenuState: setMenuState,
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
    required StateSetter setMenuState,
  }) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
        final dynamic selectedDevice = projectViewModel.selectedPopupDevice;
        final List<String> selectedAreas = projectViewModel.selectedListeningAreaIds;
        final bool canAddDevice = selectedDevice != null && selectedAreas.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// Section Header
            InkWell(
              onTap: onTap,
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
                    context.read<ProjectViewModel>().setPopupDeviceSelection(item);
                    print('Device selected via tap: ${_getDisplayName(item)}'); // Debug print
                  },
                  child: Container(
                    height: 30,
                    width: 268,
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selectedDevice == item ? Colors.blue : Theme.of(context).colorScheme.grey,
                        width: selectedDevice == item ? 2 : 1,
                      ),
                      color: selectedDevice == item ? Colors.blue[100] : null,
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
                              color: selectedDevice == item ? Colors.blue[800] : null,
                              fontWeight: selectedDevice == item ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                        if (selectedDevice == item)
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
                        selectedListeningAreaIds: selectedAreas,
                        onSelectionChanged: (List<String> selectedIds) {
                          context.read<ProjectViewModel>().setListeningAreaSelection(selectedIds);
                          print('Listening areas selected: $selectedIds'); // Debug print
                        },
                        onCreateNewArea: (String areaName, String venueType) {
                          final ListeningArea newArea = ListeningArea(
                            name: areaName,
                            vertices: <Offset>[],
                            venuType: venueType,
                          );

                          final List<String> updatedSelection = List<String>.from(selectedAreas)..add(newArea.id);
                          context.read<ProjectViewModel>().setListeningAreaSelection(updatedSelection);
                          print('Created new listening area: $areaName ($venueType)');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Add Device Button (only visible when device and areas are selected)
              // if (canAddDevice)
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
      },
    );
  }

  /// create zone section
  Widget _buildCreateZoneSection<T>({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<T> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Section Header with close button
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
            ),
          ),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 16),
              Expanded(
                child: FusionAppText(
                  text: "Create Zone",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 22,
                  color: Theme.of(context).colorScheme.fusionTextViewColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        FusionAppText(
          text: "Zone Name",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
        const SizedBox(height: 8),
        FusionTextField(
          hintText: "",
          controller: TextEditingController(),
          decoration: FusionInputDecoration.fusionDense(
            colorScheme: Theme.of(context).colorScheme,
            hintText: 'Enter zone name',
            // errorText: "",
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
