import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPlan extends StatefulWidget {
  const BuildingPlan({super.key});

  @override
  State<BuildingPlan> createState() => _BuildingPlanState();
}

class _BuildingPlanState extends State<BuildingPlan> {
  int selectedIndex = 0;
  final TextEditingController _floorNameController = TextEditingController();
  final FocusNode _floorNameFocusNode = FocusNode();
  String? _errorMessage;

  // Add editing state tracking
  int? _editingFloorIndex;
  final Map<int, TextEditingController> _editControllers = <int, TextEditingController>{};
  final Map<int, FocusNode> _editFocusNodes = <int, FocusNode>{};

  @override
  void initState() {
    super.initState();

    /// Initialize selectedIndex from ProjectViewModel's current floor index
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    selectedIndex = viewModel.currentFloorIndex;
  }

  @override
  void dispose() {
    _floorNameController.dispose();
    _floorNameFocusNode.dispose();

    // Dispose all edit controllers and focus nodes
    for (final TextEditingController controller in _editControllers.values) {
      controller.dispose();
    }
    for (final FocusNode focusNode in _editFocusNodes.values) {
      focusNode.dispose();
    }

    super.dispose();
  }

  /// Clear input fields
  void _clearFields() {
    _floorNameController.clear();
    _errorMessage = null;
  }

  // /// Check if floor name already exists
  // bool _floorNameExists(String name) {
  //   final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
  //   return viewModel.floors.any((FloorModel floor) => floor.name.toLowerCase() == name.toLowerCase());
  // }

  /// Add a new floor to the project
  void _addFloor() {
    final String floorName = _floorNameController.text.trim();

    if (floorName.isEmpty) {
      setState(() {
        _errorMessage = "Floor name can't be empty";
      });
      return;
    }

    // // Check if floor name already exists
    // if (_floorNameExists(floorName)) {
    //   setState(() {
    //     _errorMessage = "Floor name already exists";
    //   });
    //   return;
    // }

    final FloorModel model = FloorModel(
      name: floorName,
      floorPlan: FloorPlanModel.defaultFloorPlan,
    );

    /// Add floor to the project
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    viewModel.addFloor(floor: model);

    setState(() {
      /// Select the newly added floor
      selectedIndex = viewModel.floors.length - 1;
    });

    /// Ensure the current floor index is updated
    viewModel.setCurrentFloorIndex(selectedIndex);

    _clearFields();

    // Set toolbar mode to acoustics mode for new floor.
    viewModel.setToolbarMode(ToolbarMode.acoustics);
  }

