import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class CreateNewLocationWidget extends StatefulWidget {
  final TextEditingController areaNameController;
  final bool isCreateAreaExpanded;
  final String selectedFloor;
  final String selectedFloorId;
  final void Function(void Function()) setDropdownState;
  final Function({required String floorId, required String floorName, required String locationName}) onCreateNewArea;

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
      decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colorScheme.elevation2))),
      child: Column(
        children: <Widget>[
          /// Header
          InkWell(
            onTap: () {
              widget.setDropdownState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: SemanticHelper.toggle(
              testId: SemanticHelper.createTestId(SemanticTypes.toggle, "create_new_location_expand_collapse"),
              value: _isExpanded,
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
                    RotatedBox(
                      quarterTurns: _isExpanded ? 0 : 2,
                      child: FusionSvgIcon(
                        icon: AssetSvg.expandUp,
                        size: FusionSizes.iconSize12,
                        color: context.colorScheme.primaryWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Expanded form
          if (_isExpanded)
            SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "create_new_location_form_container"),
              child: Container(
                padding: const EdgeInsets.all(12),
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
                    SemanticHelper.container(
                      testId: SemanticHelper.createTestId(SemanticTypes.container, "create_new_location_floor_dropdown_container"),
                      child: Container(
                        height: 26,
                        decoration: BoxDecoration(
                          // color: Theme.of(context).colorScheme.primaryWhite,
                          border: Border.all(color: context.colorScheme.elevation2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: context.colorScheme.elevation1,
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
                                  final int index = serviceLocator<ProjectViewModel>().getAllFloors().indexOf(floor);

                                  return DropdownMenuItem<String>(
                                    value: floor.name,
                                    child: SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "create_new_location_floor_dropdown_container_$index"),
                                      child: FusionAppText(
                                        text: floor.name,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
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

                    SemanticHelper.formControl(
                      testId: SemanticHelper.createTestId(SemanticTypes.textInput, "create_new_location_location_name_field"),
                      child: FusionTextField(
                        controller: widget.areaNameController,
                        hintText: "Enter location name",
                        color: context.colorScheme.elevation2,
                        onChanged: (String value) {
                          widget.setDropdownState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Add Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, "create_new_location_add_button"),
                        child: FusionButton(
                          height: 32,
                          label: "Add",
                          isActive: widget.areaNameController.text.trim().isNotEmpty && _selectedFloorId.isNotEmpty,
                          onTap: () {
                            widget.onCreateNewArea(
                              floorId: _selectedFloorId,
                              floorName: _selectedFloor ?? '',
                              locationName: widget.areaNameController.text.trim(),
                            );
                            widget.setDropdownState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
