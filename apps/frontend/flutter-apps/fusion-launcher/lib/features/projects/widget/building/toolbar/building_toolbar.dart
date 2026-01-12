import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/add_source_popup/view/add_source_popup.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/product_query/presentation/viewModel/product_query_view_model_cubit.dart';
import 'package:fusion_launcher/features/projects/models/device_item_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../../core/models/products_data.dart';

enum _AcousticsToolType {
  draw,
  speakers,
  spl,
}

class BuildingToolbar extends StatefulWidget {
  final Function() onSplSelected;
  final Function() onSplDisabled;
  final Function() onPanSelected;
  final Function() onMoveSelected;
  final Function() onDrawSelected;
  final Function() onDrawingDisabled;
  final Function() onEditFloorPlanSelected;
  final Function() onTrashSelected;
  final Function() onFitSelected;
  final Function() onAddSpeakerSelected;
  final Function() onAddSourceSelected;
  final Function() onAddEndpointSelected;
  final Function() onAddAmplifierSelected;
  final Function() onAddDspSelected;
  final Function() onAddControllerSelected;
  final Function() onAddRackSelected;
  final Function() onProductSelected;
  final Function() onProductDeselected;
  final bool isSplSelected;
  final bool isDrawSelected;

  const BuildingToolbar({
    super.key,
    required this.onSplSelected,
    required this.onSplDisabled,
    required this.onPanSelected,
    required this.onMoveSelected,
    required this.onDrawSelected,
    required this.onDrawingDisabled,
    required this.onEditFloorPlanSelected,
    required this.onTrashSelected,
    required this.onFitSelected,
    required this.onAddSpeakerSelected,
    required this.onAddSourceSelected,
    required this.onAddEndpointSelected,
    required this.onAddAmplifierSelected,
    required this.onAddDspSelected,
    required this.onAddControllerSelected,
    required this.onAddRackSelected,
    required this.onProductSelected,
    required this.isSplSelected,
    required this.isDrawSelected,
    required this.onProductDeselected,
  });

  @override
  State<BuildingToolbar> createState() => _BuildingToolbarState();
}

class _BuildingToolbarState extends State<BuildingToolbar> {
  static const List<String> _rackOptions = <String>[
    '4U',
    '8U',
    '12U',
    '24U',
  ];

