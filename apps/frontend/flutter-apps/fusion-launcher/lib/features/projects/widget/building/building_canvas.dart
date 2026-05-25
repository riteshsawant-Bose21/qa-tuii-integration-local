import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/selection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/tool/selection_tool_painter.dart';
import 'package:fusion_launcher/features/processing_block/view/processing_blocks/widgets/disabled_widget_wrapper.dart';
import 'package:fusion_launcher/features/projects/view_model/spl_viewmodel.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_state.dart';
import 'package:fusion_launcher/features/projects/widget/building/empty_floor_plan.dart';
import 'package:fusion_launcher/features/projects/widget/building/toolbar/canvas_toolbar.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/spl_slider.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/wall_model.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../fusion_canvas/state/fusion_canvas_input_state.dart';
import '../../../fusion_canvas/state/fusion_tool_state.dart';
import '../../../fusion_canvas/view/fusion_canvas.dart';
import '../../../fusion_canvas/view/painters/elements/derived/floor_text_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/hardware_component_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/hardware_painter/floor_plan_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/listening_area_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/spl_loader_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/spl_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/wall_painter.dart';
import '../../../fusion_canvas/view/painters/elements/fusion_dotted_bg_painter.dart';
import '../../../fusion_canvas/view/painters/fusion_canvas_painter.dart';
import '../../../fusion_canvas/viewmodel/fusion_canvas_state_viewmodel.dart';
import '../../../fusion_canvas/viewmodel/tools/fusion_canvas_tool.dart';
import '../../presentation/project_work_area.dart';
import '../../viewmodel/building_page_viewmodel.dart';

class BuildingCanvas extends StatefulWidget {
  final SplRangeController? splRangeController;
  final Function(bool isShowing) onSplStateChanged;
  final Future<void> Function() onCalculateSpl;
  final SplPanelData splPanelData;

  const BuildingCanvas({
    super.key,
    this.splRangeController,
    required this.onSplStateChanged,
    required this.onCalculateSpl,
    required this.splPanelData,
    required this.leftPanel,
    required this.rightPanel,
  });
  final Widget leftPanel;
  final Widget rightPanel;

  @override
  State<BuildingCanvas> createState() => _BuildingCanvasState();
}

