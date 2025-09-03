import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_utils/image_loader_service.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../core/mace_calculation_manager.dart';
import '../../../../core/mace_engine_provider.dart';
import '../../../../core/widgets/clean_widgets.dart';
import '../../../../core/widgets/spl_range_slider.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class BuildingCanvas extends StatefulWidget {
  const BuildingCanvas({super.key});

  @override
  State<BuildingCanvas> createState() => _BuildingCanvasState();
}

class _BuildingCanvasState extends State<BuildingCanvas> {
  MaceEngine? engine;
  Offset viewPortCenter = Offset.zero;
  final FloorCanvasController floorCanvasController = FloorCanvasController();
  bool splInitCalculated = false;

  @override
  void initState() {
    super.initState();
    // initFloorsTabs();
    initMace();
  }

  @override
  void dispose() {
    if (engine != null) engine!.dispose();
    super.dispose();
  }

  /// Initialize MACE engine for SPL calculations
  Future<void> initMace() async {
    if (Platform.isMacOS || Platform.isIOS) {
      WidgetsFlutterBinding.ensureInitialized();
      engine = await MaceEngine.create();
    }
  }

  /// if floors get added/removed, rebuild the TabController…
  onFloorUpdated() {
    // final int newLen = serviceLocator<ProjectViewModel>().floors.length;
    // if (_tabController.length != newLen) {
    //   if (mounted) {
    //     _tabController = TabController(length: newLen, vsync: this, initialIndex: serviceLocator<ProjectViewModel>().currentFloorIndex)..addListener(() {
    //       if (!_tabController.indexIsChanging) return;
    //       serviceLocator<ProjectViewModel>().setCurrentFloorIndex(_tabController.index);
    //       WidgetsBinding.instance.addPostFrameCallback((_) {
    //         calculateSPL();
    //       });
    //     });
    //     setState(() {});
    //   }
    // }
  }