  /// Delete the selected floor
  void _deleteFloor(int index) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    if (viewModel.floors.length > 1) {
      final String floorId = viewModel.floors[index].id;
      viewModel.removeFloor(floorId: floorId);

      setState(() {
        // Adjust selectedIndex after deletion
        if (selectedIndex >= viewModel.floors.length) {
          selectedIndex = viewModel.floors.length - 1;
        }
        if (selectedIndex < 0) {
          selectedIndex = 0;
        }
      });

      viewModel.setCurrentFloorIndex(selectedIndex);
    }
  }

  /// Start editing a floor name
  void _startEditingFloor(int index, String currentName) {
    setState(() {
      _editingFloorIndex = index;
    });

    // Create controller and focus node if they don't exist
    if (!_editControllers.containsKey(index)) {
      _editControllers[index] = TextEditingController();
      _editFocusNodes[index] = FocusNode();
    }

    _editControllers[index]!.text = currentName;

    // Focus the text field after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNodes[index]?.requestFocus();
    });
  }

  /// Save the edited floor name
  void _saveFloorName(int index) {
    final String newName = _editControllers[index]?.text.trim() ?? '';

    if (newName.isEmpty) {
      setState(() {
        _errorMessage = "Floor name can't be empty";
      });
      return;
    }

    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();

    // Check if the new name already exists (excluding current floor)
    final bool nameExists = viewModel.floors.asMap().entries.any(
      (MapEntry<int, FloorModel> entry) => entry.key != index && entry.value.name.toLowerCase() == newName.toLowerCase(),
    );

    if (!nameExists) {
      // Update the floor name
      final FloorModel updatedFloor = viewModel.floors[index].copyWith(
        name: newName,
      );
      viewModel.updateFloor(floor: updatedFloor);

      setState(() {
        _editingFloorIndex = null;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = "Floor name already exists";
      });
    }
  }

  /// Cancel editing floor name
  void _cancelEditingFloor() {
    setState(() {
      _editingFloorIndex = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FusionAppText(
                text: "FLOORS",
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: context.colorScheme.textPrimary,
                ),
              ),
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.button,
                  FusionTestKeys.addFloorPlusButton,
                ),
                child: GestureDetector(
                  onTap: _showAddFloorDropdown,
                  child: Icon(
                    Icons.add_sharp,
                    size: 14,
                    color: Theme.of(context).colorScheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        /// List view for floors
        BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
            final List<FloorModel> floors = viewModel.floors;

            // Synchronize selectedIndex with ProjectViewModel's current floor index
            if (selectedIndex != viewModel.currentFloorIndex) {
              selectedIndex = viewModel.currentFloorIndex;
            }

            // Ensure selectedIndex is within bounds
            if (selectedIndex >= floors.length) {
              selectedIndex = floors.isNotEmpty ? floors.length - 1 : 0;
              viewModel.setCurrentFloorIndex(selectedIndex);
            }

            if (floors.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FusionAppText(
                    text: "No floors available",
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.primaryWhite,
                    ),
                  ),
                ),
              );
            }

            return Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  children: <Widget>[
                    ...floors.asMap().entries.map((MapEntry<int, FloorModel> entry) {
                      final int index = entry.key;
                      final FloorModel floor = entry.value;
                      final bool isSelected = index == selectedIndex;
                      final bool isEditing = _editingFloorIndex == index;

                      return SemanticHelper.listItem(
                        index: index,
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.listItem,
                          "floor_item_$index",
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? context.colorScheme.elevation2 : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              FusionSizes.borderRadius8,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap:
                                  isEditing
                                      ? null
                                      : () {
                                        setState(() => selectedIndex = index);
                                        viewModel.setCurrentFloorIndex(index);
                                      },
                              borderRadius: BorderRadius.circular(
                                FusionSizes.borderRadius8,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        // Floor icon
                                        Container(
                                          width: 20,
                                          height: 20,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: context.colorScheme.primaryWhite,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: FusionAppText(
                                            text: floor.name.length >= 2 ? floor.name.substring(0, 2).toUpperCase() : floor.name.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: context.colorScheme.primaryBlack,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Floor name - editable or display
                                        Expanded(
                                          child: Builder(
                                            builder: (BuildContext context) {
                                              if (isEditing) {
                                                return SemanticHelper.formControl(
                                                  testId: SemanticHelper.createTestId(
                                                    SemanticTypes.formControl,
                                                    "floor_name_edit_input_$index",
                                                  ),
                                                  child: PropertyTextField(
                                                    hintText: "Enter floor name",
                                                    controller: _editControllers[index],
                                                    focusNode: _editFocusNodes[index],
                                                    maxLength: 24,
                                                    // decoration: InputDecoration(
                                                    //   counterText: "",
                                                    //   border: InputBorder.none,
                                                    //   contentPadding: EdgeInsets.zero,
                                                    //   isDense: true,
                                                    //   enabledBorder:
                                                    //       _errorMessage != null ? const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)) : null,
                                                    //   focusedBorder:
                                                    //       _errorMessage != null ? const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)) : null,
                                                    // ),
                                                    onChanged: (_) {
                                                      if (_errorMessage != null) {
                                                        setState(() {
                                                          _errorMessage = null;
                                                        });
                                                      }
                                                    },
                                                    onSubmitted:
                                                        (_) => _saveFloorName(
                                                          index,
                                                        ),
                                                    onTapOutside:
                                                        (_) => _saveFloorName(
                                                          index,
                                                        ),
                                                  ),
                                                );
                                              } else {
                                                return FusionAppText(
                                                  text: floor.name,
                                                  maxLine: 2,
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontSize: 12,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                    color: Theme.of(context).colorScheme.textPrimary,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),

                                        // Edit icon and delete button for selected floor
                                        if (isSelected) ...<Widget>[
                                          (isEditing)
                                              ? SemanticHelper.button(
                                                testId: SemanticHelper.createTestId(
                                                  SemanticTypes.button,
                                                  "floor_name_edit_save_check_button_$index",
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Theme.of(context).colorScheme.textPrimary,
                                                  ),
                                                  onPressed: () async {
                                                    // Prevent multiple rapid taps
                                                    if (_editingFloorIndex != index) return;

                                                    _saveFloorName(index);
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(
                                                    minWidth: 24,
                                                    minHeight: 24,
                                                  ),
                                                ),
                                              )
                                              : Container(),
                                          (!isEditing)
                                              ? SemanticHelper.button(
                                                testId: SemanticHelper.createTestId(
                                                  SemanticTypes.button,
                                                  "floor_name_edit_button_$index",
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    size: 16,
                                                    color: Theme.of(context).colorScheme.textPrimary,
                                                  ),
                                                  onPressed: () {
                                                    // Prevent starting edit if already editing
                                                    if (_editingFloorIndex != null) return;

                                                    _startEditingFloor(
                                                      index,
                                                      floor.name,
                                                    );
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(
                                                    minWidth: 24,
                                                    minHeight: 24,
                                                  ),
                                                ),
                                              )
                                              : Container(),
                                          // Only show delete if there's more than one floor and not editing
                                          if (floors.length > 1 && !isEditing)
                                            SemanticHelper.button(
                                              testId: SemanticHelper.createTestId(
                                                SemanticTypes.button,
                                                "delete_floor_button_$index",
                                              ),
                                              child: GestureDetector(
                                                onTap:
                                                    () => _showDeleteConfirmDialog(
                                                      index,
                                                    ),
                                                child: const Icon(
                                                  LucideIcons.trash200,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          if (floors.length == 1 && !isEditing)
                                            SemanticHelper.button(
                                              testId: SemanticHelper.createTestId(
                                                SemanticTypes.button,
                                                "delete_floor_button_$index",
                                              ),
                                              child: GestureDetector(
                                                onTap:
                                                    () => _showRestConfirmDialog(
                                                      index,
                                                    ),
                                                child: const Icon(
                                                  LucideIcons.trash200,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                    // Show error message below the text field when editing
                                    if (isEditing && _errorMessage != null) ...<Widget>[
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 30,
                                          ), // Align with text field
                                          child: FusionAppText(
                                            text: _errorMessage!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              fontSize: 10,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Reset floor to default state
  void _resetFloor(int index) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    final FloorModel currentFloor = viewModel.floors[index];
    //remove floor
    viewModel.removeFloor(floorId: currentFloor.id);
    //add new floor with same name
    final FloorModel model = FloorModel(
      name: "Floor 1",
      floorPlan: FloorPlanModel.defaultFloorPlan,
    );

    // remove all zones
    viewModel.removeAllZones();
    viewModel.addFloor(floor: model);
  }

  /// Show confirmation dialog for deleting a floor
  void _showDeleteConfirmDialog(int index) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    final String floorName = viewModel.floors[index].name;

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Floor',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: FusionAppText(
            semanticId: "dialog_delete_floor_confirmation",
            text: 'Are you sure you want to delete "$floorName"? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            FusionOutlinedButton(
              accessLabel: 'building_plan_cancel_floor_button',
              height: 32,
              width: 80,
              label: "Cancel",
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontSize: 12),
              onTap: () {
                Navigator.of(context).pop(false);
              },
            ),
            const SizedBox(width: 8),
            FusionButton(
              accessLabel: 'building_plan_delete_floor_button',
              height: 32,
              width: 80,
              label: "Delete",
              activeBackgroundColor: Theme.of(context).colorScheme.error,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                color: Colors.white,
              ),
              onTap: () {
                Navigator.of(context).pop(true);
                _deleteFloor(index);
              },
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog for deleting a floor
  void _showRestConfirmDialog(int index) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    final String floorName = viewModel.floors[index].name;

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reset Floor',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SemanticHelper.staticText(
            testId: SemanticHelper.createTestId(
              SemanticTypes.text,
              "dialog_reset_floor_confirmation",
            ),
            child: Text(
              'Are you sure you want to Reset "$floorName"? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: <Widget>[
            FusionOutlinedButton(
              accessLabel: 'building_plan_reset_cancel',
              height: 32,
              width: 80,
              label: "Cancel",
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontSize: 12),
              onTap: () {
                Navigator.of(context).pop(false);
              },
            ),
            const SizedBox(width: 8),
            FusionButton(
              accessLabel: 'building_plan_delete_floor_button',
              height: 32,
              width: 80,
              label: "Delete",
              activeBackgroundColor: context.colorScheme.volumeRed,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                color: Colors.white,
              ),
              onTap: () {
                Navigator.of(context).pop(true);
                _resetFloor(index);
              },
            ),
          ],
        );
      },
    );
  }

  /// Show dropdown menu for adding a new floor
  void _showAddFloorDropdown() {
    _clearFields(); // Clear any previous error messages

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(50, 18), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).colorScheme.elevation2),
      ),
      color: Theme.of(context).colorScheme.elevation1,
      elevation: 1,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setMenuState) {
              /// Auto-focus the text field when the menu opens
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _floorNameFocusNode.requestFocus();
              });

              return Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FusionAppText(
                      text: "Add New Floor",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SemanticHelper.formControl(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.textInput,
                        FusionTestKeys.floorName,
                      ),
                      child: PropertyTextField(
                        controller: _floorNameController,
                        focusNode: _floorNameFocusNode,
                        maxLength: 24,
                        autofocus: true,
                        hintText: 'Enter floor name',
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setMenuState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                        onSubmitted: (_) {
                          _addFloor();
                          if (_errorMessage == null) {
                            Navigator.of(context).pop();
                          } else {
                            setMenuState(() {});
                          }
                        },
                      ),
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 4),
                      FusionAppText(
                        text: _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FusionOutlinedButton(
                          accessLabel: 'building_plan_cancel_floor_button',
                          height: 28,
                          width: 64,
                          label: "Cancel",
                          textStyle: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(fontSize: 10),
                          onTap: () {
                            _clearFields();
                            Navigator.of(context).pop();
                          },
                        ),

                        const SizedBox(width: 8),
                        FusionButton(
                          accessLabel: 'building_plan_add_floor_button',
                          height: 28,
                          width: 80,
                          textStyle: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            color: context.colorScheme.primaryBlack,
                          ),
                          label: "Add Floor",
                          activeBackgroundColor: context.colorScheme.primaryWhite,
                          onTap: () {
                            _addFloor();
                            if (_errorMessage == null) {
                              Navigator.of(context).pop();
                            } else {
                              setMenuState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