class _BuildingCanvasState extends State<BuildingCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  // bool showLiveSpl = false;
  FusionCanvasPainter? painter;
  @override
  void dispose() {
    animationController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    animationController.repeat();
    super.initState();
  }

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  void calculateSpl(BuildContext context) {
    if (context.read<BuildingPageViewModel>().isSplMode) {
      widget.onCalculateSpl();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return BlocConsumer<ProjectViewModel, ProjectViewModelState>(
            listener: (BuildContext context, ProjectViewModelState state) {},
            builder: (BuildContext context, ProjectViewModelState state) {
              final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
              final FloorModel floor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];

              final BuildingPageViewModel buildingPageViewModel = context.watch<BuildingPageViewModel>();
              final bool isFloorPlanPending = floor.skipFloorPlan == null && floor.floorPlan.imagePath.isEmpty;
              return Stack(
                children: <Widget>[
                  GuideShowcaseWrapper(
                    semanticId: "building_canvas_floor_plan",
                    step: GuideShowCaseSteps.showListeningAreaSelectionArea,
                    child: SemanticHelper.container(
                      testId: SemanticHelper.createTestId(SemanticTypes.container, "building_floor_canvas"),
                      child: Builder(
                        builder: (BuildContext context) {
                          final List<HardwareComponent> hardwareInFloorWithPosition = serviceLocator<ProjectViewModel>().getHardwareInFloorWithPosition(
                            floorId: floor.id,
                          );

                          final bool isAcousticsMode = context.watch<BuildingPageViewModel>().state.toolbarMode == ToolbarMode.acoustics;

                          final List<ListeningAreaPainter> listeningAreaPainters = <ListeningAreaPainter>[
                            for (final ListeningArea area in serviceLocator<ProjectViewModel>().getListeningAreasForFloor(floorId: floor.id))
                              ListeningAreaPainter(
                                backgoundColor:
                                    buildingPageViewModel.state.toolbarMode == ToolbarMode.system
                                        ? serviceLocator<ProjectViewModel>().getZoneColorForLA(areaId: area.id)
                                        : null,
                                listeningArea: area,
                                isShowingSpl: buildingPageViewModel.isSplMode,
                              ),
                          ];

                          return AnimatedBuilder(
                            animation: animationController,
                            builder: (BuildContext context, Widget? child) {
                              final Set<String> selectedIds = <String>{
                                if (buildingPageViewModel.state.selectedListeningAreaId != null) buildingPageViewModel.state.selectedListeningAreaId!,
                                if (buildingPageViewModel.state.selectedSpeakerId != null) buildingPageViewModel.state.selectedSpeakerId!,
                                if (buildingPageViewModel.state.selectedWallId != null) buildingPageViewModel.state.selectedWallId!,
                                if (buildingPageViewModel.state.selectedTextId != null) buildingPageViewModel.state.selectedTextId!,
                                if (buildingPageViewModel.state.selectedCircuitId != null) //buildingPageViewModel.state.selectedCircuitId!,
                                  ...serviceLocator<ProjectViewModel>()
                                      .getHardwareForCircuit(circuitId: buildingPageViewModel.state.selectedCircuitId!)
                                      .map((HardwareComponent e) => e.id),
                              };
                              final SplState splState = context.watch<SplViewModel>().state;
                              return FusionCanvas(
                                selectedIds: selectedIds,
                                onCanvasPainterReady: (FusionCanvasPainter value) {
                                  painter = value;
                                },
                                tools:
                                    isFloorPlanPending
                                        ? <FusionCanvasTool<FusionToolState>>[]
                                        : <FusionCanvasTool<FusionToolState>>[
                                          FusionCanvasTool.measureTool,
                                          FusionCanvasTool.penTool,
                                          FusionCanvasTool.rectangleTool,
                                          FusionCanvasTool.customDragTool(
                                            transformSelectedLayerIds: (String layerId) {
                                              return buildingPageViewModel.transformLayerIdForSelection(
                                                layerId: layerId,
                                                hardwareInFloorWithPosition: hardwareInFloorWithPosition,
                                              );
                                            },
                                          ),
                                          FusionCanvasTool.customSingleSelectionTool(
                                            SelectionToolParams(
                                              enableSelect: true,
                                              enableMultiSelect: false,
                                              enableMarqueeSelection: false,
                                              transformSelectedLayerIds: (String layerId) {
                                                return buildingPageViewModel.transformLayerIdForSelection(
                                                  layerId: layerId,
                                                  hardwareInFloorWithPosition: hardwareInFloorWithPosition,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                selectionToolParam: const SelectionToolPainterParam(drawOverallBounding: false),
                                elements: <FusionBasePainter>[
                                  FusionDottedBgPainter(
                                    color: Colors.grey.shade300,
                                  ),
                                  if (buildingPageViewModel.isSplMode) ...<FusionBasePainter>[
                                    if (splState is SplLoadingState)
                                      SplLoaderPainter(
                                        animation: animationController,
                                        listeningAreas: serviceLocator<ProjectViewModel>().getListeningAreasForFloor(floorId: floor.id),
                                      ),
                                    SplPainter(
                                      listeningAreas: listeningAreaPainters,
                                      minSpl: projectViewModel.minSPL,
                                      maxSpl: projectViewModel.maxSPL,
                                      splPanelData: widget.splPanelData,
                                      splState: splState,
                                    ),
                                  ],
                                  FloorPlanPainter(
                                    image: floor.floorPlan.imagePath,
                                    position: floor.floorPlan.position,
                                    size: floor.skipFloorPlan == true ? const Size(5000, 5000) : floor.floorPlan.size,
                                    showSpl: true,
                                  ),

                                  ...listeningAreaPainters,
                                  for (final Wall wall in serviceLocator<ProjectViewModel>().getWallsForFloor(floorId: floor.id)) WallPainter(wall: wall),
                                  // for (final FloorText floorText in serviceLocator<ProjectViewModel>().getTextsForFloor(floorId: floor.id))
                                  //   FloorTextPainter(floorText: floorText),
                                  for (final HardwareComponent hw in hardwareInFloorWithPosition)
                                    if (hw is Speaker)
                                      HardwareComponentPainter(hardware: hw, canMove: isAcousticsMode)
                                    else if (!isAcousticsMode)
                                      HardwareComponentPainter(hardware: hw),
                                ],
                                toolbarEvents: FusionCanvasEvents(
                                  onLayerSelected: (List<FusionBasePainter>? values) {
                                    final FusionBasePainter? value = values != null && values.isNotEmpty ? values.first : null;
                                    if (value is ListeningAreaPainter) {
                                      context.read<BuildingPageViewModel>().selectListingArea(value.id ?? "");
                                    } else if (value is HardwareComponentPainter) {
                                      context.read<BuildingPageViewModel>().selectHardware(value.hardware);
                                    } else if (value is WallPainter) {
                                      context.read<BuildingPageViewModel>().selectWall(value.wall.id);
                                    } else if (value is FloorTextPainter) {
                                      context.read<BuildingPageViewModel>().selectText(value.floorText.id);
                                    } else if (value == null) {
                                      projectViewModel.deselectAll();
                                      context.read<BuildingPageViewModel>().clearCanvasEntitySelection();
                                    }
                                  },
                                  onAddPoints: (FusionBasePainter painter, List<FusionCanvasPoint> points, FusionCanvasLine line) {
                                    // print("Add Points: $points");
                                    if (painter is ListeningAreaPainter) {
                                      final ListeningArea area = painter.listeningArea;
                                      final FusionCanvasPoint start = line.start;
                                      final int indexToInsert = area.vertices.indexWhere((FusionCanvasPoint v) => v.id == start.id);
                                      final List<FusionCanvasPoint> updatedPoints = List<FusionCanvasPoint>.from(area.vertices);
                                      updatedPoints.insertAll(indexToInsert + 1, points);
                                      serviceLocator<ProjectViewModel>().updateListeningArea(
                                        area: area.copyWith(vertices: updatedPoints),
                                      );
                                      calculateSpl(context);
                                    } else if (painter is WallPainter) {
                                      final Wall wall = painter.wall;
                                      final FusionCanvasPoint start = line.start;
                                      final int indexToInsert = wall.vertices.indexWhere((FusionCanvasPoint v) => v.id == start.id);
                                      final List<FusionCanvasPoint> updatedPoints = List<FusionCanvasPoint>.from(wall.vertices);
                                      updatedPoints.insertAll(indexToInsert + 1, points);
                                      serviceLocator<ProjectViewModel>().updateWall(
                                        wall: wall.copyWith(vertices: updatedPoints),
                                      );
                                      calculateSpl(context);
                                    }
                                  },
                                  onMoveLayer: (FusionBasePainter painter, Offset offset) {
                                    if (painter is ListeningAreaPainter) {
                                      final ListeningArea area = painter.listeningArea;
                                      serviceLocator<ProjectViewModel>().updateListeningArea(
                                        area: area.copyWith(
                                          vertices: area.vertices.map((FusionCanvasPoint v) => v.copyWith(position: v.position + offset)).toList(),
                                        ),
                                      );
                                      calculateSpl(context);
                                    } else if (painter is HardwareComponentPainter) {
                                      final HardwareComponent hw = painter.hardware;
                                      serviceLocator<ProjectViewModel>().updateHardware(
                                        hardware: hw.copyWith(
                                          pos: (hw.pos ?? Offset.zero) + offset,
                                        ),
                                      );
                                      calculateSpl(context);
                                    } else if (painter is FloorTextPainter) {
                                      serviceLocator<ProjectViewModel>().updateText(
                                        floorText: painter.floorText.copyWith(
                                          position: painter.floorText.position.copyWith(position: painter.floorText.position.position + offset),
                                        ),
                                      );
                                    }
                                  },
                                  onDeleteLayer: (FusionBasePainter painter) {
                                    if (painter is ListeningAreaPainter) {
                                      serviceLocator<ProjectViewModel>().removeListeningArea(areaId: painter.listeningArea.id);
                                    } else if (painter is HardwareComponentPainter) {
                                      serviceLocator<ProjectViewModel>().removeHardware(hardwareId: painter.hardware.id);
                                    } else if (painter is WallPainter) {
                                      serviceLocator<ProjectViewModel>().removeWall(wallId: painter.wall.id);
                                    } else if (painter is FloorTextPainter) {
                                      serviceLocator<ProjectViewModel>().removeText(textId: painter.floorText.id);
                                    }
                                    calculateSpl(context);
                                  },
                                  onRemovePoints: (FusionBasePainter painter, List<String> points) {
                                    if (painter is ListeningAreaPainter) {
                                      final ListeningArea area = painter.listeningArea;
                                      final List<FusionCanvasPoint> updatedPoints =
                                          area.vertices.where((FusionCanvasPoint v) => points.every((String p) => !p.contains(v.id))).toList();
                                      if (updatedPoints.length < 3) {
                                        FusionToast.error(context, message: "Listening area should have minimum 3 points");
                                        return;
                                      }
                                      serviceLocator<ProjectViewModel>().updateListeningArea(
                                        area: area.copyWith(vertices: updatedPoints),
                                      );
                                    } else if (painter is WallPainter) {
                                      final Wall wall = painter.wall;
                                      final List<FusionCanvasPoint> updatedPoints =
                                          wall.vertices.where((FusionCanvasPoint v) => points.every((String p) => !p.contains(v.id))).toList();
                                      if (updatedPoints.length < 2) {
                                        FusionToast.error(context, message: "Wall should have minimum 2 points");
                                        return;
                                      }
                                      serviceLocator<ProjectViewModel>().updateWall(
                                        wall: wall.copyWith(vertices: updatedPoints),
                                      );
                                    }
                                    calculateSpl(context);
                                  },
                                  onMovePoints: (FusionBasePainter painter, List<String> points, Offset delta) {
                                    if (painter is ListeningAreaPainter) {
                                      final ListeningArea area = painter.listeningArea;
                                      final List<FusionCanvasPoint> updatedPoints =
                                          area.vertices.map((FusionCanvasPoint v) {
                                            if (points.any((String p) => p == v.id)) {
                                              return v.copyWith(position: v.position + delta);
                                            } else {
                                              return v;
                                            }
                                          }).toList();
                                      serviceLocator<ProjectViewModel>().updateListeningArea(
                                        area: area.copyWith(vertices: updatedPoints),
                                      );
                                      calculateSpl(context);
                                    } else if (painter is HardwareComponentPainter) {
                                      final HardwareComponent hw = painter.hardware;
                                      serviceLocator<ProjectViewModel>().updateHardware(
                                        hardware: hw.copyWith(
                                          pos: (hw.pos ?? Offset.zero) + delta,
                                        ),
                                      );
                                      calculateSpl(context);
                                    } else if (painter is WallPainter) {
                                      final Wall wall = painter.wall;
                                      final List<FusionCanvasPoint> updatedPoints =
                                          wall.vertices.map((FusionCanvasPoint v) {
                                            if (points.any((String p) => p == v.id)) {
                                              return v.copyWith(position: v.position + delta);
                                            } else {
                                              return v;
                                            }
                                          }).toList();
                                      serviceLocator<ProjectViewModel>().updateWall(
                                        wall: wall.copyWith(vertices: updatedPoints),
                                      );
                                      calculateSpl(context);
                                    }
                                  },
                                  inputEvents: FusionCanvasInputEvents(
                                    onMouseUp: (FusionCanvasInputTapUpState event) {
                                      final BuildingPageViewModel buildingPageViewModel = context.read<BuildingPageViewModel>();
                                      if (buildingPageViewModel.state.toolState is DrawingTextState && event.gestureOrigin == FusionGestureOrigin.click) {
                                        final int textCount = serviceLocator<ProjectViewModel>().getTextsForFloor(floorId: floor.id).length;
                                        serviceLocator<ProjectViewModel>().addText(
                                          floorText: FloorText(
                                            text: 'Text ${textCount + 1}',
                                            position: FusionCanvasPoint(position: event.tapPosition),
                                          ),
                                          floorId: floor.id,
                                        );
                                        return true;
                                      }
                                      if (!buildingPageViewModel.canPlaceSpeakerOnMouseUp(event)) {
                                        return false;
                                      }
                                      projectViewModel.placeSelectedSpeaker(position: event.tapPosition, isFromBuildingPage: true);
                                      final bool hasPendingSpeakers = projectViewModel.getNonPlacedSpeakersForCurrentListeningArea().isNotEmpty;
                                      buildingPageViewModel.onSpeakerPlaced(hasPendingSpeakers: hasPendingSpeakers);
                                      return true;
                                    },
                                  ),
                                  penToolEvents: FusionPenToolEvents(
                                    onPathCancelled: (List<FusionCanvasPoint> value) {
                                      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
                                      final BuildingPageToolState state = context.read<BuildingPageViewModel>().state.toolState;
                                      if (state is DrawingWallState) {
                                        if (value.length >= 2) projectVM.addWall(wall: Wall(vertices: value), floorId: floor.id);
                                      }
                                    },
                                    onPathClosed: (List<FusionCanvasPoint> value) {
                                      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
                                      if (value.last == value.first) {
                                        value.removeLast();
                                      }
                                      final BuildingPageToolState state = context.read<BuildingPageViewModel>().state.toolState;
                                      if (state is DrawingListeningAreaState) {
                                        final String? listeningAreaId =
                                            state
                                                .listeningAreaId; // if we are already in drawing mode, we should update the existing listening area instead of creating a new one
                                        final ListeningArea? existingArea = projectVM.listeningAreas.firstWhereOrNull(
                                          (ListeningArea element) => element.id == listeningAreaId,
                                        );
                                        if (existingArea == null) {
                                          final ListeningArea listeningArea = ListeningArea(
                                            vertices: value,
                                            name: "Listening Area ${projectVM.listeningAreas.length + 1}",
                                          );
                                          projectVM.addListeningArea(
                                            area: listeningArea,
                                            floorId: floor.id,
                                          );
                                          projectVM.setCurrentSelectedListeningArea(listeningArea.id);
                                        } else {
                                          projectVM.updateListeningArea(
                                            area: existingArea.copyWith(vertices: value, isDrawn: true),
                                          );
                                          projectVM.setCurrentSelectedListeningArea(existingArea.id);
                                        }
                                      } else if (state is DrawingWallState) {
                                        projectVM.addWall(wall: Wall(vertices: value), floorId: floor.id);
                                      }

                                      calculateSpl(context);
                                    },
                                  ),
                                  rectangleToolEvents: FusionRectangleToolEvents(
                                    onRectangleDrawn: (List<FusionCanvasPoint> value) {
                                      final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
                                      if (value.last == value.first) {
                                        value.removeLast();
                                      }
                                      final String? listeningAreaId = null;
                                      // state
                                      //     .listeningAreaId; // if we are already in drawing mode, we should update the existing listening area instead of creating a new one
                                      final ListeningArea? existingArea = projectVM.listeningAreas.firstWhereOrNull(
                                        (ListeningArea element) => element.id == listeningAreaId,
                                      );
                                      if (existingArea == null) {
                                        final ListeningArea listeningArea = ListeningArea(
                                          vertices: value,
                                          name: "Listening Area ${projectVM.listeningAreas.length + 1}",
                                        );
                                        projectVM.addListeningArea(
                                          area: listeningArea,
                                          floorId: floor.id,
                                        );
                                        projectVM.setCurrentSelectedListeningArea(listeningArea.id);
                                      } else {
                                        projectVM.updateListeningArea(
                                          area: existingArea.copyWith(vertices: value, isDrawn: true),
                                        );
                                        projectVM.setCurrentSelectedListeningArea(existingArea.id);
                                      }

                                      calculateSpl(context);
                                    },
                                  ),
                                ),
                                builder:
                                    (BuildContext context) => BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                                      listenWhen:
                                          (ProjectViewModelState previous, ProjectViewModelState current) => previous != current && current is FloorsUpdated,
                                      listener: (BuildContext context, ProjectViewModelState state) {
                                        if (state is FloorsUpdated) {
                                          Future<void>.delayed(const Duration(milliseconds: 100), () {
                                            context.read<FusionCanvasStateViewModel>().fitToScreen(
                                              padding: EdgeInsets.only(
                                                left: 250,
                                                right: 250,
                                                top: WorkAreaScope.of(context).appBarHeight,
                                                bottom: 20 + 50,
                                              ),
                                            );
                                          });
                                          // onFloorUpdated();
                                        }
                                      },
                                      builder: (BuildContext context, _) {
                                        return Stack(
                                          children: <Widget>[
                                            Positioned(left: 0, child: widget.leftPanel),
                                            Positioned(
                                              right: 0,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  widget.rightPanel,
                                                  WorkSafeAreaContent(
                                                    child: SizedBox(
                                                      height: constraints.maxHeight - WorkAreaScope.of(context).appBarHeight,
                                                      child: SplSlider(
                                                        splPanelData: widget.splPanelData,
                                                        splRangeController: widget.splRangeController,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Padding(
                                                padding: const EdgeInsets.all(20),
                                                child: DisabledWidgetWrapper(
                                                  isDisabled: isFloorPlanPending,
                                                  child: const CanvasToolBar(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),

                                cursorBuilder: (BuildContext context) {
                                  final BuildingPageViewModel buildingPageViewModel = context.watch<BuildingPageViewModel>();
                                  // final List<Speaker> nonPlacedSpeakers = projectViewModel.getNonPlacedSpeakersForCurrentListeningArea();
                                  final SpeakerPlacementCursorState? cursorState = buildingPageViewModel.getSpeakerPlacementCursorState();
                                  if (cursorState == null) {
                                    return null;
                                  }
                                  return (
                                    Alignment.center,
                                    Builder(
                                      builder: (BuildContext context) {
                                        final MountingType? speakerMountType = cursorState.mountingType;

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
                                                  text: '${cursorState.pendingCount}',
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: context.colorScheme.onPrimary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                        // } else if (serviceLocator<ProjectViewModel>().selectedProductToAdd != null) {
                                        //   return Image.asset(
                                        //     serviceLocator<ProjectViewModel>().selectedProductToAdd!.image,
                                        //     width: 32,
                                        //     height: 32,
                                        //   );
                                        // } else {
                                        //   return const SizedBox.shrink();
                                        // }
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  if (isFloorPlanPending) ...<Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(245, 65, 2, 16),
                      child: EmptyFloorPlan(),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
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
