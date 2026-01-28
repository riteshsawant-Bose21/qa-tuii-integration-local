import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/constants/test_keys.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_utils/image_loader_service.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'toolbar/building_toolbar.dart';

class BuildingCanvas extends StatefulWidget {
  final SplRangeController? splRangeController;
  final Function(bool isShowing) onSplStateChanged;
  final FloorCanvasController floorCanvasController;
  final Future<void> Function() onCalculateSpl;
  final SplPanelData splPanelData;
  final Function() onProductSelected;
  final Function() onProductDeselected;

  const BuildingCanvas({
    super.key,
    this.splRangeController,
    required this.onSplStateChanged,
    required this.floorCanvasController,
    required this.onCalculateSpl,
    required this.splPanelData,
    required this.onProductSelected,
    required this.onProductDeselected,
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
      print("Selected areas for zone ${zone.name}: ${selectedAreas.map((ListeningArea e) => e.name).toList()}");
      serviceLocator<ProjectViewModel>().updateListeningAreasInZone(
        zoneId: zone.id,
        listeningAreaIds: selectedAreas.map((ListeningArea e) => e.id).toList(),
      );
    } else {
      serviceLocator<ProjectViewModel>().clearSelectedZone();
    }
  }

  void subzoneSelectionMode(SubZone subZone) async {
    final List<ListeningArea>? selectedAreas = await widget.floorCanvasController.requestListeningAreaSelectionForSubZone(
      serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: subZone.id),
      subZone,
    );