  Future<void> calculateSPL() async {
    if (engine != null) {
      if (!floorCanvasController.isShowingSpl.value) {
        return;
      }

      final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
      if (currentFloorIndex != -1 && serviceLocator<ProjectViewModel>().floors[currentFloorIndex].listeningAreaIds.isNotEmpty) {
        final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];
        final List<Speaker> speakers = List<Speaker>.from(
          serviceLocator<ProjectViewModel>().getHardwareForFloor(currentFloor.id).whereType<Speaker>(),
        );
        final List<ListeningArea> surfaces = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(currentFloor.id);
        final List<SPLCalculation> surfaceCalculations = await SPLCalculationManager.calculateSpl(
          engine!,
          speakers,
          surfaces,
        );

        for (final SPLCalculation calc in surfaceCalculations) {
          final List<ui.Offset> pts = calc.surface.getFieldPoints();
          calc.surface.setSplData(pts, calc.spl);
        }
        splInitCalculated = true;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                        if (state is FloorsUpdated) {
                          onFloorUpdated();
                        }
                      },
                      builder: (BuildContext context, ProjectViewModelState state) {
                        final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
                        final FloorModel floor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];
                        if (serviceLocator<ProjectViewModel>().floors.isEmpty) {
                          return _buildEmptyFloorWidget();
                        }
                        return FloorCanvas(
                          gridSize: 100,
                          controller: floorCanvasController,
                          hardwareComponents: serviceLocator<ProjectViewModel>().getHardwareForFloor(floor.id),
                          listeningAreas: serviceLocator<ProjectViewModel>().getListeningAreasForFloor(floor.id),
                          floor: floor,
                          floorPlanEntity: floor.floorPlan,
                          onUpdateHardwareComponent: serviceLocator<ProjectViewModel>().updateHardware,
                          zones: serviceLocator<ProjectViewModel>().zones,
                          onCanvasZoomChanged: (double z) {
                            serviceLocator<ProjectViewModel>().updateFloor(
                              floor.copyWith(floorPlan: floor.floorPlan.copyWith(canvasZoom: z)),
                            );
                            if (floorCanvasController.isShowingSpl.value && splInitCalculated) {
                              calculateSPL();
                            }
                          },
                          onCanvasPanChanged: (ui.Offset p) {
                            serviceLocator<ProjectViewModel>().updateFloor(
                              floor.copyWith(floorPlan: floor.floorPlan.copyWith(canvasPan: p)),
                            );
                          },
                          moveHardware: (HardwareComponent hardware, String? newListeningAreaId, String? floorId) {
                            serviceLocator<ProjectViewModel>().moveHardware(hardware.id, floorId: floorId, listeningAreaId: newListeningAreaId);
                            serviceLocator<ProjectViewModel>().saveProjectToLocal();
                          },
                          onAddListeningArea: (ListeningArea created, List<HardwareComponent>? containedHardware) {
                            serviceLocator<ProjectViewModel>().addListeningArea(created, floor.id);
                            if (containedHardware != null) {
                              for (final HardwareComponent hc in containedHardware) {
                                serviceLocator<ProjectViewModel>().moveHardware(
                                  hc.id,
                                  listeningAreaId: created.id,
                                  floorId: floor.id,
                                );
                              }
                            }

                            calculateSPL();
                            serviceLocator<ProjectViewModel>().saveProjectToLocal();
                          },
                          onUpdateListeningArea: serviceLocator<ProjectViewModel>().updateListeningArea,
                          onFloorPlanUpdated: (FloorPlanModel updatedPlan) {
                            serviceLocator<ProjectViewModel>().updateFloor(
                              floor.copyWith(floorPlan: updatedPlan),
                            );
                          },
                          onViewportCenterUpdated: (ui.Offset center) {
                            viewPortCenter = center;
                          },
                          onComponentTransformed: (dynamic component) {
                            if (component is Speaker || component is ListeningArea) {
                              calculateSPL();
                            }
                            serviceLocator<ProjectViewModel>().saveProjectToLocal();
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
                        );
                      },
                    ),
                  ),

                  // Clean floating toolbar
                  Visibility(
                    visible: true, // !projectManager.isFloorEmpty(projectManager.currentFloor.id),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: floorCanvasController.isListeningAreaSelectionActive,
                          builder: (_, bool isActive, __) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isActive
                                        ? FusionUtils.hexToColor(floorCanvasController.currentlySelectingZone!.zoneColor).withValues(alpha: 0.75)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.grey.shade400.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8,
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
                                          'Select listening areas for ${floorCanvasController.currentlySelectingZone!.name}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            // color: Colors.grey.shade700,
                                            color:
                                                ThemeData.estimateBrightnessForColor(
                                                          FusionUtils.hexToColor(floorCanvasController.currentlySelectingZone!.zoneColor),
                                                        ) ==
                                                        Brightness.light
                                                    ? Colors.grey.shade800
                                                    : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        CleanToolbarButton(
                                          icon: Icons.close,
                                          tooltip: 'Cancel selection',
                                          onPressed: () => floorCanvasController.cancelListeningAreaSelection(),
                                        ),
                                        const SizedBox(width: 12),
                                        CleanToolbarButton(
                                          icon: Icons.check,
                                          tooltip: 'Confirm selection',
                                          onPressed: () => floorCanvasController.completeListeningAreaSelection(),
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      ValueListenableBuilder<bool>(
                                        valueListenable: floorCanvasController.isDrawing,
                                        builder:
                                            (_, bool isDrawing, __) => CleanToggleButton(
                                              icon: Icons.edit,
                                              tooltip: isDrawing ? 'Stop drawing' : 'Draw listening area',
                                              isActive: isDrawing,
                                              onPressed: () => floorCanvasController.toggleDraw(),
                                            ),
                                      ),

                                      const SizedBox(width: 8),

                                      CleanToolbarButton(
                                        icon: Icons.add_photo_alternate,
                                        tooltip: 'Load plan',
                                        onPressed: _showFloorPlanPicker,
                                      ),

                                      const SizedBox(width: 8),

                                      if (Platform.isMacOS || Platform.isIOS)
                                        ValueListenableBuilder<bool>(
                                          valueListenable: floorCanvasController.isShowingSpl,
                                          builder:
                                              (_, bool showSpl, __) => Row(
                                                children: <Widget>[
                                                  CleanToggleButton(
                                                    icon: Icons.graphic_eq,
                                                    tooltip: showSpl ? 'Hide SPL' : 'Show SPL',
                                                    isActive: showSpl,
                                                    onPressed: () {
                                                      floorCanvasController.toggleSpl();
                                                      calculateSPL();
                                                    },
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                              ),
                                        ),

                                      CleanToolbarButton(
                                        icon: Icons.fit_screen,
                                        tooltip: 'Fit to view',
                                        onPressed: () => floorCanvasController.fitToView(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  //SPL range slider
                  ValueListenableBuilder<bool>(
                    valueListenable: floorCanvasController.isShowingSpl,
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
                              minValue: serviceLocator<ProjectViewModel>().minSPL,
                              maxValue: serviceLocator<ProjectViewModel>().maxSPL,
                              onChanged: (double min, double max) {
                                debugPrint("SPL Range changed: ${min.round()} - ${max.round()}");
                                serviceLocator<ProjectViewModel>().setMinSPL(min);
                                serviceLocator<ProjectViewModel>().setMaxSPL(max);
                              },
                              onChangeEnd: (double min, double max) {
                                debugPrint("SPL Range change ended: ${min.round()} - ${max.round()}");

                                serviceLocator<ProjectViewModel>().setMinSPL(min);
                                serviceLocator<ProjectViewModel>().setMaxSPL(max);
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

            // Clean header with tabs
            // Container(
            //   decoration: BoxDecoration(
            //     // color: Colors.grey.shade100,
            //     border: Border(
            //       top: BorderSide(
            //         color: Colors.grey.shade300,
            //         width: 1,
            //       ),
            //     ),
            //   ),
            //   child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            //     builder: (BuildContext context, ProjectViewModelState state) {
            //       return Row(
            //         children: <Widget>[
            //           // Clean Floors TabBar
            //           Expanded(
            //             child: Theme(
            //               data: Theme.of(context).copyWith(
            //                 tabBarTheme: TabBarThemeData(
            //                   labelColor: Colors.grey.shade800,
            //                   unselectedLabelColor: Colors.grey.shade500,
            //                   indicatorSize: TabBarIndicatorSize.label,
            //                   dividerColor: Colors.transparent,
            //                   labelStyle: const TextStyle(
            //                     fontSize: 13,
            //                     fontWeight: FontWeight.w500,
            //                   ),
            //                   unselectedLabelStyle: const TextStyle(
            //                     fontSize: 13,
            //                     fontWeight: FontWeight.w400,
            //                   ),
            //                   indicator: UnderlineTabIndicator(
            //                     borderSide: BorderSide(color: Colors.grey.shade800, width: 3.0),
            //                     insets: const EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 46.0),
            //                   ),
            //                 ),
            //               ),
            //               child: TabBar(
            //                 controller: _tabController,
            //                 isScrollable: true,
            //                 tabAlignment: TabAlignment.start,
            //                 tabs: serviceLocator<ProjectViewModel>().floors.map((FloorModel f) => Tab(text: f.name)).toList(),
            //               ),
            //             ),
            //           ),
            //
            //           const SizedBox(width: 12),
            //
            //           // Clean action buttons
            //           CleanIconButton(
            //             icon: Icons.add,
            //             tooltip: 'Add new floor',
            //             onPressed: () => _showAddFloorDialog(context),
            //           ),
            //
            //           const SizedBox(width: 8),
            //
            //           CleanIconButton(
            //             icon: Icons.schema_outlined,
            //             tooltip: 'Schematics',
            //             onPressed: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute<AmplifierMatchingPage>(
            //                   builder: (_) => const AmplifierMatchingPage(),
            //                 ),
            //               );
            //             },
            //           ),
            //
            //           const SizedBox(width: 8),
            //
            //           // CleanIconButton(
            //           //   icon: Icons.speaker_group_sharp,
            //           //   tooltip: 'Source Sets',
            //           //   onPressed: () {
            //           //     Navigator.push(
            //           //       context,
            //           //       MaterialPageRoute<AudioSystemDesignPage>(
            //           //         builder: (_) => const AudioSystemDesignPage(),
            //           //       ),
            //           //     );
            //           //   },
            //           // ),
            //           //
            //           // const SizedBox(width: 8),
            //         ],
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // Future<void> _showAddFloorDialog(BuildContext context) async {
  //   String? newName;
  //
  //   await showDialog(
  //     context: context,
  //     builder:
  //         (BuildContext ctx) => CleanDialog(
  //           title: 'New Floor',
  //           actions: <Widget>[
  //             TextButton(
  //               onPressed: () => Navigator.pop(ctx),
  //               child: Text(
  //                 'Cancel',
  //                 style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
  //               ),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 if (newName?.trim().isNotEmpty ?? false) {
  //                   final FloorPlanModel plan = FloorPlanModel.defaultFloorPlan;
  //                   serviceLocator<ProjectViewModel>().addFloor(
  //                     FloorModel(name: newName!.trim(), floorPlan: plan),
  //                   );
  //                   serviceLocator<ProjectViewModel>().saveProjectToLocal();
  //                   Navigator.pop(ctx);
  //                 }
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.grey.shade800,
  //                 foregroundColor: Colors.white,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(4),
  //                 ),
  //                 elevation: 0,
  //               ),
  //               child: const Text(
  //                 'Create',
  //                 style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  //               ),
  //             ),
  //           ],
  //           child: TextField(
  //             autofocus: true,
  //             style: const TextStyle(fontSize: 14),
  //             decoration: InputDecoration(
  //               hintText: 'Floor name',
  //               hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
  //               contentPadding: const EdgeInsets.symmetric(
  //                 horizontal: 12,
  //                 vertical: 8,
  //               ),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(4),
  //                 borderSide: BorderSide(color: Colors.grey.shade300),
  //               ),
  //               enabledBorder: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(4),
  //                 borderSide: BorderSide(color: Colors.grey.shade300),
  //               ),
  //               focusedBorder: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(4),
  //                 borderSide: BorderSide(color: Colors.grey.shade600),
  //               ),
  //               filled: true,
  //               fillColor: Colors.white,
  //             ),
  //             onChanged: (String v) => newName = v,
  //           ),
  //         ),
  //   );
  //
  //   _tabController.animateTo(serviceLocator<ProjectViewModel>().floors.length - 1);
  // }

  Widget _buildEmptyFloorWidget() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Upload Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.upload_file,
                size: 40,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Add Floor plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Use a floor plan to define the space for your audio setup.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Upload Button
            ElevatedButton(
              onPressed: () {
                _showFloorPlanPicker();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Import File',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
    final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addAssetImageToProject(assetImagePath);
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
        final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(sourcePath);
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
              child: FloorPlanCalibration(
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

        final double widthInUnits = image.width * calibrationData.unitsPerPixel;
        final double heightInUnits = image.height * calibrationData.unitsPerPixel;

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

        serviceLocator<ProjectViewModel>().updateFloor(
          floor.copyWith(
            floorPlan: floor.floorPlan.copyWith(
              imagePath: savedImagePath,
              position: floor.floorPlan.imagePath.isNotEmpty ? floor.floorPlan.position : viewPortCenter,
              size: floorPlanSize,
            ),
          ),
        );

        floorCanvasController.loadFloorPlanImage();
        serviceLocator<ProjectViewModel>().saveProjectToLocal();
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
}
