import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_utils/image_loader_service.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../core/mace_calculation_manager.dart';
import '../../../../core/mace_engine_provider.dart';
import '../../../../core/models/floor_entity.dart';
import '../../../../core/models/products_data.dart';
import '../../../../core/models/project_entity.dart';
import '../../../../core/services/project_manager.dart';
import '../../../../core/widgets/clean_widgets.dart';
import '../../../../core/widgets/spl_range_slider.dart';
import '../../../schematics/presentation/pages/amplifier_matching_page.dart';
import '../widgets/products_sidebar.dart';
import '../widgets/properties/properties_side_bar.dart';
import '../widgets/zones_panel/zones_panel.dart';

class FloorPlanProjectEditor extends StatefulWidget {
  const FloorPlanProjectEditor({super.key});

  @override
  FloorPlanProjectEditorState createState() => FloorPlanProjectEditorState();
}

class FloorPlanProjectEditorState extends State<FloorPlanProjectEditor> with TickerProviderStateMixin {
  late final ProjectManager projectManager;
  MaceEngine? engine;
  Offset viewPortCenter = Offset.zero;
  final FloorCanvasController floorCanvasController = FloorCanvasController();
  late TabController _tabController;
  bool splInitCalculated = false;

  @override
  void initState() {
    super.initState();
    projectManager = serviceLocator<ProjectManager>();
    initFloorsTabs();
    initMace();
  }

  @override
  void dispose() {
    if (engine != null) engine!.dispose();
    super.dispose();
  }

