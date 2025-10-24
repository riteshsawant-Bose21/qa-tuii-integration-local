import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class CreateNewLocationWidget extends StatefulWidget {
  final TextEditingController areaNameController;
  final bool isCreateAreaExpanded;
  final String selectedFloor;
  final String selectedFloorId;
  final void Function(void Function()) setDropdownState;
  final Function({required String floorId}) onCreateNewArea;

  const CreateNewLocationWidget({
    super.key,
    required this.areaNameController,
    required this.isCreateAreaExpanded,
    required this.selectedFloor,
    required this.selectedFloorId,
    required this.setDropdownState,
    required this.onCreateNewArea,
  });

  @override
  State<CreateNewLocationWidget> createState() => _CreateNewLocationWidgetState();
}

class _CreateNewLocationWidgetState extends State<CreateNewLocationWidget> {
  late bool _isExpanded;
  late String? _selectedFloor;
  late String _selectedFloorId;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isCreateAreaExpanded;
    _selectedFloor = widget.selectedFloor.isNotEmpty ? widget.selectedFloor : null;
    _selectedFloorId = widget.selectedFloorId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// Header
          InkWell(
            onTap: () {
              widget.setDropdownState(() {
                _isExpanded = !_isExpanded;
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
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          /// Expanded form
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Floor label
                  FusionAppText(
                    text: "Floor",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// Floor dropdown
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
                        hint: FusionAppText(
                          text: "Select floor",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                            widget.setDropdownState(() {
                              _selectedFloor = newValue;
                              _selectedFloorId = serviceLocator<ProjectViewModel>().getAllFloors().firstWhere((FloorModel f) => f.name == newValue).id;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// Location Name
                  FusionAppText(
                    text: "Location Name",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  FusionTextField(
                    controller: widget.areaNameController,
                    hintText: "Enter location name",
                    decoration: FusionInputDecoration.fusionDense(
                      colorScheme: Theme.of(context).colorScheme,
                      hintText: 'Enter location name',
                    ),
                    onChanged: (String value) {
                      widget.setDropdownState(() {});
                    },
                  ),
                  const SizedBox(height: 12),

                  /// Add Button
                  Align(
                    alignment: Alignment.centerRight,

                    child: FusionButton(
                      height: 32,
                      label: "Add",
                      isActive: widget.areaNameController.text.trim().isNotEmpty && _selectedFloorId.isNotEmpty,
                      onTap: () {
                        widget.onCreateNewArea(floorId: _selectedFloorId);
                        widget.setDropdownState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
