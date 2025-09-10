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

  @override
  void dispose() {
    _floorNameController.dispose();
    _floorNameFocusNode.dispose();
    super.dispose();
  }

  /// Clear input fields
  void _clearFields() {
    _floorNameController.clear();
  }

  /// Add a new floor to the project
  void _addFloor() {
    if (_floorNameController.text.trim().isNotEmpty) {
      final FloorModel model = FloorModel(
        name: _floorNameController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FusionAppText(text: "Building Plan", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
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

          const SizedBox(height: 10),

          /// PopupMenuButton for dropdown functionality
          BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              final List<FloorModel> floors = serviceLocator<ProjectViewModel>().floors;

              // Ensure selectedIndex is within bounds
              if (selectedIndex >= floors.length) {
                selectedIndex = floors.isNotEmpty ? floors.length - 1 : 0;
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

              return PopupMenuButton<int>(
                onSelected: (int index) {
                  setState(() {
                    selectedIndex = index;
                  });
                  serviceLocator<ProjectViewModel>().setCurrentFloorIndex(index);
                },
                constraints: const BoxConstraints(maxHeight: 600, minWidth: 200),
                padding: EdgeInsets.zero,
                offset: const Offset(50, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
                ),
                color: Theme.of(context).colorScheme.white,
                elevation: 1,
                itemBuilder: (BuildContext context) {
                  /// Create ordered list with selected floor first
                  final List<int> orderedIndices = <int>[];

                  /// Add selected floor first
                  orderedIndices.add(selectedIndex);

                  /// Add all other floors
                  for (int i = 0; i < floors.length; i++) {
                    if (i != selectedIndex) {
                      orderedIndices.add(i);
                    }
                  }

                  return List<PopupMenuEntry<int>>.generate(floors.length, (int menuIndex) {
                    final int floorIndex = orderedIndices[menuIndex];
                    final bool isSelected = floorIndex == selectedIndex;
                    final FloorModel floorData = floors[floorIndex];

                    return PopupMenuItem<int>(
                      value: floorIndex,
                      padding: EdgeInsets.zero,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.grey : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: <Widget>[
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
                                text: floorData.name.length >= 2 ? floorData.name.substring(0, 2).toUpperCase() : floorData.name.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.fusionButtonTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: FusionAppText(
                                          text: floorData.name,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: Theme.of(context).colorScheme.fusionTextViewColor,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.fusionTextViewColor,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.greyDark,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                      ),
                      child: FusionAppText(
                        text:
                            floors[selectedIndex].name.length >= 2
                                ? floors[selectedIndex].name.substring(0, 2).toUpperCase()
                                : floors[selectedIndex].name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.fusionButtonTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: floors[selectedIndex].name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Show dropdown menu for adding a new floor
  void _showAddFloorDropdown() {
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
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.fusionTextViewColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      onSubmitted: (_) {
                        _addFloor();
                        Navigator.of(context).pop();
                      },
                    ),
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
                            Navigator.of(context).pop();
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
