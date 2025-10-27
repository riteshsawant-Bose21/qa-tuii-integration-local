import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_utils/image_loader_service.dart';

import '../../../../core/widgets/clean_widgets.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'toolbar/building_toolbar.dart';

class BuildingCanvas extends StatefulWidget {
  final SplRangeController? splRangeController;
  final Function(bool isShowing) onSplStateChanged;
  final FloorCanvasController floorCanvasController;
  final Future<void> Function() onCalculateSpl;
  final SplPanelData splPanelData;
  final Function() onProductSelected;

  const BuildingCanvas({
    super.key,
    this.splRangeController,
    required this.onSplStateChanged,
    required this.floorCanvasController,
    required this.onCalculateSpl,
    required this.splPanelData,
    required this.onProductSelected,
  });

  @override
  State<BuildingCanvas> createState() => _BuildingCanvasState();
}

class _BuildingCanvasState extends State<BuildingCanvas> {
  Offset viewPortCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void zoneSelectionMode(Zone zone) async {
    final List<ListeningArea>? selectedAreas = await widget.floorCanvasController.requestListeningAreaSelection(
      serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: zone.id),
      zone,
    );

    if (selectedAreas != null) {
      serviceLocator<ProjectViewModel>().updateListeningAreasInZone(
        zoneId: zone.id,
        listeningAreaIds: selectedAreas.map((ListeningArea e) => e.id).toList(),
      );
    } else {
      serviceLocator<ProjectViewModel>().clearSelectedZone();
    }
  }

  Offset? cursorPosition;

  bool isCustomCursorNeeded() {
    return serviceLocator<ProjectViewModel>().selectedProductToAdd != null;
    // ||
    // serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode ||
    // serviceLocator<ProjectViewModel>().isInZoneSelectionMode;
  }

  Widget getCustomCursor() {
    if (serviceLocator<ProjectViewModel>().selectedProductToAdd != null) {
      return Image.asset(
        serviceLocator<ProjectViewModel>().selectedProductToAdd!.image, // Your asset icon path
        width: 32,
        height: 32,
      );
    }
    // else if (serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode) {
    //   return Icon(
    //     Icons.edit,
    //     size: 20,
    //     color: Theme.of(context).colorScheme.primary,
    //   );
    // } else if (serviceLocator<ProjectViewModel>().isInZoneSelectionMode) {
    //   return Icon(
    //     Icons.layers,
    //     size: 20,
    //     color: Theme.of(context).colorScheme.primary,
    //   );
    // }
    else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FusionKeyboardWrapper(
      onUndo: () {
        if (serviceLocator<ProjectViewModel>().canUndo) {
          serviceLocator<ProjectViewModel>().undo();
        }
      },
      onRedo: () {
        if (serviceLocator<ProjectViewModel>().canRedo) {
          serviceLocator<ProjectViewModel>().redo();
        }
      },
      onDelete: () {
        //IN Building page
        if (serviceLocator<ProjectViewModel>().currentSelectedHardwareId != null) {
          serviceLocator<ProjectViewModel>().removeHardware(hardwareId: serviceLocator<ProjectViewModel>().currentSelectedHardwareId!);
        } else if (serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId != null) {
          serviceLocator<ProjectViewModel>().removeListeningArea(areaId: serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          // borderRadius: BorderRadius.circular(6),
          // border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: <Widget>[
            // Canvas with floor plan and components
            Expanded(
              child: Stack(
                children: <Widget>[
                  // Main canvas area
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
                    child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                      listener: (BuildContext context, ProjectViewModelState state) {
                        // if (state is FloorsUpdated) {
                        //   onFloorUpdated();
                        // }
                      },
                      builder: (BuildContext context, ProjectViewModelState state) {
                        final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
                        final FloorModel floor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];

                        /// If no floor plan image,
                        /// show upload floor plan widget
                        if (floor.floorPlan.imagePath.isEmpty) {
                          return _buildEmptyFloorWidget();
                        }

                        return ValueListenableBuilder<bool>(
                          valueListenable: widget.floorCanvasController.isDrawing,
                          builder: (BuildContext context, bool isDrawingValue, Widget? child) {
                            final bool useCustomCursor = isCustomCursorNeeded();
                            return Stack(
                              children: <Widget>[
                                MouseRegion(
                                  cursor:
                                      widget.floorCanvasController.isDrawing.value
                                          ? SystemMouseCursors.precise
                                          : (serviceLocator<ProjectViewModel>().selectedProductToAdd != null
                                              ? SystemMouseCursors.none
                                              : SystemMouseCursors.basic),
                                  onHover: (PointerHoverEvent event) {
                                    setState(() {
                                      cursorPosition = event.localPosition;
                                    });
                                  },
                                  onExit: (PointerExitEvent event) {
                                    setState(() {
                                      cursorPosition = null;
                                    });
                                  },
                                  child: FloorCanvas(
                                    gridSize: 100,
                                    controller: widget.floorCanvasController,
                                    hardwareComponents: serviceLocator<ProjectViewModel>().getHardwareForFloor(floorId: floor.id),
                                    listeningAreas: serviceLocator<ProjectViewModel>().getListeningAreasForFloor(floorId: floor.id),
                                    floor: floor,
                                    floorPlanEntity: floor.floorPlan,
                                    selectedHardwareId: serviceLocator<ProjectViewModel>().currentSelectedHardwareId,
                                    selectedListeningAreaId: serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId,
                                    onUpdateHardwareComponent: (HardwareComponent updatedHw) {
                                      final HardwareComponent oldHw = serviceLocator<ProjectViewModel>().getHardware(hardwareId: updatedHw.id)!;

                                      //check for pos && listening area id since only those two can be updated from canvas
                                      if (oldHw.pos != updatedHw.pos ||
                                          oldHw.locationEntity.listeningAreaId != updatedHw.locationEntity.listeningAreaId ||
                                          oldHw.locationEntity.floorId != updatedHw.locationEntity.floorId) {
                                        serviceLocator<ProjectViewModel>().updateHardware(hardware: updatedHw);
                                      } else {
                                        debugPrint("No changes detected for hardware ${updatedHw.id}, skipping update.");
                                      }
                                    },
                                    zones: serviceLocator<ProjectViewModel>().zones,
                                    splPanelData: widget.splPanelData,
                                    onCanvasZoomChanged: (double z) {
                                      serviceLocator<ProjectViewModel>().updateFloor(
                                        floor: floor.copyWith(floorPlan: floor.floorPlan.copyWith(canvasZoom: z)),
                                      );
                                    },
                                    onCanvasPanChanged: (ui.Offset p) {
                                      serviceLocator<ProjectViewModel>().updateFloor(
                                        floor: floor.copyWith(floorPlan: floor.floorPlan.copyWith(canvasPan: p)),
                                      );
                                    },
                                    moveHardware: (HardwareComponent hardware, String? newListeningAreaId, String? floorId) {
                                      serviceLocator<ProjectViewModel>().moveHardware(
                                        hardwareId: hardware.id,
                                        floorId: floorId,
                                        listeningAreaId: newListeningAreaId,
                                      );
                                      // serviceLocator<ProjectViewModel>().saveProjectToLocal();
                                    },
                                    onAddListeningArea: (ListeningArea created, List<HardwareComponent>? containedHardware) {
                                      serviceLocator<ProjectViewModel>().recordSnapshot();
                                      serviceLocator<ProjectViewModel>().addListeningArea(area: created, floorId: floor.id, autoSave: false);
                                      if (containedHardware != null) {
                                        for (final HardwareComponent hc in containedHardware) {
                                          serviceLocator<ProjectViewModel>().moveHardware(
                                            hardwareId: hc.id,
                                            listeningAreaId: created.id,
                                            floorId: floor.id,
                                            autoSave: false,
                                          );
                                        }
                                      }
                                      widget.onCalculateSpl();
                                      serviceLocator<ProjectViewModel>().saveProject();
                                    },
                                    onUpdateListeningArea: (ListeningArea area) {
                                      serviceLocator<ProjectViewModel>().updateListeningArea(area: area);
                                    },
                                    onFloorPlanUpdated: (FloorPlanModel updatedPlan) {
                                      serviceLocator<ProjectViewModel>().updateFloor(
                                        floor: floor.copyWith(floorPlan: updatedPlan),
                                      );
                                    },
                                    onViewportCenterUpdated: (ui.Offset center) {
                                      viewPortCenter = center;
                                    },
                                    onComponentTransformed: (dynamic component) {
                                      if (component is Speaker || component is ListeningArea) {
                                        widget.onCalculateSpl();
                                      }
                                    },
                                    onTapListeningArea: (ListeningArea value) {
                                      // serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(value.id);
                                    },
                                    onSelectedListeningAreaIdChanged: (String? value) {
                                      serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(value);
                                      serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
                                    },
                                    onSelectedHardwareComponentIdChanged: (String? value) {
                                      serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(value);
                                      serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
                                    },
                                    onSelectedFloorPlanIdChanged: () {
                                      serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
                                      serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
                                    },
                                    splMin: serviceLocator<ProjectViewModel>().minSPL,
                                    splMax: serviceLocator<ProjectViewModel>().maxSPL,
                                    addNewHardwareComponent: (Offset speakerPosition, String? listeningAreaId) {
                                      if (serviceLocator<ProjectViewModel>().selectedProductToAdd == null) {
                                        debugPrint("No product selected to add");
                                        return;
                                      }
                                      serviceLocator<ProjectViewModel>().addSelectedProduct(
                                        position: speakerPosition,
                                        listeningAreaId: listeningAreaId,
                                      );
                                    },
                                    listeningAreaToZoneMap: serviceLocator<ProjectViewModel>().getListeningAreaToZoneMap(),
                                  ),
                                ),

                                if (useCustomCursor && cursorPosition != null)
                                  Positioned(
                                    left: cursorPosition!.dx - 12,
                                    top: cursorPosition!.dy - 12,
                                    child: IgnorePointer(
                                      child: getCustomCursor(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Clean floating toolbar
                  BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                    listener: (BuildContext context, ProjectViewModelState state) {
                      if (state is ZoneSelectionMode) {
                        //Create new zone
                        final Zone zone = state.zone;
                        zoneSelectionMode(zone);
                      }

                      if (state is ListeningAreaSelectionMode) {
                        widget.floorCanvasController.toggleDraw();
                      }

                      if (!serviceLocator<ProjectViewModel>().isInListeningAreaSelectionMode && widget.floorCanvasController.isDrawing.value) {
                        widget.floorCanvasController.toggleDraw();
                      }

                      if (!serviceLocator<ProjectViewModel>().isInZoneSelectionMode && widget.floorCanvasController.isListeningAreaSelectionActive.value) {
                        widget.floorCanvasController.cancelListeningAreaSelection();
                      }
                    },
                    builder: (BuildContext context, ProjectViewModelState state) {
                      final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
                      final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];
                      return Visibility(
                        visible: currentFloor.floorPlan.imagePath.isNotEmpty || currentFloor.floorPlan.imagePath != "" ? true : false,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: widget.floorCanvasController.isListeningAreaSelectionActive,
                              builder: (_, bool isActive, __) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isActive
                                            ? FusionUiUtils.hexToColor(widget.floorCanvasController.currentlySelectingZone!.zoneColor).withValues(alpha: 0.75)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black.withAlpha((0.1 * 255).toInt()),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Builder(
                                    builder: (BuildContext context) {
                                      if (isActive) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Text(
                                              'Select listening areas for ${widget.floorCanvasController.currentlySelectingZone!.name}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    ThemeData.estimateBrightnessForColor(
                                                              FusionUiUtils.hexToColor(widget.floorCanvasController.currentlySelectingZone!.zoneColor),
                                                            ) ==
                                                            Brightness.light
                                                        ? Colors.grey.shade800
                                                        : Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            InkWell(
                                              onTap: () {
                                                serviceLocator<ProjectViewModel>().clearSelectedZone();
                                                widget.floorCanvasController.cancelListeningAreaSelection();
                                              },
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color:
                                                        ThemeData.estimateBrightnessForColor(
                                                                  FusionUiUtils.hexToColor(widget.floorCanvasController.currentlySelectingZone!.zoneColor),
                                                                ) ==
                                                                Brightness.light
                                                            ? Colors.grey.shade800
                                                            : Colors.white,
                                                    width: 1,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),

                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color:
                                                      ThemeData.estimateBrightnessForColor(
                                                                FusionUiUtils.hexToColor(widget.floorCanvasController.currentlySelectingZone!.zoneColor),
                                                              ) ==
                                                              Brightness.light
                                                          ? Colors.grey.shade800
                                                          : Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            InkWell(
                                              onTap: () {
                                                serviceLocator<ProjectViewModel>().clearSelectedZone();
                                                widget.floorCanvasController.completeListeningAreaSelection();
                                              },
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color:
                                                        ThemeData.estimateBrightnessForColor(
                                                                  FusionUiUtils.hexToColor(widget.floorCanvasController.currentlySelectingZone!.zoneColor),
                                                                ) ==
                                                                Brightness.light
                                                            ? Colors.grey.shade800
                                                            : Colors.white,
                                                    width: 1,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color:
                                                      ThemeData.estimateBrightnessForColor(
                                                                FusionUiUtils.hexToColor(widget.floorCanvasController.currentlySelectingZone!.zoneColor),
                                                              ) ==
                                                              Brightness.light
                                                          ? Colors.grey.shade800
                                                          : Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: widget.floorCanvasController.isDrawing,
                                        builder: (_, bool isDrawing, __) {
                                          return BuildingToolbar(
                                            onSplSelected: () {
                                              widget.floorCanvasController.toggleSpl();
                                              widget.onCalculateSpl();
                                              widget.onSplStateChanged(widget.floorCanvasController.isShowingSpl.value);
                                            },
                                            onPanSelected: () {},
                                            onMoveSelected: () {},
                                            onPencilSelected: () {
                                              widget.floorCanvasController.toggleDraw();
                                            },
                                            onEditFloorPlanSelected: _showFloorPlanPicker,
                                            onTrashSelected: () {},
                                            onFitSelected: () {
                                              widget.floorCanvasController.fitToView();
                                            },
                                            onAddSpeakerSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(0); // DeviceType.speakers
                                            },
                                            onAddSourceSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(1); // DeviceType.sources
                                            },
                                            onAddEndpointSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(2); // DeviceType.endpoints
                                            },
                                            onAddAmplifierSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(3); // DeviceType.amplifiers
                                            },
                                            onAddDspSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(4); // DeviceType.dsp
                                            },
                                            onAddControllerSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(5); // DeviceType.controllers
                                            },
                                            onAddRackSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(6); // DeviceType.rack
                                            },
                                            onProductSelected: widget.onProductSelected,
                                            isPencilSelected: isDrawing,
                                            isSplSelected: widget.floorCanvasController.isShowingSpl.value,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  //SPL range slider
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.floorCanvasController.isShowingSpl,
                    builder: (_, bool isShowingSpl, __) {
                      if (!isShowingSpl) {
                        return const SizedBox.shrink();
                      }
                      return LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: SPLRangeSlider(
                              width: 24,
                              height: constraints.maxHeight,
                              controller: widget.splRangeController,
                              minValue: serviceLocator<ProjectViewModel>().minSPL,
                              maxValue: serviceLocator<ProjectViewModel>().maxSPL,
                              invertedColors: widget.splPanelData.splInvertColor,
                              onChanged: (double min, double max) {
                                // debugPrint("SPL Range changed: ${min.round()} - ${max.round()}");
                                serviceLocator<ProjectViewModel>().setMinSPL(minSPL: min, autoSave: false);
                                serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: max);
                              },
                              onChangeEnd: (double min, double max) {
                                // debugPrint("SPL Range change ended: ${min.round()} - ${max.round()}");
                                serviceLocator<ProjectViewModel>().setMinSPL(minSPL: min, autoSave: false);
                                serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: max);
                                // serviceLocator<ProjectViewModel>().saveProjectToLocal();
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFloorWidget() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            /// icon
            const FusionImage.asset(
              "assets/images/upload_floor_plan.png",
              width: 64,
              height: 64,
            ),

            const SizedBox(height: 24),

            /// Title
            FusionAppText(
              text: "Getting Started",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            /// Subtitle
            FusionAppText(
              text: "Start with a pre-built structure.\nChoose how you want to shape your sound space.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 28),

            /// Upload Button
            FusionOutlinedButton(
              height: 32,
              width: 160,
              label: "Upload Floor-plan",
              textStyle: Theme.of(context).textTheme.titleSmall,
              onTap: () {
                _showFloorPlanPicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFloorPlanPicker() async {
    final List<String> plans = <String>[
      "assets/images/floor_plans/floor_plan_1.png",
      "assets/images/floor_plans/floor_plan_2.png",
      "assets/images/floor_plans/floor_plan_gym.png",
      "assets/images/floor_plans/demo_plan_gym.jpg",
    ];

    await showDialog(
      context: context,
      builder:
          (BuildContext ctx) => CleanDialog(
            title: 'Select Floor Plan',
            actions: <Widget>[
              TextButton(
                onPressed: () => _importFloorPlan(),
                child: Text(
                  'Import',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            ],
            child: SizedBox(
              width: 400,
              height: 300,
              child: ListView.builder(
                itemCount: plans.length,
                itemBuilder: (_, int i) {
                  final String planPath = plans[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _buildFloorPlanImage(planPath),
                      ),
                      title: Text(
                        planPath.split('/').last,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: () => _selectAssetFloorPlan(planPath),
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }

  Widget _buildFloorPlanImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(imagePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey.shade300,
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey.shade600,
              size: 30,
            ),
          );
        },
      );
    }
  }

  Future<void> _selectAssetFloorPlan(String assetImagePath) async {
    if (mounted) Navigator.of(context).pop();
    final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addAssetImageToProject(assetPath: assetImagePath);
    if (responseCallback.success && responseCallback.data != null) {
      final String savedImagePath = responseCallback.data!;
      _calibrateFloorPlan(savedImagePath);
    }
  }

  Future<void> _importFloorPlan() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
      );

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: <String>['png', 'jpg', 'jpeg'],
      );

      if (mounted) Navigator.of(context).pop();

      if (result != null && result.files.single.path != null) {
        final String sourcePath = result.files.single.path!;
        final String fileName = result.files.single.name;
        final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(imagePath: sourcePath);
        if (responseCallback.success && responseCallback.data != null) {
          final String savedImagePath = responseCallback.data!;
          _calibrateFloorPlan(savedImagePath);
        }

        if (mounted) Navigator.of(context).pop();
        debugPrint('Floor plan imported successfully: $fileName');
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('Error importing floor plan: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing floor plan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _calibrateFloorPlan(String savedImagePath) async {
    try {
      final ui.Image image = await serviceLocator<ImageLoaderService>().loadImage(savedImagePath);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (BuildContext context) => const Center(
              child: CircularProgressIndicator(),
            ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      final CalibrationData? calibrationData = await showDialog<CalibrationData>(
        context: context,
        barrierDismissible: true,
        builder:
            (BuildContext context) => Dialog(
              child: FloorPlanCalibrationDialog(
                floorPlanImage: image,
                onCalibrationComplete: (CalibrationData data) {
                  if (mounted) {
                    Navigator.of(context).pop(data);
                  }
                },
                onCancel: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
      );

      if (calibrationData != null) {
        debugPrint('Calibration completed: $calibrationData');
        debugPrint('Scale: ${calibrationData.pixelsPerUnit.toStringAsFixed(2)} pixels per ${calibrationData.unit.symbol}');

        const double canvasPixelsPerMeter = 100.0;

        //get current floor
        final int floorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
        final FloorModel floor = serviceLocator<ProjectViewModel>().floors[floorIndex];

        // Use cropped image if available, otherwise use original
        final ui.Image imageToUse = calibrationData.croppedImage ?? image;

        final double widthInUnits = imageToUse.width * calibrationData.unitsPerPixel;
        final double heightInUnits = imageToUse.height * calibrationData.unitsPerPixel;

        double widthInMeters = widthInUnits;
        double heightInMeters = heightInUnits;

        switch (calibrationData.unit) {
          case MeasurementUnit.meters:
            break;
          case MeasurementUnit.feet:
            widthInMeters = widthInUnits * 0.3048;
            heightInMeters = heightInUnits * 0.3048;
            break;
          case MeasurementUnit.centimeters:
            widthInMeters = widthInUnits * 0.01;
            heightInMeters = heightInUnits * 0.01;
            break;
          case MeasurementUnit.inches:
            widthInMeters = widthInUnits * 0.0254;
            heightInMeters = heightInUnits * 0.0254;
            break;
        }

        final double canvasWidthInPixels = widthInMeters * canvasPixelsPerMeter;
        final double canvasHeightInPixels = heightInMeters * canvasPixelsPerMeter;
        final Size floorPlanSize = Size(canvasWidthInPixels, canvasHeightInPixels);

        debugPrint('Real-world dimensions: ${widthInMeters.toStringAsFixed(2)}m x ${heightInMeters.toStringAsFixed(2)}m');
        debugPrint('Canvas dimensions: ${canvasWidthInPixels.toStringAsFixed(1)}px x ${canvasHeightInPixels.toStringAsFixed(1)}px');

        // If we have a cropped image, save it and use it instead of the original
        String imagePathToUse = savedImagePath;
        if (calibrationData.croppedImage != null) {
          // Save the cropped image
          final String croppedImagePath = await _saveCroppedImage(calibrationData.croppedImage!, savedImagePath);
          imagePathToUse = croppedImagePath;
        }

        serviceLocator<ProjectViewModel>().updateFloor(
          floor: floor.copyWith(
            floorPlan: floor.floorPlan.copyWith(
              imagePath: imagePathToUse,
              position: floor.floorPlan.imagePath.isNotEmpty ? floor.floorPlan.position : viewPortCenter,
              size: floorPlanSize,
            ),
          ),
        );

        widget.floorCanvasController.loadFloorPlanImage();
      } else {
        debugPrint('Calibration cancelled by user');
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      debugPrint('Error during calibration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error during calibration: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<String> _saveCroppedImage(ui.Image croppedImage, String originalImagePath) async {
    // Convert the cropped image to byte data
    final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to convert cropped image to byte data.');

    // Create a temporary file to save the cropped image
    final String tempFileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.png';
    final String tempPath = '${Directory.systemTemp.path}/$tempFileName';

    // Write the byte data to the temporary file first
    final File tempFile = File(tempPath);
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

    debugPrint('Cropped image temporarily saved to: $tempPath');

    // Now use the project's image management system to properly store it
    final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(imagePath: tempPath);

    // Clean up the temporary file
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint('Warning: Could not delete temporary file: $e');
    }

    if (responseCallback.success && responseCallback.data != null) {
      final String savedCroppedImagePath = responseCallback.data!;
      debugPrint('Cropped image properly saved to: $savedCroppedImagePath');
      return savedCroppedImagePath;
    } else {
      throw Exception('Failed to save cropped image to project storage');
    }
  }
}
