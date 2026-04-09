import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/fusion_canvas/view/painters/fusion_base_painter.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_state.dart';
import 'package:fusion_launcher/features/projects/widget/building/toolbar/canvas_toolbar.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_utils/image_loader_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../fusion_canvas/state/fusion_canvas_input_state.dart';
import '../../../fusion_canvas/view/fusion_canvas.dart';
import '../../../fusion_canvas/view/painters/elements/derived/hardware_component_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/hardware_painter/floor_plan_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/listening_area_painter.dart';
import '../../../fusion_canvas/view/painters/elements/derived/spl_painter.dart';
import '../../../fusion_canvas/view/painters/elements/fusion_dotted_bg_painter.dart';
import '../../presentation/project_work_area.dart';
import '../../viewmodel/building_page_viewmodel.dart';

class BuildingCanvas extends StatefulWidget {
  final SplRangeController? splRangeController;
  final Function(bool isShowing) onSplStateChanged;
  final FloorCanvasController floorCanvasController;
  final Future<void> Function() onCalculateSpl;
  final SplPanelData splPanelData;

  const BuildingCanvas({
    super.key,
    this.splRangeController,
    required this.onSplStateChanged,
    required this.floorCanvasController,
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

class _BuildingCanvasState extends State<BuildingCanvas> {
  Offset viewPortCenter = Offset.zero;

  // bool showLiveSpl = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // void zoneSelectionMode(Zone zone) async {
  //   final List<ListeningArea>? selectedAreas = await widget.floorCanvasController.requestListeningAreaSelection(
  //     serviceLocator<ProjectViewModel>().getListeningAreasForZone(
  //       zoneId: zone.id,
  //     ),
  //     zone,
  //   );

  //   if (selectedAreas != null) {
  //     print(
  //       "Selected areas for zone ${zone.name}: ${selectedAreas.map((ListeningArea e) => e.name).toList()}",
  //     );
  //     serviceLocator<ProjectViewModel>().updateListeningAreasInZone(
  //       zoneId: zone.id,
  //       listeningAreaIds: selectedAreas.map((ListeningArea e) => e.id).toList(),
  //     );
  //   } else {
  //     serviceLocator<ProjectViewModel>().clearSelectedZone();
  //   }
  // // }

  // void subzoneSelectionMode(SubZone subZone) async {
  //   final List<ListeningArea>? selectedAreas = await widget.floorCanvasController.requestListeningAreaSelectionForSubZone(
  //     serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(
  //       subZoneId: subZone.id,
  //     ),
  //     subZone,
  //   );

  //   if (selectedAreas != null) {
  //     print(
  //       "Selected areas for subzone ${subZone.name}: ${selectedAreas.map((ListeningArea e) => e.name).toList()}",
  //     );
  //     serviceLocator<ProjectViewModel>().updateListeningAreasInSubZone(
  //       subZoneId: subZone.id,
  //       listeningAreaIds: selectedAreas.map((ListeningArea e) => e.id).toList(),
  //     );
  //   } else {
  //     serviceLocator<ProjectViewModel>().clearSelectedSubZone();
  //   }
  // }

  // Offset? cursorPosition;

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  // // bool get shouldUseCustomCursor => projectViewModel.selectedProductToAdd != null || projectViewModel.shouldPlaceNonPlacedSpeakers;

  // MouseCursor get cursorType {
  //   // if (widget.floorCanvasController.isDrawing.value) {
  //   //   return SystemMouseCursors.precise;
  //   // } else if (projectViewModel.selectedProductToAdd != null || projectViewModel.shouldPlaceNonPlacedSpeakers) {
  //   //   return SystemMouseCursors.none;
  //   // } else {
  //   return SystemMouseCursors.basic;
  //   // }
  // }

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
          return Column(
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

                          return ValueListenableBuilder<bool>(
                            valueListenable: widget.floorCanvasController.isDrawing,
                            builder: (BuildContext context, bool isDrawingValue, Widget? child) {
                              final BuildingPageViewModel buildingPageViewModel = context.watch<BuildingPageViewModel>();
                              return Stack(
                                children: <Widget>[
                                  GuideShowcaseWrapper(
                                    semanticId: "building_canvas_floor_plan",
                                    step: GuideShowCaseSteps.showListeningAreaSelectionArea,
                                    child: SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "building_floor_canvas"),
                                      child: Builder(
                                        builder: (BuildContext context) {
                                          final List<ListeningAreaPainter> listeningAreaPainters = <ListeningAreaPainter>[
                                            for (final ListeningArea area in serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
                                              floorId: floor.id,
                                            ))
                                              ListeningAreaPainter(listeningArea: area, isShowingSpl: buildingPageViewModel.isSplMode),
                                          ];

                                          return FusionCanvas(
                                            selectedIds: <String>{
                                              if (buildingPageViewModel.state.selectedListeningAreaId != null)
                                                buildingPageViewModel.state.selectedListeningAreaId!,
                                              if (buildingPageViewModel.state.selectedSpeakerId != null) buildingPageViewModel.state.selectedSpeakerId!,
                                            },

                                            elements: <FusionBasePainter>[
                                              FusionDottedBgPainter(
                                                color: Colors.grey.shade300,
                                              ),
                                              if (buildingPageViewModel.isSplMode)
                                                SplPainter(
                                                  listeningAreas: listeningAreaPainters,
                                                  minSpl: projectViewModel.minSPL,
                                                  maxSpl: projectViewModel.maxSPL,
                                                  splPanelData: widget.splPanelData,
                                                ),
                                              FloorPlanPainter(
                                                image: floor.floorPlan.imagePath,
                                                position: floor.floorPlan.position,
                                                size: floor.floorPlan.size,
                                                showSpl: true,
                                              ),
                                              ...listeningAreaPainters,
                                              for (final HardwareComponent hw in serviceLocator<ProjectViewModel>().getHardwareInFloorWithPosition(
                                                floorId: floor.id,
                                              ))
                                                HardwareComponentPainter(
                                                  hardware: hw,
                                                ),
                                            ],
                                            toolbarEvents: FusionCanvasEvents(
                                              onLayerSelected: (List<FusionBasePainter>? values) {
                                                final FusionBasePainter? value = values != null && values.isNotEmpty ? values.first : null;
                                                if (value is ListeningAreaPainter) {
                                                  serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(value.listeningArea.id);
                                                  serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
                                                } else if (value is HardwareComponentPainter) {
                                                  serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
                                                  serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(value.hardware.id);
                                                } else if (value == null) {
                                                  serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
                                                  serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
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
                                                }
                                              },
                                              onDeleteLayer: (FusionBasePainter painter) {
                                                if (painter is ListeningAreaPainter) {
                                                  serviceLocator<ProjectViewModel>().removeListeningArea(areaId: painter.listeningArea.id);
                                                  calculateSpl(context);
                                                } else if (painter is HardwareComponentPainter) {
                                                  serviceLocator<ProjectViewModel>().removeHardware(hardwareId: painter.hardware.id);
                                                  calculateSpl(context);
                                                }
                                              },
                                              onRemovePoints: (FusionBasePainter painter, List<String> points) {
                                                if (painter is ListeningAreaPainter) {
                                                  final ListeningArea area = painter.listeningArea;
                                                  final List<FusionCanvasPoint> updatedPoints =
                                                      area.vertices.where((FusionCanvasPoint v) => points.every((String p) => p != v.id)).toList();
                                                  serviceLocator<ProjectViewModel>().updateListeningArea(
                                                    area: area.copyWith(vertices: updatedPoints),
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
                                                }
                                              },
                                              inputEvents: FusionCanvasInputEvents(
                                                onMouseUp: (FusionCanvasInputTapUpState event) {
                                                  final BuildingPageViewModel buildingPageViewModel = context.read<BuildingPageViewModel>();
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
                                                onPathClosed: (List<FusionCanvasPoint> value) {
                                                  final ProjectViewModel projectVM = serviceLocator<ProjectViewModel>();
                                                  final ListeningArea listeningArea = ListeningArea(
                                                    vertices: value,
                                                    name: "Listening Area ${projectVM.listeningAreas.length + 1}",
                                                  );
                                                  projectVM.addListeningArea(
                                                    area: listeningArea,
                                                    floorId: floor.id,
                                                  );
                                                  projectVM.setCurrentSelectedHardware(null);
                                                  projectVM.setCurrentSelectedListeningArea(listeningArea.id);

                                                  calculateSpl(context);
                                                },
                                              ),
                                            ),
                                            builder:
                                                (BuildContext context) => Stack(
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
                                                    const Align(
                                                      alignment: Alignment.bottomCenter,
                                                      child: Padding(
                                                        padding: EdgeInsets.all(20),
                                                        child: CanvasToolBar(),
                                                      ),
                                                    ),
                                                  ],
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
                                      ),
                                    ),
                                  ),

                                  if (floor.floorPlan.imagePath.isEmpty) ...<Widget>[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(245, 65, 2, 16),
                                      child: _buildEmptyFloorWidget(),
                                    ),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),

                    //SPL range slider
                  ],
                ),
              ),
            ],
          );
        },
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
            semanticId: 'building_canvas_upload_floor_plan',
            step: GuideShowCaseSteps.uploadFloorPlan,
            onHighlightedSpotTap: (TapDownDetails details) => _showFloorPlanPicker(),
            child: FusionOutlinedButton(
              accessLabel: 'upload_floor_plan',
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
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.elevation1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 720,
            height: 500,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(right: 8),
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
                const SizedBox(height: 8),

                // Import Section (Primary)
                Expanded(
                  flex: 2,
                  child: _buildImportSection(ctx),
                ),

                const SizedBox(height: 16),

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
        );
      },
    );
  }

  Widget _buildImportSection(BuildContext ctx) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> details) => true,
      onAcceptWithDetails: (DragTargetDetails<String> details) => _importFloorPlan(),
      builder: (BuildContext context, List<String?> candidateData, List<dynamic> rejectedData) {
        final bool isDragActive = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _importFloorPlan(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDragActive ? Theme.of(context).colorScheme.primaryColor.withValues(alpha: 0.05) : context.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: isDragActive ? 2 : 1,
                color: isDragActive ? Theme.of(context).colorScheme.primaryWhite : context.colorScheme.elevation2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  isDragActive ? LucideIcons.download200 : LucideIcons.cloudUpload200,
                  size: 48,
                  color: context.colorScheme.primaryWhite,
                ),
                const SizedBox(height: 16),
                FusionAppText(
                  text: isDragActive ? 'Drop your file here!' : 'Click here to upload',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: isDragActive ? context.colorScheme.primaryWhite : context.colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                FusionAppText(
                  text: 'Upload .PDF, .JPEG or .PNG\nfiles (max file size- 5MB)',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isDragActive ? context.colorScheme.primaryWhite : context.colorScheme.elevation4,
                  ),
                ),
                const SizedBox(height: 8),
                FusionNeumorphicButton(
                  semanticId: "import_floor_plan",
                  height: 36,
                  width: 140,
                  text: 'Browse Files',
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        'floor_plan_sample_${index + 1}',
      ),
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
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
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
    serviceLocator<GuideShowCaseController>().completeStep(
      GuideShowCaseSteps.uploadFloorPlan,
    );

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
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: <String>['png', 'jpg', 'jpeg', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final String sourcePath = result.files.single.path!;
        final String fileName = result.files.single.name;

        // Enforce 5 MB maximum file size
        const int maxBytes = 5 * 1024 * 1024; // 5 MB
        final int fileSize = result.files.single.size;
        if (fileSize > maxBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File is too large. Maximum allowed size is 5 MB.'),
              ),
            );
          }
          return;
        }

        // Handle PDF files: convert selected page to image first
        String imagePath = sourcePath;
        if (fileName.toLowerCase().endsWith('.pdf')) {
          final String? convertedPath = await _handlePdfImport(sourcePath);
          if (convertedPath == null) return; // User cancelled page selection
          imagePath = convertedPath;
        }

        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
          );

          final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(
            imagePath: imagePath,
          );

          if (mounted) Navigator.of(context).pop();

          // ignore: use_build_context_synchronously
          serviceLocator<GuideShowCaseController>().completeStep(
            GuideShowCaseSteps.uploadFloorPlan,
          );

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
          content: FusionAppText(
            text: 'Error importing floor plan: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Opens a PDF, and if it has multiple pages shows a page selection dialog.
  /// Returns the path to a temporary PNG image of the selected page, or null if cancelled.
  Future<String?> _handlePdfImport(String pdfPath) async {
    final PdfDocument document = await PdfDocument.openFile(pdfPath);
    try {
      final int pageCount = document.pages.length;

      if (pageCount == 1) {
        return _renderPdfPageToFile(document.pages[0]);
      }

      // Multi-page: show selection dialog
      if (!mounted) return null;
      final int? selectedIndex = await showDialog<int>(
        context: context,
        builder: (BuildContext ctx) => _PdfPageSelectionDialog(document: document),
      );

      if (selectedIndex == null) return null;
      return _renderPdfPageToFile(document.pages[selectedIndex]);
    } finally {
      document.dispose();
    }
  }

  /// Renders a single PDF page at 4x resolution (288 dpi) and saves as a temp PNG file.
  Future<String> _renderPdfPageToFile(PdfPage page) async {
    const double scale = 4.0; // 72 dpi * 4 = 288 dpi
    final PdfImage? pdfImage = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: Colors.white,
    );
    if (pdfImage == null) throw Exception('Failed to render PDF page');

    final ui.Image uiImage = await pdfImage.createImage();
    pdfImage.dispose();

    final ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    uiImage.dispose();
    if (byteData == null) throw Exception('Failed to encode PDF page as PNG');

    final String tempPath = '${Directory.systemTemp.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(tempPath).writeAsBytes(byteData.buffer.asUint8List());
    return tempPath;
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
        builder: (_) {
          return Dialog(
            insetPadding: const EdgeInsets.all(100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: context.colorScheme.elevation1,
            child: FloorPlanCalibrationDialog(
              floorPlanImage: image,
              onCalibrationComplete: (CalibrationData data) {
                serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.confirmFloorCalibrated);
                if (context.mounted) Navigator.of(context).pop(data);
              },
              onCancel: () {
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          );
        },
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
        final Size floorPlanSize = Size(
          canvasWidthInPixels,
          canvasHeightInPixels,
        );

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
          final String croppedImagePath = await _saveCroppedImage(
            calibrationData.croppedImage!,
            savedImagePath,
          );
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
        serviceLocator<GuideShowCaseController>().completeStep(
          GuideShowCaseSteps.confirmFloorCalibrated,
        );
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

  Future<String> _saveCroppedImage(
    ui.Image croppedImage,
    String originalImagePath,
  ) async {
    // Convert the cropped image to byte data
    final ByteData? byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
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

class SplSlider extends StatelessWidget {
  const SplSlider({
    super.key,
    required this.splRangeController,
    required this.splPanelData,
  });

  final SplRangeController? splRangeController;
  final SplPanelData splPanelData;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: BlocBuilder<BuildingPageViewModel, BuildingPageState>(
        builder: (BuildContext context, BuildingPageState state) {
          final bool isShowingSpl = context.watch<BuildingPageViewModel>().isSplMode;
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
                  controller: splRangeController,
                  minValue: serviceLocator<ProjectViewModel>().minSPL,
                  maxValue: serviceLocator<ProjectViewModel>().maxSPL,
                  invertedColors: splPanelData.splInvertColor,
                  onChanged: (double min, double max) {
                    // debugPrint("SPL Range changed: ${min.round()} - ${max.round()}");
                    serviceLocator<ProjectViewModel>().setMinSPL(minSPL: min, autoSave: false);
                    serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: max);
                    // if (!showLiveSpl) {
                    //   setState(() {
                    //     showLiveSpl = true;
                    //   });
                    // }
                  },
                  onChangeEnd: (double min, double max) {
                    // debugPrint("SPL Range change ended: ${min.round()} - ${max.round()}");
                    serviceLocator<ProjectViewModel>().setMinSPL(minSPL: min, autoSave: false);
                    serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: max);
                    // serviceLocator<ProjectViewModel>().saveProjectToLocal();
                    // if (showLiveSpl) {
                    //   setState(() {
                    //     showLiveSpl = false;
                    //   });
                    // }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Dialog that displays PDF page thumbnails and lets the user select one.
class _PdfPageSelectionDialog extends StatefulWidget {
  final PdfDocument document;

  const _PdfPageSelectionDialog({required this.document});

  @override
  State<_PdfPageSelectionDialog> createState() => _PdfPageSelectionDialogState();
}

class _PdfPageSelectionDialogState extends State<_PdfPageSelectionDialog> {
  int? _selectedIndex;
  final Map<int, ui.Image?> _thumbnails = <int, ui.Image?>{};

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  Future<void> _loadThumbnails() async {
    for (int i = 0; i < widget.document.pages.length; i++) {
      final PdfPage page = widget.document.pages[i];
      // Render at 1x (72 dpi) for thumbnails
      final PdfImage? pdfImage = await page.render(fullWidth: page.width, fullHeight: page.height, backgroundColor: Colors.white);
      if (pdfImage != null) {
        final ui.Image image = await pdfImage.createImage();
        pdfImage.dispose();
        if (mounted) {
          setState(() => _thumbnails[i] = image);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final ui.Image? image in _thumbnails.values) {
      image?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int pageCount = widget.document.pages.length;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.elevation1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.all(100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FusionAppText(
                  text: 'Select a Page ($pageCount pages)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: context.colorScheme.primaryWhite, size: 20),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Page grid
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colorScheme.strokeLight,
                    width: 1,
                  ),
                ),
                child: GridView.builder(
                  itemCount: pageCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (BuildContext context, int index) {
                    final bool isSelected = _selectedIndex == index;
                    final ui.Image? thumbnail = _thumbnails[index];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primaryColor : context.colorScheme.strokeLight,
                            width: isSelected ? 2 : 1,
                          ),
                          color: context.colorScheme.elevation1,
                        ),
                        child: Builder(
                          builder: (BuildContext context) {
                            if (thumbnail != null) {
                              return RawImage(image: thumbnail, fit: BoxFit.contain);
                            } else {
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Confirm button
            Align(
              alignment: Alignment.centerRight,
              child: FusionNeumorphicButton(
                semanticId: 'pdf_page_import',
                height: 36,
                width: 120,
                text: 'Import',
                enabled: _selectedIndex != null,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                onTap: () => Navigator.of(context).pop(_selectedIndex),
              ),
            ),
          ],
        ),
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