    if (selectedAreas != null) {
      print("Selected areas for subzone ${subZone.name}: ${selectedAreas.map((ListeningArea e) => e.name).toList()}");
      serviceLocator<ProjectViewModel>().updateListeningAreasInSubZone(
        subZoneId: subZone.id,
        listeningAreaIds: selectedAreas.map((ListeningArea e) => e.id).toList(),
      );
    } else {
      serviceLocator<ProjectViewModel>().clearSelectedSubZone();
    }
  }

  Offset? cursorPosition;

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  bool get shouldUseCustomCursor => projectViewModel.selectedProductToAdd != null || projectViewModel.shouldPlaceNonPlacedSpeakers;

  MouseCursor get cursorType {
    if (widget.floorCanvasController.isDrawing.value) {
      return SystemMouseCursors.precise;
    } else if (projectViewModel.selectedProductToAdd != null || projectViewModel.shouldPlaceNonPlacedSpeakers) {
      return SystemMouseCursors.none;
    } else {
      return SystemMouseCursors.basic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FusionKeyboardWrapper(
      onUndo: () {
        // if (serviceLocator<ProjectViewModel>().canUndo) {
        //   serviceLocator<ProjectViewModel>().undo();
        // }
      },
      onRedo: () {
        // if (serviceLocator<ProjectViewModel>().canRedo) {
        //   serviceLocator<ProjectViewModel>().redo();
        // }
      },
      onDelete: () {
        //IN Building page
        if (serviceLocator<ProjectViewModel>().currentSelectedHardwareId != null) {
          serviceLocator<ProjectViewModel>().removeHardware(
            hardwareId: serviceLocator<ProjectViewModel>().currentSelectedHardwareId!,
          );
        } else if (serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId != null) {
          serviceLocator<ProjectViewModel>().removeListeningArea(
            areaId: serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId!,
          );
        }
        widget.onCalculateSpl();
      },
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
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
                            return Stack(
                              children: <Widget>[
                                MouseRegion(
                                  cursor: cursorType,
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
                                  child: GuideShowcaseWrapper(
                                    step: GuideShowCaseSteps.showListeningAreaSelectionArea,
                                    child: SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "building_floor_canvas"),
                                      child: FloorCanvas(
                                        gridSize: 100,
                                        controller: widget.floorCanvasController,
                                        hardwareComponents: serviceLocator<ProjectViewModel>().getHardwareInFloorWithPosition(
                                          floorId: floor.id,
                                        ),
                                        listeningAreas: serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
                                          floorId: floor.id,
                                        ),
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
                                            debugPrint(
                                              "No changes detected for hardware ${updatedHw.id}, skipping update.",
                                            );
                                          }
                                        },
                                        zones: serviceLocator<ProjectViewModel>().zones,
                                        subZones: serviceLocator<ProjectViewModel>().subZones,
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
                                        onRightClick: (PointerDownEvent e) {
                                          if (widget.floorCanvasController.isDrawing.value) {
                                            widget.floorCanvasController.toggleDraw();
                                          }
                                          if (projectViewModel.shouldPlaceNonPlacedSpeakers) {
                                            projectViewModel.setShouldPlaceNonPlacedSpeakers(false);
                                          }
                                        },
                                        moveHardware: (
                                          HardwareComponent hardware,
                                          String? newListeningAreaId,
                                          String? floorId,
                                        ) {
                                          serviceLocator<ProjectViewModel>().moveHardware(
                                            hardwareId: hardware.id,
                                            floorId: floorId,
                                            listeningAreaId: newListeningAreaId,
                                          );
                                          // serviceLocator<ProjectViewModel>().saveProjectToLocal();
                                        },
                                        onAddListeningArea: (
                                          ListeningArea created,
                                          List<HardwareComponent>? containedHardware,
                                        ) {
                                          serviceLocator<ProjectViewModel>().recordSnapshot();
                                          serviceLocator<ProjectViewModel>().addListeningArea(
                                            area: created,
                                            floorId: floor.id,
                                            autoSave: false,
                                          );
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
                                          serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.drawListeningArea);
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
                                          serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(value.id);
                                          serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.showListeningAreaSelectionArea);
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
                                        addNewHardwareComponent: (Offset speakerPosition) {
                                          final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

                                          if (projectViewModel.shouldPlaceNonPlacedSpeakers) {
                                            projectViewModel.placeSelectedSpeaker(position: speakerPosition, isFromBuildingPage: true);
                                          }
                                          // else {
                                          //   if (projectViewModel.selectedProductToAdd == null) return;
                                          //   projectViewModel.addSelectedProduct(
                                          //     position: speakerPosition,
                                          //     listeningAreaId: listeningAreaId,
                                          //     isFromBuildingPage: true,
                                          //   );
                                          // }

                                          serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.addSpeakers);

                                          if (serviceLocator<GuideShowCaseController>().isStepCompleted(GuideShowCaseSteps.systemMode)) {
                                            serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.systemModeTabs);
                                          }
                                          widget.onCalculateSpl();
                                        },
                                        listeningAreaToZoneMap: serviceLocator<ProjectViewModel>().getListeningAreaToZoneMap(),
                                        subZoneToZoneMap: serviceLocator<ProjectViewModel>().getSubZoneToZoneMap(),
                                        listeningAreaToSubZoneMap: serviceLocator<ProjectViewModel>().getListeningAreaToSubZoneMap(),
                                        isAcousticsMode: serviceLocator<ProjectViewModel>().currentToolbarMode == ToolbarMode.acoustics,
                                        isInSpeakerPlacementMode: projectViewModel.shouldPlaceNonPlacedSpeakers,
                                      ),
                                    ),
                                  ),
                                ),

                                if (shouldUseCustomCursor && cursorPosition != null) ...<Widget>[
                                  Positioned(
                                    left: cursorPosition!.dx - 12,
                                    top: cursorPosition!.dy - 12,
                                    child: IgnorePointer(
                                      child: Builder(
                                        builder: (BuildContext context) {
                                          if (serviceLocator<ProjectViewModel>().shouldPlaceNonPlacedSpeakers) {
                                            final List<Speaker> nonPlacedSpeakers = projectViewModel.getNonPlacedSpeakersForCurrentListeningArea();

                                            if (nonPlacedSpeakers.isEmpty) return const SizedBox();

                                            final MountingType? speakerMountType = nonPlacedSpeakers.first.mountingType;

                                            return Stack(
                                              clipBehavior: Clip.none,
                                              children: <Widget>[
                                                Builder(
                                                  builder: (BuildContext context) {
                                                    if (speakerMountType == MountingType.surface) {
                                                      return const RotatedBox(
                                                        quarterTurns: 1,
                                                        child: Icon(
                                                          Icons.rectangle,
                                                          size: 32,
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    } else if (speakerMountType == MountingType.pendant) {
                                                      return SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CustomPaint(
                                                          painter: TrianglePainter(
                                                            color: Colors.black,
                                                            isUp: true,
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      return const Icon(
                                                        Icons.circle,
                                                        size: 32,
                                                        color: Colors.black,
                                                      );
                                                    }
                                                  },
                                                ),
                                                Positioned(
                                                  bottom: -10,
                                                  right: -10,
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: Colors.black,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: const EdgeInsets.all(5),
                                                    child: FusionAppText(
                                                      text: '${nonPlacedSpeakers.length}',
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                        color: context.colorScheme.onPrimary,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else if (serviceLocator<ProjectViewModel>().selectedProductToAdd != null) {
                                            return Image.asset(
                                              serviceLocator<ProjectViewModel>().selectedProductToAdd!.image,
                                              width: 32,
                                              height: 32,
                                            );
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
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

                      if (state is SubZoneSelectionMode) {
                        //Create new subzone
                        final SubZone subZone = state.subZone;
                        subzoneSelectionMode(subZone);
                      }

                      if (state is ListeningAreaSelectionMode) {
                        widget.floorCanvasController.setDraw(true);
                      }

                      if (serviceLocator<ProjectViewModel>().currentToolbarMode == ToolbarMode.system &&
                          !serviceLocator<ProjectViewModel>().isInListeningAreaMode &&
                          widget.floorCanvasController.isDrawing.value) {
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
                              builder: (_, bool isListeningAreaSelectionActive, __) {
                                if (isListeningAreaSelectionActive) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: serviceLocator<ProjectViewModel>().getCurrentSelectionZoneColor(),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        FusionAppText(
                                          text: 'Select listening areas for ${serviceLocator<ProjectViewModel>().getCurrentSelectionZoneName()}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                ThemeData.estimateBrightnessForColor(
                                                          serviceLocator<ProjectViewModel>().getCurrentSelectionZoneColor(),
                                                        ) ==
                                                        Brightness.light
                                                    ? Colors.grey.shade800
                                                    : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SemanticHelper.button(
                                          testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.close),
                                          child: InkWell(
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
                                                                serviceLocator<ProjectViewModel>().getCurrentSelectionZoneColor(),
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
                                                              serviceLocator<ProjectViewModel>().getCurrentSelectionZoneColor(),
                                                            ) ==
                                                            Brightness.light
                                                        ? Colors.grey.shade800
                                                        : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GuideShowcaseWrapper(
                                          step: GuideShowCaseSteps.confirmSelectListeningArea,
                                          onHighlightedSpotTap: (TapDownDetails details) {
                                            serviceLocator<ProjectViewModel>().clearSelectedZone();
                                            serviceLocator<ProjectViewModel>().clearSelectedSubZone();
                                            widget.floorCanvasController.completeListeningAreaSelection();
                                            serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.confirmSelectListeningArea);
                                          },
                                          child: SemanticHelper.button(
                                            testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.check),
                                            child: InkWell(
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
                                                                  serviceLocator<ProjectViewModel>().getCurrentSelectionZoneColor(),
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
                                                                serviceLocator<ProjectViewModel>().getCurrentSelectionZoneColor(),
                                                              ) ==
                                                              Brightness.light
                                                          ? Colors.grey.shade800
                                                          : Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: widget.floorCanvasController.isDrawing,
                                    builder: (_, bool isDrawing, __) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: widget.floorCanvasController.isShowingSpl,
                                        builder: (_, bool isShowingSpl, __) {
                                          return BuildingToolbar(
                                            onSplSelected: () {
                                              widget.floorCanvasController.toggleSpl();
                                              widget.onCalculateSpl();
                                              widget.onSplStateChanged(
                                                widget.floorCanvasController.isShowingSpl.value,
                                              );
                                            },
                                            onSplDisabled: () {
                                              widget.floorCanvasController.setSpl(false);
                                              widget.onSplStateChanged(false);
                                            },
                                            onPanSelected: () {},
                                            onMoveSelected: () {},
                                            onDrawSelected: () {
                                              if (!widget.floorCanvasController.isDrawing.value) {
                                                serviceLocator<ProjectViewModel>().enterListeningAreaMode();
                                              } else {
                                                serviceLocator<ProjectViewModel>().exitSelectionModes();
                                              }
                                            },
                                            onDrawingDisabled: () {
                                              widget.floorCanvasController.setDraw(false);
                                            },
                                            onEditFloorPlanSelected: _showFloorPlanPicker,
                                            onTrashSelected: () {},
                                            onFitSelected: () {
                                              widget.floorCanvasController.fitToView();
                                            },
                                            onAddSpeakerSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(
                                                0,
                                              ); // DeviceType.speakers
                                            },
                                            onAddSourceSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(
                                                1,
                                              ); // DeviceType.sources
                                            },
                                            onAddEndpointSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(
                                                2,
                                              ); // DeviceType.endpoints
                                            },
                                            onAddAmplifierSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(
                                                3,
                                              ); // DeviceType.amplifiers
                                            },
                                            onAddDspSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(
                                                4,
                                              ); // DeviceType.dsp
                                            },
                                            onAddControllerSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(
                                                5,
                                              ); // DeviceType.controllers
                                            },
                                            onAddRackSelected: () {
                                              serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(
                                                6,
                                              ); // DeviceType.rack
                                            },
                                            onProductSelected: widget.onProductSelected,
                                            onProductDeselected: widget.onProductDeselected,
                                            isDrawSelected: isDrawing,
                                            isSplSelected: isShowingSpl,
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        border: Border.all(color: context.colorScheme.elevation2, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          /// icon
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primaryWhite,
              BlendMode.srcIn,
            ),
            child: const FusionImage.asset(
              "assets/images/upload_floor_plan.png",
              width: 64,
              height: 64,
            ),
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
          GuideShowcaseWrapper(
            step: GuideShowCaseSteps.uploadFloorPlan,
            onHighlightedSpotTap: (TapDownDetails details) => _showFloorPlanPicker(),
            child: FusionOutlinedButton(
              height: 32,
              width: 160,
              semanticsId: FusionTestKeys.uploadFloorPlan,
              label: "Upload Floor-plan",
              textStyle: Theme.of(context).textTheme.titleSmall,
              onTap: () {
                _showFloorPlanPicker();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFloorPlanPicker() async {
    final List<String> plans = <String>[
      "assets/images/floor_plans/cafe.png",
      "assets/images/floor_plans/restaurant.png",
      // "assets/images/floor_plans/floor_plan_gym.png",
      "assets/images/floor_plans/gym.jpg",
    ];

    await showDialog(
      context: context,
      builder:
          (BuildContext ctx) => Dialog(
            backgroundColor: Theme.of(context).colorScheme.elevation1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Container(
              width: 720,
              height: 600,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'Upload Floor Plan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.textPrimary,
                          ),
                        ),
                      ),
                      SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.closeX),
                        child: IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(
                            Icons.close,
                            color: context.colorScheme.primaryWhite,
                            size: 20,
                          ),
                          splashRadius: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Import Section (Primary)
                  Expanded(
                    flex: 3,
                    child: _buildImportSection(ctx),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: <Widget>[
                      Expanded(child: Divider(color: context.colorScheme.elevation2)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FusionAppText(
                          text: 'or choose from samples',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.primaryWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: context.colorScheme.elevation2)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: List<Widget>.generate(
                      plans.length,
                      (int index) {
                        final String planPath = plans[index];
                        return Expanded(
                          child: _buildSamplePlanCard(index, planPath),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildImportSection(BuildContext ctx) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> details) => true,
      onAcceptWithDetails: (DragTargetDetails<String> details) {
        _importFloorPlan();
      },
      builder: (BuildContext context, List<String?> candidateData, List<dynamic> rejectedData) {
        final bool isDragActive = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _importFloorPlan(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDragActive ? Theme.of(context).colorScheme.primaryColor.withValues(alpha: 0.05) : context.colorScheme.elevation1,
              border: Border.all(
                width: isDragActive ? 2 : 1,
                color: isDragActive ? Theme.of(context).colorScheme.primaryWhite : context.colorScheme.elevation2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDragActive ? context.colorScheme.primaryWhite.withValues(alpha: 0.15) : context.colorScheme.primaryWhite.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDragActive ? Icons.file_download : Icons.cloud_upload_outlined,
                    size: 48,
                    color: context.colorScheme.primaryWhite,
                  ),
                ),
                const SizedBox(height: 16),
                FusionAppText(
                  text: isDragActive ? 'Drop your file here!' : 'Click here to upload',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDragActive ? context.colorScheme.primaryWhite : context.colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                FusionAppText(
                  text: 'Upload .JPEG and .PNG files',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDragActive ? context.colorScheme.primaryWhite : context.colorScheme.elevation4,
                  ),
                ),
                const SizedBox(height: 16),
                FusionOutlinedButton(
                  height: 36,
                  width: 140,
                  label: 'Browse Files',
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  foregroundColor: Theme.of(context).colorScheme.textPrimary,
                  activeBorderColor: Theme.of(context).colorScheme.primaryWhite,
                  backgroundColor: Theme.of(context).colorScheme.primaryColor.withValues(alpha: 0.05),
                  onTap: () => _importFloorPlan(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSamplePlanCard(int index, String planPath) {
    final String title = planPath.split('/').last.split('.').first.replaceAll('_', ' ').toUpperCase();

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'floor_plan_sample_${index + 1}'),
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.elevation2,
          ),
        ),
        child: GestureDetector(
          onTap: () => _selectAssetFloorPlan(planPath),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _buildFloorPlanImage(planPath),
              ),
              const SizedBox(height: 8),
              FusionAppText(
                text: title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLine: 1,
                // overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloorPlanImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return Container(
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
    serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.uploadFloorPlan);

    final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addAssetImageToProject(
      assetPath: assetImagePath,
    );
    if (responseCallback.success && responseCallback.data != null) {
      final String savedImagePath = responseCallback.data!;
      _calibrateFloorPlan(savedImagePath);
    }
  }

  Future<void> _importFloorPlan() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: <String>['png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        final String sourcePath = result.files.single.path!;
        final String fileName = result.files.single.name;

        // Close the dialog first
        // if (mounted) Navigator.of(context).pop();

        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (BuildContext context) => const Center(
                  child: CircularProgressIndicator(),
                ),
          );

          final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(imagePath: sourcePath);

          if (mounted) Navigator.of(context).pop();

          // ignore: use_build_context_synchronously
          serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.uploadFloorPlan);

          if (responseCallback.success && responseCallback.data != null) {
            final String savedImagePath = responseCallback.data!;
            _calibrateFloorPlan(savedImagePath);
          }

          if (mounted) {
            Navigator.of(context).pop();
          }
          debugPrint('Floor plan imported successfully: $fileName');
        } else {
          debugPrint("Dialog is not mounted !!!!!");
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('Error importing floor plan: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: FusionAppText(text: 'Error importing floor plan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _calibrateFloorPlan(String savedImagePath) async {
    try {
      final ui.Image image = await serviceLocator<ImageLoaderService>().loadImage(savedImagePath);

      // if (!mounted) return;
      //
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (_) => const Center(child: CircularProgressIndicator()),
      // );
      //
      // await Future<void>.delayed(const Duration(milliseconds: 100));
      //
      // if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      final CalibrationData? calibrationData = await showDialog<CalibrationData>(
        context: context,
        barrierDismissible: true,
        builder:
            (_) => Dialog(
              child: FloorPlanCalibrationDialog(
                floorPlanImage: image,
                onCalibrationComplete: (CalibrationData data) {
                  serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.confirmFloorCalibrated);
                  if (context.mounted) {
                    Navigator.of(context).pop(data);
                  }
                },
                onCancel: () {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
      );

      if (calibrationData != null) {
        debugPrint('Calibration completed: $calibrationData');

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

        debugPrint(
          'Real-world dimensions: ${widthInMeters.toStringAsFixed(2)}m x ${heightInMeters.toStringAsFixed(2)}m',
        );
        debugPrint(
          'Canvas dimensions: ${canvasWidthInPixels.toStringAsFixed(1)}px x ${canvasHeightInPixels.toStringAsFixed(1)}px',
        );

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
        // ignore: use_build_context_synchronously
        serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.confirmFloorCalibrated);
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
                  child: FusionAppText(text: 'Error during calibration: $e'),
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
    final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(
      imagePath: tempPath,
    );

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

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUp;

  TrianglePainter({required this.color, this.isUp = true});

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

    final ui.Path path = Path();

    if (isUp) {
      path
        ..moveTo(size.width / 2, 0) // top center
        ..lineTo(0, size.height) // bottom left
        ..lineTo(size.width, size.height); // bottom right
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
