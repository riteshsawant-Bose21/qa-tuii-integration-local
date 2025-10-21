import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class ListeningAreaDropdownWidget extends StatefulWidget {
  final List<ListeningArea> listeningAreas;
  final List<Zone> zones;
  final List<String> selectedListeningAreaIds;
  final Function(List<String>) onSelectionChanged;
  final Function(String areaName, String venueType) onCreateNewArea;

  const ListeningAreaDropdownWidget({
    super.key,
    required this.listeningAreas,
    required this.zones,
    required this.selectedListeningAreaIds,
    required this.onSelectionChanged,
    required this.onCreateNewArea,
  });

  @override
  State<ListeningAreaDropdownWidget> createState() => _ListeningAreaDropdownWidgetState();
}

class _ListeningAreaDropdownWidgetState extends State<ListeningAreaDropdownWidget> {
  bool _isCreateAreaExpanded = false;
  final TextEditingController _areaNameController = TextEditingController();
  String _selectedVenueType = 'Indoor';
  final List<String> _venueTypes = <String>['Indoor', 'Outdoor', 'Mixed'];

  @override
  void dispose() {
    _areaNameController.dispose();
    super.dispose();
  }

  String _getZoneNameForListeningArea(String listeningAreaId) {
    for (final Zone zone in widget.zones) {
      if (zone.listeningAreasIds.contains(listeningAreaId)) {
        return zone.name;
      }
    }
    return 'No Zone';
  }

  void _toggleListeningAreaSelection(String areaId) {
    // For radio button behavior - only one selection allowed
    final List<String> newSelection = <String>[areaId];
    widget.onSelectionChanged(newSelection);
    print('Listening area selected: $areaId'); // Debug print
  }

  void _createNewArea() {
    if (_areaNameController.text.trim().isNotEmpty) {
      widget.onCreateNewArea(_areaNameController.text.trim(), _selectedVenueType);
      _areaNameController.clear();
      setState(() {
        _isCreateAreaExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: "Select Listening Areas",
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
            child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
              builder: (BuildContext context, ProjectViewModelState state) {
                return StatefulBuilder(
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
                                    text: "Listening Areas",
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
                          if (widget.listeningAreas.isNotEmpty)
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  children:
                                      serviceLocator<ProjectViewModel>().getAllListeningAreas().map((ListeningArea area) {
                                        final bool isSelected = widget.selectedListeningAreaIds.contains(area.id);
                                        final String zoneName = _getZoneNameForListeningArea(area.id);

                                        return InkWell(
                                          onTap: () {
                                            _toggleListeningAreaSelection(area.id);
                                            setDropdownState(() {}); // Update dropdown UI
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.blue[50] : null,
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Radio<String>(
                                                  value: area.id,
                                                  groupValue: widget.selectedListeningAreaIds.isNotEmpty ? widget.selectedListeningAreaIds.first : null,
                                                  onChanged: (String? value) {
                                                    if (value != null) {
                                                      _toggleListeningAreaSelection(value);
                                                      setDropdownState(() {}); // Update dropdown UI
                                                    }
                                                  },
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: FusionAppText(
                                                    text: area.name.isNotEmpty ? area.name : 'Unnamed Area',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 10),
                                                  ),
                                                ),
                                                FusionAppText(
                                                  text: zoneName,
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
                            ),

                          /// Create New Area Section
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                /// Create New Area Header
                                InkWell(
                                  onTap: () {
                                    setDropdownState(() {
                                      _isCreateAreaExpanded = !_isCreateAreaExpanded;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          child: FusionAppText(
                                            text: "Create New Listening Area",
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

                                // Create New Area Form
                                if (_isCreateAreaExpanded)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        // Area Name Field
                                        FusionAppText(
                                          text: "Area Name",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FusionTextField(
                                          controller: _areaNameController,
                                          hintText: "Enter area name",
                                          decoration: FusionInputDecoration.fusionDense(
                                            colorScheme: Theme.of(context).colorScheme,
                                            hintText: 'Enter area name',
                                          ),
                                          onChanged: (String value) {
                                            setDropdownState(() {}); // Update button state
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Venue Type Dropdown
                                        FusionAppText(
                                          text: "Venue Type",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedVenueType,
                                              isExpanded: true,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              items:
                                                  _venueTypes.map((String type) {
                                                    return DropdownMenuItem<String>(
                                                      value: type,
                                                      child: FusionAppText(
                                                        text: type,
                                                        style: Theme.of(context).textTheme.bodySmall,
                                                      ),
                                                    );
                                                  }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setDropdownState(() {
                                                    _selectedVenueType = newValue;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        /// Create and Select Button
                                        FusionButton(
                                          label: "Create and Select",
                                          isActive: _areaNameController.text.trim().isNotEmpty,
                                          onTap: () {
                                            if (_areaNameController.text.trim().isNotEmpty) {
                                              _createNewArea();
                                              setDropdownState(() {});
                                            }
                                          },
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
              text: widget.selectedListeningAreaIds.isEmpty ? "Select Areas" : "${widget.selectedListeningAreaIds.length} selected",
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