  void initFloorsTabs() {
    _tabController = TabController(
      animationDuration: const Duration(milliseconds: 1), // No animation for tab changes
      length: projectManager.value.floors.length,
      vsync: this,
      initialIndex: projectManager.value.currentFloorIndex,
    );

    // when user taps a tab, switch floors in the manager…
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      if (_tabController.index == projectManager.value.currentFloorIndex) return;
      projectManager.setCurrentFloor(_tabController.index);
    });

    // if floors get added/removed, rebuild the TabController…
    projectManager.addListener(() {
      final int newLen = projectManager.value.floors.length;
      if (_tabController.length != newLen) {
        if (mounted) {
          _tabController = TabController(length: newLen, vsync: this, initialIndex: projectManager.value.currentFloorIndex)..addListener(() {
            if (!_tabController.indexIsChanging) return;
            projectManager.setCurrentFloor(_tabController.index);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              calculateSPL();
            });
          });
          setState(() {});
        }
      }
    });
  }

  Future<void> initMace() async {
    if (Platform.isMacOS || Platform.isIOS) {
      WidgetsFlutterBinding.ensureInitialized();
      engine = await MaceEngine.create();
    }
  }

  Future<void> calculateSPL() async {
    if (engine != null) {
      if (!floorCanvasController.isShowingSpl.value) {
        return;
      }

      if (projectManager.currentFloor.listeningAreas.isNotEmpty) {
        final List<Speaker> speakers = List<Speaker>.from(
          projectManager.getSpeakersInFloor(projectManager.currentFloor.id),
        );
        final List<ListeningArea> surfaces = List<ListeningArea>.from(
          projectManager.currentFloor.listeningAreas,
        );
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
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left sidebar
            Container(
              width: 200,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: <Widget>[
                  // Sidebar Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.widgets_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Library',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ProductsSidebar(
                      onSpeakerSelected: (SpeakerData speakerData) {
                        final Speaker cs = Speaker(
                          name: speakerData.name,
                          speakerSKU: speakerData.sku,
                          gain:
                              speakerData.sku == "MSA12X"
                                  ? 50.0
                                  : speakerData.sku == "CO-12 H120"
                                  ? 10.0
                                  : 0.0,
                          pos: viewPortCenter,
                          rotation: 0.0,
                          assetImagePath: speakerData.assetPath,
                          type: speakerData.type,
                          locationEntity: LocationEntity(
                            floorId: projectManager.currentFloor.id,
                          ),
                          price: speakerData.price,
                        );
                        projectManager.addHardwareComponent(cs);
                        projectManager.setSelectedHardwareComponentId(cs.id);
                        floorCanvasController.setHardwareComponentListeningAreaId(cs);
                        floorCanvasController.setSelectedHardwareComponent(cs);
                        calculateSPL();
                        projectManager.saveProject();
                      },
                      onProductSelected: (GenericHardwareComponent product) {
                        product = product.copyWith(
                          pos: viewPortCenter,
                          locationEntity: LocationEntity(
                            floorId: projectManager.currentFloor.id,
                          ),
                        );
                        projectManager.addHardwareComponent(product);
                        projectManager.setSelectedHardwareComponentId(
                          product.id,
                        );
                        floorCanvasController.setSelectedHardwareComponent(
                          product,
                        );
                        floorCanvasController.setHardwareComponentListeningAreaId(product);
                        projectManager.saveProject();
                      },
                      onSourceSelected: (Source source) {
                        source = source.copyWith(
                          pos: viewPortCenter,
                          locationEntity: LocationEntity(
                            floorId: projectManager.currentFloor.id,
                          ),
                        );
                        projectManager.addHardwareComponent(source);
                        projectManager.setSelectedHardwareComponentId(
                          source.id,
                        );
                        floorCanvasController.setSelectedHardwareComponent(
                          source,
                        );
                        floorCanvasController.setHardwareComponentListeningAreaId(source);
                        projectManager.saveProject();
                      },
                      onAutoPlaceRequested: (SpeakerData speakerData) async {
                        final List<ui.Offset>? points = await floorCanvasController.requestAutoPlace();

                        if (points == null) return;

                        for (final ui.Offset pt in points) {
                          final Speaker speaker = Speaker(
                            name: speakerData.name,
                            speakerSKU: speakerData.sku,
                            gain: 0,
                            pos: pt,
                            rotation: 0.0,
                            assetImagePath: speakerData.assetPath,
                            type: speakerData.type,
                            locationEntity: LocationEntity(
                              floorId: projectManager.currentFloor.id,
                            ),
                            price: speakerData.price,
                          );
                          projectManager.addHardwareComponent(speaker);
                          projectManager.setSelectedHardwareComponentId(
                            speaker.id,
                          );
                          floorCanvasController.setHardwareComponentListeningAreaId(speaker);
                        }
                        calculateSPL();
                        projectManager.saveProject();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Canvas area
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  // color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
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
                            child: ValueListenableBuilder<ProjectEntity>(
                              valueListenable: projectManager,
                              builder: (_, ProjectEntity project, __) {
                                final Floor floor = project.currentFloor;
                                if (projectManager.isFloorEmpty(floor.id)) {
                                  return _buildEmptyFloorWidget();
                                }
                                return FloorCanvas(
                                  gridSize: 100,
                                  controller: floorCanvasController,
                                  hardwareComponents: projectManager.getHardwareComponentsInFloor(floor.id),
                                  listeningAreas: floor.listeningAreas,
                                  floorPlanEntity: floor.floorPlan,
                                  onUpdateHardwareComponent: projectManager.updateHardwareComponent,
                                  zones: project.zones,
                                  onCanvasZoomChanged: (double z) {
                                    projectManager.updateFloorPlan(
                                      floor.floorPlan.copyWith(canvasZoom: z),
                                    );
                                  },
                                  onCanvasPanChanged: (ui.Offset p) {
                                    projectManager.updateFloorPlan(
                                      floor.floorPlan.copyWith(canvasPan: p),
                                    );
                                  },
                                  onAddListeningArea: (ListeningArea created) {
                                    projectManager.addListeningArea(created);
                                    calculateSPL();
                                    projectManager.setSelectedSurfaceId(
                                      created.id,
                                    );
                                    projectManager.saveProject();
                                  },
                                  onUpdateListeningArea: projectManager.updateListeningArea,
                                  onFloorPlanUpdated: (FloorPlanEntity updatedPlan) {
                                    projectManager.updateFloorPlan(updatedPlan);
                                  },
                                  onViewportCenterUpdated: (ui.Offset center) {
                                    viewPortCenter = center;
                                  },
                                  onComponentTransformed: (dynamic component) {
                                    if (component is Speaker || component is ListeningArea) {
                                      calculateSPL();
                                    }
                                    projectManager.saveProject();
                                  },
                                  onTapListeningArea: (ListeningArea value) {},
                                  onSelectedListeningAreaIdChanged: (String? value) {
                                    projectManager.setSelectedSurfaceId(value);
                                  },
                                  onSelectedHardwareComponentIdChanged: (String? value) {
                                    projectManager.setSelectedHardwareComponentId(value);
                                  },
                                  onSelectedFloorPlanIdChanged: () {
                                    projectManager.setSelectedFloorPlanId(
                                      floor.id,
                                    );
                                  },
                                  splMin: project.minSPL,
                                  splMax: project.maxSPL,
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
                                      minValue: projectManager.value.minSPL,
                                      maxValue: projectManager.value.maxSPL,
                                      onChanged: (double min, double max) {
                                        print("SPL Range changed: ${min.round()} - ${max.round()}");
                                        projectManager.value = projectManager.value.copyWith(
                                          maxSPL: max,
                                          minSPL: min,
                                        );
                                      },
                                      onChangeEnd: (double min, double max) {
                                        print("SPL Range change ended: ${min.round()} - ${max.round()}");
                                        projectManager.value = projectManager.value.copyWith(
                                          maxSPL: max,
                                          minSPL: min,
                                        );
                                        projectManager.saveProject();
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
                    Container(
                      decoration: BoxDecoration(
                        // color: Colors.grey.shade100,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: ValueListenableBuilder<ProjectEntity>(
                        valueListenable: projectManager,
                        builder: (_, ProjectEntity project, __) {
                          return Row(
                            children: <Widget>[
                              // Clean Floors TabBar
                              Expanded(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    tabBarTheme: TabBarThemeData(
                                      labelColor: Colors.grey.shade800,
                                      unselectedLabelColor: Colors.grey.shade500,
                                      indicatorSize: TabBarIndicatorSize.label,
                                      dividerColor: Colors.transparent,
                                      labelStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      unselectedLabelStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      indicator: UnderlineTabIndicator(
                                        borderSide: BorderSide(color: Colors.grey.shade800, width: 3.0),
                                        insets: const EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 46.0),
                                      ),
                                    ),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    tabs: projectManager.value.floors.map((Floor f) => Tab(text: f.name)).toList(),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Clean action buttons
                              CleanIconButton(
                                icon: Icons.add,
                                tooltip: 'Add new floor',
                                onPressed: () => _showAddFloorDialog(context),
                              ),

                              const SizedBox(width: 8),

                              CleanIconButton(
                                icon: Icons.schema_outlined,
                                tooltip: 'Schematics',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<AmplifierMatchingPage>(
                                      builder: (_) => const AmplifierMatchingPage(),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(width: 8),

                              // CleanIconButton(
                              //   icon: Icons.speaker_group_sharp,
                              //   tooltip: 'Source Sets',
                              //   onPressed: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute<AudioSystemDesignPage>(
                              //         builder: (_) => const AudioSystemDesignPage(),
                              //       ),
                              //     );
                              //   },
                              // ),
                              //
                              // const SizedBox(width: 8),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right sidebar
            Container(
              width: 240,
              margin: const EdgeInsets.all(12),
              child: ValueListenableBuilder<ProjectEntity>(
                valueListenable: projectManager,
                builder: (_, ProjectEntity project, __) {
                  return SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        // Properties Section
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Theme(
                            data: ThemeData().copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              title: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.tune,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Properties',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              initiallyExpanded: false,
                              children: <Widget>[
                                IntrinsicHeight(
                                  child: PropertiesSideBar(
                                    floor: projectManager.selectedFloorPlan,
                                    hardwareComponent: projectManager.selectedHardwareComponent,
                                    surface: projectManager.selectedListeningArea,
                                    onFloorChanged: (Floor floorEntity) {
                                      projectManager.updateFloor(floorEntity);
                                      calculateSPL();
                                      projectManager.saveProject();
                                    },
                                    onFloorDelete: (Floor floorEntity) {
                                      projectManager.removeFloor(
                                        floorEntity.id,
                                      );
                                      projectManager.saveProject();
                                    },
                                    onHardwareDelete: (
                                      HardwareComponent hardwareComponent,
                                    ) {
                                      projectManager.removeHardwareComponent(
                                        hardwareComponent.id,
                                      );
                                      calculateSPL();
                                      projectManager.saveProject();
                                    },
                                    onSurfaceDelete: (ListeningArea surface) {
                                      projectManager.removeListeningArea(
                                        surface.id,
                                      );
                                      projectManager.saveProject();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Zones Section
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Theme(
                            data: ThemeData().copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              title: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.layers,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Zones',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              initiallyExpanded: false,
                              children: <Widget>[
                                IntrinsicHeight(
                                  child: ZonesPanel(
                                    zones: projectManager.value.zones,
                                    getZoneListeningAreas: (String zoneId) => projectManager.getListeningAreasInZone(zoneId),
                                    getListeningAreaFloor: (String listeningAreaId) => projectManager.getFloorByListeningAreaId(listeningAreaId),
                                    onZoneAdded: (Zone zone) {
                                      projectManager.addZone(zone);
                                      projectManager.saveProject();
                                    },
                                    onZoneUpdated: (Zone zone) {
                                      projectManager.updateZone(zone);
                                      projectManager.saveProject();
                                    },
                                    onZoneDeleted: (Zone zone) {
                                      projectManager.removeZone(zone.id);
                                      projectManager.saveProject();
                                    },
                                    onAreaRemovedFromZone: (String removedAreaId) {
                                      //Remove the zone id from the removed areas
                                      final List<HardwareComponent> componentsInRemovedArea =
                                          projectManager.value.hardwareComponents
                                              .where((HardwareComponent hc) => removedAreaId == hc.locationEntity.listeningAreaId)
                                              .toList();

                                      final List<HardwareComponent> updatedRemovedComponents =
                                          componentsInRemovedArea
                                              .map(
                                                (HardwareComponent component) =>
                                                    component.copyWith(locationEntity: component.locationEntity.copyWith(zoneId: "")),
                                              )
                                              .toList();
                                      projectManager.updateHardwareList(
                                        updatedRemovedComponents,
                                      );
                                      projectManager.saveProject();
                                    },
                                    onRequestListeningAreaSelection: (Zone zone) async {
                                      print("Starting area selection");

                                      final List<ListeningArea>? selectedAreas = await floorCanvasController.requestListeningAreaSelection(
                                        projectManager.getListeningAreasInZone(zone.id),
                                        zone,
                                      );

                                      if (selectedAreas != null) {
                                        print("${selectedAreas.length} areas selected");

                                        final List<String> selectedAreaIds = selectedAreas.map((ListeningArea area) => area.id).toList();

                                        final List<String> removedAreaIds = zone.listeningAreasIds.where((String id) => !selectedAreaIds.contains(id)).toList();

                                        // if the selectedAreaIds are in any zone, remove them from those zones
                                        for (String selectedAreaId in selectedAreaIds) {
                                          for (Zone z in (projectManager.value.zones.where((Zone z) => z.listeningAreasIds.contains(selectedAreaId)))) {
                                            z.listeningAreasIds.remove(selectedAreaId);
                                          }
                                        }

                                        //update all the hardware entities that are using this zone and update their LocationEntity zone id
                                        final List<HardwareComponent> componentsInSelectedArea =
                                            projectManager.value.hardwareComponents
                                                .where(
                                                  (HardwareComponent hc) => selectedAreaIds.contains(
                                                    hc.locationEntity.listeningAreaId,
                                                  ),
                                                )
                                                .toList();

                                        final List<HardwareComponent> updatedComponents =
                                            componentsInSelectedArea
                                                .map(
                                                  (HardwareComponent component) => component.copyWith(
                                                    locationEntity: component.locationEntity.copyWith(
                                                      zoneId: zone.id,
                                                    ),
                                                  ),
                                                )
                                                .toList();

                                        projectManager.updateHardwareList(
                                          updatedComponents,
                                        );

                                        //Remove the zone id from the removed areas
                                        final List<HardwareComponent> componentsInRemovedArea =
                                            projectManager.value.hardwareComponents
                                                .where(
                                                  (HardwareComponent hc) => removedAreaIds.contains(hc.locationEntity.listeningAreaId),
                                                )
                                                .toList();

                                        final List<HardwareComponent> updatedRemovedComponents =
                                            componentsInRemovedArea
                                                .map(
                                                  (HardwareComponent component) =>
                                                      component.copyWith(locationEntity: component.locationEntity.copyWith(zoneId: "")),
                                                )
                                                .toList();

                                        projectManager.updateHardwareList(updatedRemovedComponents);

                                        projectManager.updateZone(
                                          zone.copyWith(
                                            listeningAreaIds: selectedAreaIds,
                                          ),
                                        );

                                        projectManager.saveProject();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

  Future<void> _showAddFloorDialog(BuildContext context) async {
    String? newName;

    await showDialog(
      context: context,
      builder:
          (BuildContext ctx) => CleanDialog(
            title: 'New Floor',
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newName?.trim().isNotEmpty ?? false) {
                    final FloorPlanEntity plan = FloorPlanEntity.defaultFloorPlan;
                    projectManager.addFloor(
                      Floor(name: newName!.trim(), floorPlan: plan),
                    );
                    projectManager.saveProject();
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            child: TextField(
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Floor name',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (String v) => newName = v,
            ),
          ),
    );

    _tabController.animateTo(projectManager.value.floors.length - 1);
  }

  // ------------------------------- //

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
    final String savedImagePath = await projectManager.saveAssetImageToProject(assetImagePath);
    _calibrateFloorPlan(savedImagePath);
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

        final String savedImagePath = await projectManager.saveImageToProject(sourcePath);

        _calibrateFloorPlan(savedImagePath);

        if (mounted) Navigator.of(context).pop();
        print('Floor plan imported successfully: $fileName');
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Error importing floor plan: $e');

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
        print('Calibration completed: $calibrationData');
        print('Scale: ${calibrationData.pixelsPerUnit.toStringAsFixed(2)} pixels per ${calibrationData.unit.symbol}');

        const double canvasPixelsPerMeter = 100.0;
        final Floor floor = projectManager.value.currentFloor;

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

        print('Real-world dimensions: ${widthInMeters.toStringAsFixed(2)}m x ${heightInMeters.toStringAsFixed(2)}m');
        print('Canvas dimensions: ${canvasWidthInPixels.toStringAsFixed(1)}px x ${canvasHeightInPixels.toStringAsFixed(1)}px');

        projectManager.updateFloorPlan(
          floor.floorPlan.copyWith(
            imagePath: savedImagePath,
            position: floor.floorPlan.imagePath.isNotEmpty ? floor.floorPlan.position : viewPortCenter,
            size: floorPlanSize,
          ),
        );

        floorCanvasController.loadFloorPlanImage();
        projectManager.saveProject();
      } else {
        print('Calibration cancelled by user');
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Error during calibration: $e');
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
