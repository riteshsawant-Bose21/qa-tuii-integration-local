import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

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

  /// Check if floor name already exists
  bool _floorNameExists(String name) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    return viewModel.floors.any((FloorModel floor) => floor.name.toLowerCase() == name.toLowerCase());
  }

  /// Add a new floor to the project
  void _addFloor() {
    if (_floorNameController.text.trim().isNotEmpty) {
      final String floorName = _floorNameController.text.trim();

      // Check if floor name already exists
      if (_floorNameExists(floorName)) {
        setState(() {
          _errorMessage = "Floor name already exists";
        });
        return;
      }

      final FloorModel model = FloorModel(
        name: floorName,
        floorPlan: FloorPlanModel.defaultFloorPlan,
      );

      /// Add floor to the project
      final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
      viewModel.addFloor(model);

      setState(() {
        /// Select the newly added floor
        selectedIndex = viewModel.floors.length - 1;
      });

      /// Ensure the current floor index is updated
      viewModel.setCurrentFloorIndex(selectedIndex);

      _clearFields();
    }
  }

  /// Delete the selected floor
  void _deleteFloor(int index) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    if (viewModel.floors.length > 1) {
      final String floorId = viewModel.floors[index].id;
      viewModel.removeFloor(floorId);

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

    if (newName.isNotEmpty) {
      final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();

      // Check if the new name already exists (excluding current floor)
      final bool nameExists = viewModel.floors.asMap().entries.any(
        (MapEntry<int, FloorModel> entry) => entry.key != index && entry.value.name.toLowerCase() == newName.toLowerCase(),
      );

      if (!nameExists) {
        // Update the floor name
        final FloorModel updatedFloor = viewModel.floors[index].copyWith(name: newName);
        viewModel.updateFloor(updatedFloor);

        setState(() {
          _editingFloorIndex = null;
        });
      } else {
        // Show error - name already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Floor name "$newName" already exists'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      // Cancel editing if name is empty
      _cancelEditingFloor();
    }
  }

  /// Cancel editing floor name
  void _cancelEditingFloor() {
    setState(() {
      _editingFloorIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                FusionAppText(text: "BUILDING PLAN", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                GestureDetector(
                  onTap: _showAddFloorDropdown,
                  child: Icon(
                    Icons.add_sharp,
                    size: 14,
                    color: Theme.of(context).colorScheme.fusionTextViewColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.greyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FusionAppText(
                    text: "No floors available",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                );
              }

              return Column(
                children:
                    floors.asMap().entries.map((MapEntry<int, FloorModel> entry) {
                      final int index = entry.key;
                      final FloorModel floor = entry.value;
                      final bool isSelected = index == selectedIndex;
                      final bool isEditing = _editingFloorIndex == index;

                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.grey.withOpacity(0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                isEditing
                                    ? null
                                    : () {
                                      setState(() {
                                        selectedIndex = index;
                                      });
                                      viewModel.setCurrentFloorIndex(index);
                                    },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: <Widget>[
                                  // Floor icon
                                  Container(
                                    width: 18,
                                    height: 18,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.greyDark,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.dividerColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: FusionAppText(
                                      text: floor.name.length >= 2 ? floor.name.substring(0, 2).toUpperCase() : floor.name.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.fusionButtonTextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Floor name - editable or display
                                  Expanded(
                                    child:
                                        isEditing
                                            ? TextField(
                                              controller: _editControllers[index],
                                              focusNode: _editFocusNodes[index],
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.fusionTextViewColor,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                              ),
                                              onSubmitted: (_) => _saveFloorName(index),
                                              onTapOutside: (_) => _saveFloorName(index),
                                            )
                                            : FusionAppText(
                                              text: floor.name,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                color: Theme.of(context).colorScheme.fusionTextViewColor,
                                              ),
                                            ),
                                  ),

                                  // Edit icon and delete button for selected floor
                                  if (isSelected) ...<Widget>[
                                    IconButton(
                                      icon: Icon(
                                        isEditing ? Icons.check : Icons.edit,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.fusionTextViewColor,
                                      ),
                                      onPressed: () {
                                        if (isEditing) {
                                          _saveFloorName(index);
                                        } else {
                                          _startEditingFloor(index, floor.name);
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                    ),
                                    // Only show delete if there's more than one floor and not editing
                                    if (floors.length > 1 && !isEditing)
                                      GestureDetector(
                                        onTap: () => _showDeleteConfirmDialog(index),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
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
          content: Text(
            'Are you sure you want to delete "$floorName"? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            FusionOutlinedButton(
              height: 32,
              width: 80,
              label: "Cancel",
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              onTap: () {
                Navigator.of(context).pop(false);
              },
            ),
            const SizedBox(width: 8),
            FusionButton(
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

  /// Show dropdown menu for adding a new floor
  void _showAddFloorDropdown() {
    _clearFields(); // Clear any previous error messages

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(50, 18), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
      ),
      color: Theme.of(context).colorScheme.white,
      elevation: 1,
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 300),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FusionAppText(
                      text: "Add New Floor",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _floorNameController,
                      focusNode: _floorNameFocusNode,
                      autofocus: true,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.fusionTextViewColor,
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter floor name',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.grey,
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: _errorMessage != null ? Colors.red : Theme.of(context).colorScheme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: _errorMessage != null ? Colors.red : Theme.of(context).colorScheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: _errorMessage != null ? Colors.red : Theme.of(context).colorScheme.fusionTextViewColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
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
                          height: 28,
                          width: 64,
                          label: "Cancel",
                          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                          onTap: () {
                            _clearFields();
                            Navigator.of(context).pop();
                          },
                        ),

                        const SizedBox(width: 8),
                        FusionButton(
                          height: 28,
                          width: 80,
                          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.fusionButtonTextColor),

                          label: "Add Floor",
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
