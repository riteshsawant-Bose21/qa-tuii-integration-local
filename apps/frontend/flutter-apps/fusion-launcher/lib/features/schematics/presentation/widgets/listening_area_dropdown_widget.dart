import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

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
        _areaNameController.clear();
        setState(() {
          _isCreateAreaExpanded = false;
        });

        /// Show success message
        FusionToast.success(
          context,
          message: "Location '${newListeningArea.name}' created successfully",
        );

        /// Automatically select the newly created area
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
    return PopupMenuButton<void>(
      tooltip: "Select Location",
      constraints: const BoxConstraints(
        maxHeight: 400,
        maxWidth: 300,
      ),
      color: Colors.white,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<void>>[
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDropdownState) {
                return Container(
                  width: 300,
                  constraints: const BoxConstraints(
                    maxHeight: 380,
                    maxWidth: 300,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      /// Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
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
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      /// Listening Areas List
                      widget.listeningAreas.isNotEmpty
                          ? Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                children:
                                    widget.listeningAreas.map((ListeningArea area) {
                                      final bool isSelected = widget.selectedListeningAreaIds.contains(area.id);
                                      final Zone? zoneData = serviceLocator<ProjectViewModel>().getZonesForListeningArea(areaId: area.id);
                                      final FloorModel? floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: area.id);

                                      return InkWell(
                                        onTap: () {
                                          _toggleListeningAreaSelection(area.id, floorName?.id ?? '');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Theme.of(context).colorScheme.grey : null,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              /// Radio Button
                                              Radio<String>(
                                                value: area.id,
                                                activeColor: Theme.of(context).colorScheme.greyDark,
                                                groupValue: widget.selectedListeningAreaIds.isNotEmpty ? widget.selectedListeningAreaIds.first : null,
                                                onChanged: (String? value) {
                                                  if (value != null) {
                                                    _toggleListeningAreaSelection(value, floorName?.id ?? '');
                                                  }
                                                },
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: FusionAppText(
                                                  text: area.name.isNotEmpty ? "${floorName?.name}/${area.name}" : 'Unnamed Location',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 10),
                                                ),
                                              ),
                                              FusionAppText(
                                                text: zoneData?.name ?? "No zone",
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontSize: 9,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          )
                          : Padding(
                            padding: const EdgeInsets.all(12),
                            child: FusionAppText(
                              text: "No locations available. Please create a new location.",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
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
                                child: Container(
                                  padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12, right: 12),
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

                              /// Create location form
                              if (_isCreateAreaExpanded)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      /// Floor Dropdown
                                      FusionAppText(
                                        text: "Floor",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.white,

                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            dropdownColor: Theme.of(context).colorScheme.white,
                                            hint: const FusionAppText(text: "Select floor"),
                                            value: _selectedFloor,
                                            isExpanded: true,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            items:
                                                serviceLocator<ProjectViewModel>().getAllFloors().map((FloorModel floor) {
                                                  return DropdownMenuItem<String>(
                                                    value: floor.name,
                                                    child: FusionAppText(
                                                      text: floor.name,
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  );
                                                }).toList(),
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
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FusionTextField(
                                        controller: _areaNameController,
                                        hintText: "Enter location name",
                                        decoration: FusionInputDecoration.fusionDense(
                                          colorScheme: Theme.of(context).colorScheme,
                                          hintText: 'Enter location name',
                                        ),
                                        onChanged: (String value) {
                                          setDropdownState(() {}); // Update button state
                                        },
                                      ),

                                      const SizedBox(height: 12),

                                      /// Create and Select Button
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: FusionButton(
                                          height: 32,
                                          label: "Add",
                                          isActive: _areaNameController.text.trim().isNotEmpty && _selectedFloorId.isNotEmpty,
                                          onTap: () {
                                            _createNewArea(floorId: _selectedFloorId);
                                          },
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
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
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
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
          ],
        ),
      ),
    );
  }
}
