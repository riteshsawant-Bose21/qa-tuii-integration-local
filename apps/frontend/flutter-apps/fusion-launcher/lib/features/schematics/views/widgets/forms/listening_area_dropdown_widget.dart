import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class ListeningAreaDropdownWidget extends StatefulWidget {
  final List<ListeningArea> listeningAreas;
  final List<String> selectedListeningAreaIds;
  final Function(List<String>, String floorId) onSelectionChanged;
  final bool hideAddLocationButton;

  const ListeningAreaDropdownWidget({
    super.key,
    required this.listeningAreas,
    required this.selectedListeningAreaIds,
    required this.onSelectionChanged,
    this.hideAddLocationButton = false,
  });

  @override
  State<ListeningAreaDropdownWidget> createState() => _ListeningAreaDropdownWidgetState();
}

class _ListeningAreaDropdownWidgetState extends State<ListeningAreaDropdownWidget> {
  bool _isCreateAreaExpanded = false;
  final TextEditingController _areaNameController = TextEditingController();
  String _selectedFloor = '';
  String _selectedFloorId = '';

  @override
  void initState() {
    super.initState();
    // Initialize with current floor data
    final FloorModel currentFloor = serviceLocator<ProjectViewModel>().currentFloor;
    _selectedFloor = currentFloor.name;
    _selectedFloorId = currentFloor.id;
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    super.dispose();
  }

  /// Toggle selection of a listening area
  void _toggleListeningAreaSelection(String areaId, String floorId) {
    final List<String> newSelection = <String>[areaId];
    widget.onSelectionChanged(newSelection, floorId);
    Navigator.of(context).pop();
  }

  /// Create a new listening area
  void _createNewArea({required String floorId}) {
    if (_areaNameController.text.trim().isNotEmpty && floorId.isNotEmpty) {
      // todo: Replace with actual area creation logic (e.g., user-defined vertices)
      final ListeningArea newListeningArea = ListeningArea(
        name: _areaNameController.text.trim(),
        vertices: <FusionCanvasPoint>[],
        isDrawn: false,
      );

      try {
        serviceLocator<ProjectViewModel>().addListeningArea(area: newListeningArea, floorId: floorId);

        /// Clear form and close expansion
        _areaNameController.clear();
        setState(() {
          _isCreateAreaExpanded = false;
        });

        /// Show success message
        FusionToast.success(
          context,
          message: "Location '${newListeningArea.name}' created successfully",
        );

        widget.onSelectionChanged(<String>[newListeningArea.id], floorId);
        Navigator.of(context).pop();
      } catch (e) {
        FusionToast.error(
          context,
          message: "Failed to create location: $e",
        );
      }
    } else {
      FusionToast.error(
        context,
        message: "Please enter location name and select a floor",
      );
    }
  }

  String _getSelectedAreaDisplayText() {
    if (widget.selectedListeningAreaIds.isEmpty) {
      return "Select location";
    }

    // Get the first selected area ID
    final String selectedId = widget.selectedListeningAreaIds.first;

    // Find the listening area by ID
    final ListeningArea? selectedArea = widget.listeningAreas.where((ListeningArea area) => area.id == selectedId).firstOrNull;

    if (selectedArea != null) {
      final FloorModel? floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: selectedArea.id);
      return selectedArea.name.isNotEmpty ? "${floorName?.name}/${selectedArea.name}" : 'Unnamed Area';
    }