  final GlobalKey<PopupMenuButtonState<SourceData>> sourcesPopupMenuButtonStateGlobalKey = GlobalKey<PopupMenuButtonState<SourceData>>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: <BoxShadow>[
          // Main drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24.0),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 2.0,
            ),
            child: BlocListener<ProjectViewModel, ProjectViewModelState>(
              listenWhen: (ProjectViewModelState previous, ProjectViewModelState current) => current is ToolbarModeChanged,
              listener: (BuildContext context, ProjectViewModelState state) {
                if (state is ToolbarModeChanged && state.mode == ToolbarMode.system) {
                  // Force SPL off when mode changes to system
                  widget.onSplDisabled();
                }
              },
              child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                builder: (BuildContext context, ProjectViewModelState state) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Mode Switch
                      _buildModeSwitch(),
                      const SizedBox(width: 12.0),

                      // Animated tool section with size transition
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
                                ),
                              ),
                              child: FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: animation,
                                  curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: _buildModeSpecificTools(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    final ToolbarMode currentMode = serviceLocator<ProjectViewModel>().currentToolbarMode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      padding: const EdgeInsets.all(2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GuideShowcaseWrapper(
            step: GuideShowCaseSteps.acousticMode,
            onHighlightedSpotTap: (TapDownDetails details) {
              _switchMode(ToolbarMode.acoustics);
              serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.acousticMode);
            },
            child: _buildModeTab(
              label: "Acoustics",
              isSelected: currentMode == ToolbarMode.acoustics,
              color: Colors.blue,
              onTap: () {
                _switchMode(ToolbarMode.acoustics);
              },
            ),
          ),
          GuideShowcaseWrapper(
            step: GuideShowCaseSteps.systemMode,
            onHighlightedSpotTap: (TapDownDetails details) {
              _switchMode(ToolbarMode.system);
              serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.systemMode);
            },
            child: _buildModeTab(
              label: "System",
              isSelected: currentMode == ToolbarMode.system,
              color: Colors.green,
              onTap: () {
                _switchMode(ToolbarMode.system);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, label),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
            border: isSelected ? Border.all(color: color.withValues(alpha: 0.3), width: 1.0) : null,
            boxShadow:
                isSelected
                    ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            style: TextStyle(
              color: isSelected ? _getDarkerShade(color) : Colors.black54,
              fontSize: 13.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: FusionAppText(text: label),
          ),
        ),
      ),
    );
  }

  Widget _buildToolItem(
    String tooltip, {
    String? assetIcon,
    IconData? icon,
    bool isSelected = false,
    required Function() onTap,
    Color? selectedColor,
  }) {
    final Color color = selectedColor ?? Colors.green;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, tooltip),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () {
            onTap();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child:
                icon != null
                    ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        icon,
                        size: 18.0,
                        color: isSelected ? _getDarkerShade(color) : Colors.black54,
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        assetIcon!,
                        width: 18.0,
                        height: 18.0,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSpecificTools() {
    final ToolbarMode currentMode = serviceLocator<ProjectViewModel>().currentToolbarMode;

    return Row(
      key: ValueKey<ToolbarMode>(currentMode),
      mainAxisSize: MainAxisSize.min,
      children: currentMode == ToolbarMode.acoustics ? _buildAcousticsTools() : _buildSystemTools(),
    );
  }

  List<Widget> _buildAcousticsTools() {
    final int currentDeviceIndex = serviceLocator<ProjectViewModel>().currentDeviceTypeIndex;

    return <Widget>[
      // if (serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode)
      GuideShowcaseWrapper(
        step: GuideShowCaseSteps.drawListeningArea,
        onHighlightedSpotTap: (TapDownDetails details) => _onAcousticsToolSelected(_AcousticsToolType.draw),
        child: _buildToolItem(
          icon: Icons.polyline,
          "Draw Listening Area",
          onTap: () => _onAcousticsToolSelected(_AcousticsToolType.draw),
          isSelected: widget.isDrawSelected,
          selectedColor: Colors.blue,
        ),
      ),
      // GuideShowcaseWrapper(
      //   step: GuideShowCaseSteps.selectSpeakersTool,
      //   onHighlightedSpotTap: (TapDownDetails details) => _onAcousticsToolSelected(_AcousticsToolType.speakers),
      //   child: _buildToolItem(
      //     icon: Icons.speaker,
      //     "Add Speakers",
      //     onTap: () => _onAcousticsToolSelected(_AcousticsToolType.speakers),
      //     isSelected: currentDeviceIndex == 0,
      //     selectedColor: Colors.blue,
      //   ),
      // ),
      _buildSplTool(),
      _buildToolItem(
        icon: Icons.fit_screen_rounded,
        "Fit to viewport",
        onTap: widget.onFitSelected,
      ),
      // _buildToolItem(
      //   assetIcon: Assets.tableIcon,
      //   "Floor Plan",
      //   onTap: widget.onEditFloorPlanSelected,
      // ),
    ];
  }

  List<Widget> _buildSystemTools() {
    final int currentDeviceIndex = serviceLocator<ProjectViewModel>().currentDeviceTypeIndex;
    final bool isListeningAreaSelected = serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId != null;

    return <Widget>[
      if (isListeningAreaSelected) ...<Widget>[
        _buildSourcesToolWithMenu(isSelected: currentDeviceIndex == 1),
        _buildToolItem(
          icon: Icons.spoke_outlined,
          "Add Endpoints",
          onTap: () {
            widget.onAddEndpointSelected();
            widget.onProductSelected(); // Expand products panel
          },
          isSelected: currentDeviceIndex == 2,
          selectedColor: Colors.green,
        ),
        _buildToolItem(
          icon: Icons.amp_stories,
          "Add Amplifiers",
          onTap: () {
            widget.onAddAmplifierSelected();
            widget.onProductSelected(); // Expand products panel
          },
          isSelected: currentDeviceIndex == 3,
          selectedColor: Colors.green,
        ),
        _buildToolItem(
          icon: Icons.memory,
          "Add DSPs",
          onTap: () {
            widget.onAddDspSelected();
            widget.onProductSelected(); // Expand products panel
          },
          isSelected: currentDeviceIndex == 4,
          selectedColor: Colors.green,
        ),
        _buildToolItem(
          icon: Icons.tune,
          "Add Controllers",
          onTap: () {
            widget.onAddControllerSelected();
            widget.onProductSelected(); // Expand products panel
          },
          isSelected: currentDeviceIndex == 5,
          selectedColor: Colors.green,
        ),
        _buildRackToolWithMenu(
          isSelected: currentDeviceIndex == 6,
        ),
      ],
      _buildToolItem(
        icon: Icons.fit_screen_rounded,
        "Fit to viewport",
        onTap: widget.onFitSelected,
      ),
    ];
  }

  Widget _buildSourcesToolWithMenu({required bool isSelected}) {
    return GuideShowcaseWrapper(
      step: GuideShowCaseSteps.systemModeTabs,
      onHighlightedSpotTap: (TapDownDetails value) {
        sourcesPopupMenuButtonStateGlobalKey.currentState?.showButtonMenu();
      },
      child: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "add_sources"),
        child: AddSourcePopup(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Tooltip(
              message: "Add Sources",
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Icon(
                  Icons.mic,
                  size: 18.0,
                  color: isSelected ? _getDarkerShade(Colors.green) : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRackToolWithMenu({required bool isSelected}) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "add_racks"),
      child: PopupMenuButton<DeviceItemModel>(
        onSelected: (DeviceItemModel selectedItem) {
          // Set device type index first
          serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(6); // Rack index

          // Create product and set for addition
          final ProductQueryModel product = ProductQueryModel(
            name: selectedItem.name,
            price: 0.0,
            image: selectedItem.image,
            type: ProductType.racks,
            sku: selectedItem.sku,
          );
          serviceLocator<ProjectViewModel>().setSelectedProductToAdd(product);
        },
        constraints: const BoxConstraints(
          maxHeight: 500,
          maxWidth: 320,
        ),
        color: Colors.white,
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<DeviceItemModel>>[
            const PopupMenuItem<DeviceItemModel>(
              enabled: false,
              child: FusionAppText(
                text: 'RACK OPTIONS',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
              ),
            ),
            ..._rackOptions.map(
              (String option) => PopupMenuItem<DeviceItemModel>(
                height: 30,
                value: DeviceItemModel(
                  sku: option.toLowerCase(),
                  name: '$option Rack',
                  image: 'assets/images/products/rack.png',
                ),
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/images/products/rack.png',
                      height: 14,
                      width: 14,
                    ),
                    const SizedBox(width: 8),
                    FusionAppText(text: '$option Rack'),
                  ],
                ),
              ),
            ),
          ];
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Tooltip(
            message: "Add Racks",
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                Icons.dns_outlined,
                size: 18.0,
                color: isSelected ? _getDarkerShade(Colors.green) : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplTool() {
    return _buildToolItem(
      icon: Icons.graphic_eq,
      "Show SPL",
      onTap: () => _onAcousticsToolSelected(_AcousticsToolType.spl),
      isSelected: widget.isSplSelected,
      selectedColor: Colors.blue,
    );
  }

  void _onAcousticsToolSelected(_AcousticsToolType toolType) {
    final int currentDeviceIndex = serviceLocator<ProjectViewModel>().currentDeviceTypeIndex;

    switch (toolType) {
      case _AcousticsToolType.draw:
        // Toggle draw - if already selected, deselect; otherwise select
        if (widget.isDrawSelected) {
          widget.onDrawingDisabled();
        } else {
          // Always deselect other tools first when enabling draw
          if (widget.isSplSelected) {
            widget.onSplDisabled();
          }
          if (currentDeviceIndex == 0) {
            serviceLocator<ProjectViewModel>().resetDeviceTypeIndex();
            serviceLocator<ProductQueryCubit>().onProductTypeChanged(null);
            //close products panel
            widget.onProductDeselected();
          }
          widget.onDrawSelected();
        }

        break;

      case _AcousticsToolType.speakers:
        // Always deselect other tools first
        if (widget.isSplSelected) {
          widget.onSplDisabled();
        }
        if (widget.isDrawSelected) {
          widget.onDrawingDisabled();
        }

        // Toggle speakers - if already selected, deselect; otherwise select
        if (currentDeviceIndex == 0) {
          serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(-1);
        } else {
          widget.onAddSpeakerSelected();
          widget.onProductSelected();
        }

        serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.selectSpeakersTool);
        break;

      case _AcousticsToolType.spl:
        // Always deselect other tools first
        if (currentDeviceIndex == 0) {
          // Reset device selection to deselect speakers
          serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(-1);
        }
        if (widget.isDrawSelected) {
          widget.onDrawingDisabled();
        }

        // Toggle SPL - if already selected, deselect; otherwise select
        if (widget.isSplSelected) {
          widget.onSplDisabled();
        } else {
          widget.onSplSelected();
        }
        break;
    }
  }

  void _switchMode(ToolbarMode newMode) {
    final ToolbarMode currentMode = serviceLocator<ProjectViewModel>().currentToolbarMode;

    if (currentMode != newMode) {
      // Deselect any currently selected hardware component or listening area when switching modes
      serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
      serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);

      // Always force SPL off when switching to system mode
      // This is more robust than checking isSplSelected which might be stale
      if (newMode == ToolbarMode.system) {
        widget.onSplDisabled();
      }

      serviceLocator<ProjectViewModel>().setToolbarMode(newMode);
    }
  }

  Color _getDarkerShade(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
  }
}