    return "Unknown Area";
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenuButton<void>(
      tooltip: "",
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
      color: context.colorScheme.elevation1,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
        side: BorderSide(color: context.colorScheme.elevation2),
      ),
      menuSemanticLabel: "select_location_dropdown_menu",
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<void>>[
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "listening_area_container"),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setDropdownState) {
                  return Container(
                    width: 300,
                    constraints: const BoxConstraints(maxHeight: 380, maxWidth: 300),
                    color: context.colorScheme.elevation1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        /// Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: context.colorScheme.elevation2),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: FusionAppText(
                                  text: "Location",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                               SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, "listening_area_close_button"),
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: FusionSizes.iconSize16),
                                  color: context.colorScheme.primaryWhite,
                                  onPressed: () => Navigator.of(context).pop(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// Listening Areas List
                        Builder(
                          builder: (BuildContext context) {
                            if (widget.listeningAreas.isNotEmpty) {
                              return Flexible(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children:
                                        widget.listeningAreas.map((ListeningArea area) {
                                          final int index = widget.listeningAreas.indexOf(area);

                                          final bool isSelected = widget.selectedListeningAreaIds.contains(area.id);
                                          final Zone? zoneData = serviceLocator<ProjectViewModel>().getZonesForListeningArea(areaId: area.id);
                                          final FloorModel? floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: area.id);

                                          return InkWell(
                                            onTap: () {
                                              _toggleListeningAreaSelection(area.id, floorName?.id ?? '');
                                            },
                                            child: SemanticHelper.container(
                                              testId: SemanticHelper.createTestId(SemanticTypes.toggle, "select_listening_areas_item_$index"),
                                              // value: isSelected,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? context.colorScheme.elevation3 : null,
                                                ),
                                                child: Row(
                                                  children: <Widget>[
                                                    /// Radio Button
                                                    SemanticHelper.toggle(
                                                      testId: SemanticHelper.createTestId(SemanticTypes.toggle, "select_location_radio_button_${index}_radio"),
                                                      value: isSelected,
                                                      child: Radio<String>(
                                                        value: area.id,
                                                        activeColor: context.colorScheme.primaryWhite,
                                                        groupValue: widget.selectedListeningAreaIds.isNotEmpty ? widget.selectedListeningAreaIds.first : null,
                                                        onChanged: (String? value) {
                                                          if (value != null) {
                                                            _toggleListeningAreaSelection(value, floorName?.id ?? '');
                                                          }
                                                        },
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: FusionAppText(
                                                        semanticId: "listening_areas_name",
                                                        text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Location',
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 10),
                                                      ),
                                                    ),
                                                    FusionAppText(
                                                      semanticId: "listening_area_zone_name",
                                                      text: zoneData?.name ?? "No zone",
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontSize: 9,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: FusionAppText(
                                  text: "No locations available. Please create a new location.",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                        /// Create New Location Section
                        if (!widget.hideAddLocationButton)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                /// Create LoCATION Header
                                InkWell(
                                  onTap: () {
                                    setDropdownState(() {
                                      _isCreateAreaExpanded = !_isCreateAreaExpanded;
                                    });
                                  },
                                  child: SemanticHelper.toggle(
                                    testId: SemanticHelper.createTestId(SemanticTypes.toggle, "create_new_listening_area_toggle"),
                                    value: _isCreateAreaExpanded,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Expanded(
                                            child: FusionAppText(
                                              text: "Create new location",
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            _isCreateAreaExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                            size: 20,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                /// Create location form
                                if (_isCreateAreaExpanded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: context.colorScheme.elevation1),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        /// Floor Dropdown
                                        FusionAppText(
                                          text: "Floor",
                                          style: context.textTheme.bodySmall?.copyWith(
                                            fontSize: FusionSizes.fontSize12,
                                            color: context.colorScheme.primaryWhite,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 26,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: context.colorScheme.elevation2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              dropdownColor: context.colorScheme.primaryBlack,
                                              hint: const FusionAppText(text: "Select floor"),
                                              value: _selectedFloor,
                                              isExpanded: true,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              items: <DropdownMenuItem<String>>[
                                                ...serviceLocator<ProjectViewModel>().getAllFloors().map((FloorModel floor) {
                                                  final int index = serviceLocator<ProjectViewModel>().getAllFloors().indexOf(floor);

                                                  return DropdownMenuItem<String>(
                                                    value: floor.name,
                                                    child: SemanticHelper.container(
                                                      testId: SemanticHelper.createTestId(
                                                        SemanticTypes.container,
                                                        "create_new_location_floor_dropdown_item_${index}_container",
                                                      ),
                                                      child: FusionAppText(
                                                        text: floor.name,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: context.colorScheme.primaryWhite,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ],
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setDropdownState(() {
                                                    _selectedFloor = newValue;
                                                    _selectedFloorId =
                                                        serviceLocator<ProjectViewModel>()
                                                            .getAllFloors()
                                                            .firstWhere((FloorModel floor) => floor.name == newValue)
                                                            .id;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        /// location Name Field
                                        FusionAppText(
                                          text: "Location Name",
                                          style: context.textTheme.bodySmall?.copyWith(
                                            fontSize: FusionSizes.fontSize12,
                                            color: context.colorScheme.primaryWhite,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SemanticHelper.formControl(
                                          testId: SemanticHelper.createTestId(SemanticTypes.textInput, "create_new_location_name_field"),
                                          child: PropertyTextField(
                                            controller: _areaNameController,
                                            hintText: "Enter location name",
                                            onChanged: (String value) {
                                              setDropdownState(() {}); // Update button state
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        /// Create and Select Button
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: SemanticHelper.button(
                                            testId: SemanticHelper.createTestId(SemanticTypes.button, "create_new_location_add_button"),
                                            child: FusionButton(
                                              height: 32,
                                              label: "Add",
                                              activeBackgroundColor: context.colorScheme.primaryColor,
                                              textStyle: context.textTheme.labelMedium?.copyWith(color: Colors.white),
                                              isActive: _areaNameController.text.trim().isNotEmpty && _selectedFloorId.isNotEmpty,
                                              onTap: () {
                                                _createNewArea(floorId: _selectedFloorId);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ];
      },
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "select_location_dropdown"),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: context.colorScheme.elevation2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FusionAppText(
                text: _getSelectedAreaDisplayText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: context.colorScheme.primaryWhite,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: context.colorScheme.primaryWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
