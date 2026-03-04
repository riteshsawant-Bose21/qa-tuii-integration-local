import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fusion_launcher/core/assets/asset_icons.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_launcher/core/spl_calculation/isolate_mace_calculation_manager.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/features/configuration_events/widgets/configuration_events.dart';
import 'package:fusion_launcher/features/create_new_project/views/create_new_project_dialog.dart';
import 'package:fusion_launcher/features/media_files/view/configuration_media_files_pages.dart';
import 'package:fusion_launcher/features/media_files/viewModel/media_files_view_model.dart';
import 'package:fusion_launcher/features/projects/view_model/project_sync_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/side_speaker_section.dart';
import 'package:fusion_launcher/features/scheduling/view/scheduling_page.dart';
import 'package:fusion_launcher/features/wiring_design/view/wiring_device_list_view.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/fusion_theme_notifier.dart';
import 'package:fusion_lib/models/dock_item_config.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/spl_calculation/mace_calculation_manager.dart';
import '../../../core/service_locator.dart';
import '../../../core/spl_calculation/ffi_constants.dart';
import '../../../core/spl_calculation/mace_engine_provider.dart';
import '../../../core/utils/broadcast_controllers.dart';
import '../../../core/utils/bug_report_popup.dart';
import '../../../core/widgets/clean_widgets.dart';
import '../../authentication/viewmodel/session_view_model.dart';
import '../../commission/presentation/pages/network_config_trigger_page.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../configuration_page/pages/configuration_events.dart';
import '../../configuration_page/pages/configuration_processing_page.dart';
import '../../configuration_snapshot/widgets/configuration_snapshots.dart';
import '../../control_dashboard/presentation/pages/fusion_control_dashboard.dart';
import '../../devices/presentation/pages/fusion_devices_page.dart';
import '../../devices/presentation/widgets/device_mapping_dialog.dart';
import '../../gpio/view/gpio_page.dart';
import '../../schematics/presentation/pages/schematics_page.dart';
import '../../schematics/presentation/widgets/cost_calculator_widget.dart';
import '../widget/building/building_canvas.dart';
import '../widget/building/side_panel_widgets/building_plan.dart';
import '../widget/building/side_panel_widgets/equipment_location/equipment_location_section.dart';
import '../widget/building/side_panel_widgets/listening_areas_panel.dart';
import '../widget/building/side_panel_widgets/properties_panel.dart';
import '../widget/building/side_panel_widgets/schematic_properties.dart';
import '../widget/building/side_panel_widgets/zone_and_listening_area.dart';
import '../widget/configuration/side_panel_widgets/configuration_tab_switcher.dart';
import '../widget/control_design_tab_switcher.dart';

class ProjectWorkArea extends StatefulWidget {
  const ProjectWorkArea({super.key});

  @override
  State<ProjectWorkArea> createState() => _ProjectWorkAreaState();
}

class _ProjectWorkAreaState extends State<ProjectWorkArea> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  StreamSubscription<int>? subscription;
  late TextEditingController _projectNameController;
  final FocusNode _projectNameFocusNode = FocusNode();
  final GlobalKey _projectNameKey = GlobalKey();
  String? _projectNameError;
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();

  final SplRangeController _splRangeController = SplRangeController();
  final FloorCanvasController _floorCanvasController = FloorCanvasController();
  MaceEngine? _engine;
  bool useIsolateEngine = true;

  bool get isListingViewMode => _projectViewModel.currentProjectMode == ProjectMode.systemListingMode;
  String _appVersion = '1.0.0';

  bool get isInDesignMode => !serviceLocator<ProjectViewModel>().isInControlMode;

  final List<Widget> _designTabs = const <Widget>[
    Tab(text: 'Building'),
    Tab(text: 'System'),
    // Tab(text: 'Cost'),
    Tab(text: 'Configuration'),
    // Tab(text: 'Cloud'),
  ];

  final List<Widget> _controlTabs = const <Widget>[
    Tab(text: 'Dashboard'),
    Tab(text: 'Devices'),
    Tab(text: 'Building'),
    Tab(text: 'Configuration'),
  ];

  late List<Widget> _designWidgets;

  late List<Widget> _controlWidgets;

  List<Widget> get _currentTabs => isInDesignMode ? _designTabs : _controlTabs;

  List<Widget> get _currentWidgets => isInDesignMode ? _designWidgets : _controlWidgets;

  @override
  void initState() {
    super.initState();
    _initController(isInDesignMode);
    FusionLogger.log(
      message: "Opened Project ",
      tag: LogTag.project,
    );

    // Listen for tab changes to trigger rebuild for IndexedStack
    _tabController.addListener(() {
      setState(() {});
    });

    /// Todo: Need to handle this in a better way
    serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(-1);
    serviceLocator<ProjectViewModel>().currentToolbarMode = ToolbarMode.acoustics;

    subscription = projectTabBroadcastController.stream.listen((int index) {
      if (index >= 0 && index < _tabController.length) {
        _tabController.animateTo(index);
      }
    });
    _projectNameController = TextEditingController(
      text: serviceLocator<ProjectViewModel>().projectName,
    );
    _initMace();
    _initSplRangeDefaults();
    _initAppVersion();

    // Initialize tab widgets to preserve state
    _createTabWidgets();
  }

  void _initController(bool isDesignMode) {
    final int length = isDesignMode ? _designTabs.length : _controlTabs.length;
    _tabController = TabController(
      length: length,
      vsync: this,
      animationDuration: Duration.zero,
      initialIndex: 0, // Always reset to 0 when switching modes to avoid index out of bounds
    );

    // Since you are using IndexedStack, we need to rebuild when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });
  }

  void toggleFusionModes() {
    serviceLocator<ProjectViewModel>().toggleControlMode();

    // Verify tab controller index is valid, reset to 0 if invalid
    // if (_tabController.index >= currentWidget.length) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _tabController.animateTo(0);
    //   });
    // }
  }

  Future<void> _initMace() async {
    await IsolatedMaceCalculationManager.instance.start();

    if (Platform.isMacOS || Platform.isIOS || Platform.isWindows) {
      WidgetsFlutterBinding.ensureInitialized();
      _engine = await MaceEngine.create(
        basePath: await MaceEngine.getLibPath(),
        bsfBasePath: (await getApplicationSupportDirectory()).path,
      );

      FusionLogger.log(
        message: "Mace engine initialized ",
        tag: LogTag.project,
      );
    }
  }

  SplPanelData? _lastPanelData;

  void _initSplRangeDefaults() {
    final SplPanelData currentPanelData = _splRangeController.getPanelData();
    _lastPanelData = currentPanelData;
    serviceLocator<ProjectViewModel>().setMinSPL(minSPL: currentPanelData.splLowerDb, autoSave: false);
    serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: currentPanelData.splUpperDb, autoSave: false);
  }

  Future<void> _initAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}-${packageInfo.buildNumber}';
      });
    } catch (e) {
      // Fallback to default version if package info fails
      setState(() {
        _appVersion = 'v1.0.0';
      });
    }
  }

  void _updateSPLFromPanelData() {
    final SplPanelData currentPanelData = _splRangeController.getPanelData();
    if (_lastPanelData != currentPanelData) {
      // if resolution changed, need to recalculate all SPLs
      if (_lastPanelData?.resolution != currentPanelData.resolution) {
        _lastPanelData = currentPanelData;
        calculateSPL();
        return;
      }
      _lastPanelData = currentPanelData;
      final Bandwidth maceBandwidth = _mapToMaceBandwidth(currentPanelData.bandwidth);
      final double frequency = currentPanelData.frequency.frequencyValue.toDouble();
      final Weighting weighting = _mapToMaceWeighting(currentPanelData.weighting);
      serviceLocator<ProjectViewModel>().setMinSPL(minSPL: currentPanelData.splLowerDb);
      serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: currentPanelData.splUpperDb);
      updateSpl(maceBandwidth, frequency, weighting, currentPanelData.relative);

      setState(() {}); // <-- Trigger rebuild
    }
  }

  Weighting _mapToMaceWeighting(SplWeighting w) {
    switch (w) {
      case SplWeighting.aWeighted:
        return Weighting.a;
      case SplWeighting.cWeighted:
        return Weighting.c;
      case SplWeighting.zWeighted:
        return Weighting.z;
    }
  }

  Bandwidth _mapToMaceBandwidth(SplBandwidth b) {
    switch (b) {
      case SplBandwidth.oneThirdOctave:
        return Bandwidth.oneThirdOctave;
      case SplBandwidth.oneOctave:
        return Bandwidth.oneOctave;
      case SplBandwidth.vocal:
        return Bandwidth.vocalBands;
      case SplBandwidth.allBands:
        return Bandwidth.allBands;
    }
  }

  Future<void> calculateSPL() async {
    // if (_engine == null) {
    //   debugPrint('calculateSPL: _engine is null');
    //   return;
    // }
    if (!_floorCanvasController.isShowingSpl.value) {
      debugPrint('calculateSPL: isShowingSpl is false');
      return;
    }

    final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
    if (currentFloorIndex == -1) return;

    final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];

    final List<ListeningArea> floorListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    if (floorListeningAreas.isEmpty) return;
    // for (ListeningArea e in floorListeningAreas) {
    //   e.clearSplData();
    // }
    final List<Speaker> speakers = List<Speaker>.from(
      serviceLocator<ProjectViewModel>().getHardwareInFloorWithPosition(floorId: currentFloor.id).whereType<Speaker>(),
    );
    final List<ListeningArea> surfaces = serviceLocator<ProjectViewModel>().getAllDrawnListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    if (!useIsolateEngine) {
      await SPLCalculationManager.calculateSpl(
        _engine!,
        speakers,
        surfaces,
        _lastPanelData!.getResolutionSpacing(),
      );
    } else {
      await IsolatedMaceCalculationManager.instance.calculateSpl(
        speakers: speakers,
        surfaces: surfaces,
        resolutionSpacing: _lastPanelData!.getResolutionSpacing(),
      );
    }

    final SplPanelData currentPanelData = _splRangeController.getPanelData();
    final Bandwidth maceBandwidth = _mapToMaceBandwidth(
      currentPanelData.bandwidth,
    );
    final Weighting weighting = _mapToMaceWeighting(currentPanelData.weighting);
    final double frequency = currentPanelData.frequency.frequencyValue.toDouble();
    await updateSpl(
      maceBandwidth,
      frequency,
      weighting,
      currentPanelData.relative,
    );
  }

  Future<void> updateSpl(
    Bandwidth bw,
    double frequency,
    Weighting weighting,
    bool relative,
  ) async {
    // if (_engine == null) return;
    if (!_floorCanvasController.isShowingSpl.value) return;

    final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
    if (currentFloorIndex == -1) return;

    final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];
    final List<ListeningArea> floorListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    if (floorListeningAreas.isEmpty) return;

    final List<SPLCalculation> toApply = <SPLCalculation>[];

    final Iterable<SPLCalculation> currentCalcs =
        useIsolateEngine ? await IsolatedMaceCalculationManager.instance.currentCalculations() : SPLCalculationManager.currentCalculations();

    for (final SPLCalculation sc in currentCalcs) {
      if (!floorListeningAreas.any((ListeningArea area) => area.id == sc.surface.id)) continue;
      final List<SPLCalculation> updated =
          useIsolateEngine
              ? await IsolatedMaceCalculationManager.instance.getSplAt(
                fph: sc.fphHandle,
                bandwidth: bw,
                freqHz: (bw == Bandwidth.oneThirdOctave || bw == Bandwidth.oneOctave) ? frequency : 2000,
                weighting: weighting,
                relative: relative,
                resolutionSpacing: _lastPanelData?.getResolutionSpacing() ?? 20.0,
              )
              : SPLCalculationManager.getSplAt(
                _engine!,
                sc.fphHandle,
                bw,
                (bw == Bandwidth.oneThirdOctave || bw == Bandwidth.oneOctave) ? frequency : 2000,
                weighting,
                relative,
                _lastPanelData?.getResolutionSpacing() ?? 20.0,
              );

      print("[isolate] updateSpl: updated length ${updated.map((SPLCalculation e) => e.spl.length)}");
      toApply.addAll(updated);
    }

    for (final SPLCalculation calc in toApply) {
      final List<ui.Offset> pts = calc.surface.getFieldPoints(
        _lastPanelData?.getResolutionSpacing() ?? 20.0,
      );
      floorListeningAreas.firstWhere((ListeningArea area) => area.id == calc.surface.id).setSplData(pts, calc.spl);
      // calc.surface.setSplData(pts, calc.spl);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    subscription?.cancel();
    _projectNameController.dispose();
    _projectNameFocusNode.dispose();
    productsController.dispose();
    splController.dispose();
    zoneAreaController.dispose();
    _splRangeController.dispose();
    _engine?.dispose();
    IsolatedMaceCalculationManager.instance.stop();
    _floorCanvasController.dispose();

    /// Reset configuration menu mode to processing on dispose
    _projectViewModel.setConfigurationMenuMode(ConfigurationMenuMode.processing);

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  bool get hasCloudAccess {
    return serviceLocator<SessionViewModel>().hasCloudAccess();
  }

  final ExpansibleController productsController = ExpansibleController();
  final ExpansibleController splController = ExpansibleController();
  final ExpansibleController zoneAreaController = ExpansibleController();

  List<DockItemConfig> _createBuildingDockItems(ToolbarMode toolbarMode, FloorCanvasController floorCanvasController) {
    return <DockItemConfig>[
      const DockItemConfig(
        id: "1",
        title: "FLOORS",
        side: "left",
        allowUndock: true,
        isCollapsibleSection: false,
        dockItemWidget: BuildingPlan(),
      ),
      DockItemConfig(
        id: "5",
        title: "PROPERTIES",
        side: "right",
        initiallyExpanded: false,
        dockItemWidget: PropertiesPanel(
          onSpeakerUpdated: () {
            calculateSPL();
          },
          onSpeakerDeleted: () {
            calculateSPL();
          },
        ),
      ),
      DockItemConfig(
        id: "6",
        title: "COST CALCULATOR",
        side: "right",
        allowUndock: true,
        dockItemWidget: CostCalculatorScreen(
          speakers: serviceLocator<ProjectViewModel>().speakers,
          sources: serviceLocator<ProjectViewModel>().sources,
          controllers: serviceLocator<ProjectViewModel>().fusionControllers,
          racks:
              serviceLocator<ProjectViewModel>().genericHardwareComponents
                  .where(
                    (GenericHardwareComponent component) => component.type == GenericHardwareComponentType.rack,
                  )
                  .toList(),
          amplifiers: <Amplifier>[],
          fusionDevices: <FusionDsp>[],
          others:
              serviceLocator<ProjectViewModel>().genericHardwareComponents
                  .where(
                    (HardwareComponent component) => component is GenericHardwareComponent && component.type == GenericHardwareComponentType.other,
                  )
                  .toList(),
        ),
      ),
      DockItemConfig(
        id: "7",
        title: toolbarMode == ToolbarMode.acoustics ? "LISTENING AREAS" : "ZONES",
        side: "left",
        controller: zoneAreaController,
        allowUndock: false,
        initiallyExpanded: true,
        dockItemWidget:
            toolbarMode == ToolbarMode.acoustics
                ? ListeningAreasPanel(
                  floorCanvasController: floorCanvasController,
                )
                : ZoneAndListeningAreaPanel(
                  floorCanvasController: floorCanvasController,
                ),
      ),
      // DockItemConfig(
      //   id: "8",
      //   title: "PRODUCT QUERY",
      //   side: "right",
      //   dockItemWidget: const ProductQueryView(),
      //   controller: productsController,
      // ),
      DockItemConfig(
        id: "9",
        title: "SPL MAPPING",
        side: "right",
        controller: splController,
        dockItemWidget: SplPanel(
          controller: _splRangeController,
          initialData: _lastPanelData!,
          onChanged: (SplPanelData value) {
            FusionLogger.log(tag: LogTag.panel, message: value.toString());
            _splRangeController.onMappingDataChanged(value);
            _updateSPLFromPanelData();
            setState(() {});
          },
        ),
      ),
      const DockItemConfig(
        id: "20",
        title: "SPEAKERS",
        side: "left",
        allowUndock: false,
        isCollapsibleSection: false,
        dockItemWidget: SpeakerSelectionWidget(),
      ),
      // if (toolbarMode == ToolbarMode.system)
      DockItemConfig(
        id: "21",
        title: "EQUIPMENT LOCATIONS",
        side: "left",
        allowUndock: false,
        isCollapsibleSection: false,
        dockItemWidget: toolbarMode == ToolbarMode.system ? const EquipmentLocationSection() : const SizedBox(),
      ),
    ];
  }

  void _createTabWidgets() {
    /// Building tab
    final Widget buildingPage = BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return FusionDockableArea(
          tabKey: "building_tab",
          showLeft: true,
          showRight: true,
          mainArea: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              return SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.buildingCanvas),
                child: BuildingCanvas(
                  splRangeController: _splRangeController,
                  onSplStateChanged: (bool value) {
                    if (value) {
                      productsController.collapse();
                      splController.expand();
                    } else {
                      splController.collapse();
                    }
                  },
                  floorCanvasController: _floorCanvasController,
                  onCalculateSpl: calculateSPL,
                  splPanelData: _lastPanelData!,
                  onProductSelected: () {
                    productsController.expand();
                  },
                  onProductDeselected: () {
                    productsController.collapse();
                  },
                ),
              );
            },
          ),
          dockItemList: _createBuildingDockItems(serviceLocator<ProjectViewModel>().currentToolbarMode, _floorCanvasController),
        );
      },
    );

    /// Config tab without docking area
    final Widget configurationPage = FusionDockableArea(
      tabKey: "configuration_tab",
      showLeft: true,
      showRight: false,
      mainArea: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          return switch (_projectViewModel.currentConfigurationMenuMode) {
            ConfigurationMenuMode.processing => const ConfigurationProcessingPage(),
            ConfigurationMenuMode.snapshots => const ConfigurationSnapshots(),
            // add all othere
            ConfigurationMenuMode.events => const ConfigurationEvents(),
            ConfigurationMenuMode.gpio => const GpioPage(),
            ConfigurationMenuMode.scheduling => const SchedulingPage(),
            ConfigurationMenuMode.mediaFiles => BlocProvider<MediaFilesViewModel>(
              create: (_) => MediaFilesViewModel(),
              child: const ConfigurationMediaFilesPage(),
            ),
          };
        },
      ),

      dockItemList: <DockItemConfig>[
        DockItemConfig(
          id: "19",
          title: "CONFIG",
          side: "left",
          allowUndock: true,
          isCollapsibleSection: false,
          dockItemWidget: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              return ConfigurationTabSwitcher(
                selectedMode: _projectViewModel.currentConfigurationMenuMode,
                onModeChanged: (ConfigurationMenuMode mode) {
                  _projectViewModel.setConfigurationMenuMode(mode);
                },
              );
            },
          ),
        ),
      ],
    );

    _designWidgets = <Widget>[
      buildingPage,

      /// Schematics tab
      BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, Object? state) {
          return FusionDockableArea(
            tabKey: "schematics_tab",
            showLeft: isListingViewMode ? false : true,
            showRight: true,
            mainArea: const SchematicsPage(),
            dockItemList: <DockItemConfig>[
              DockItemConfig(
                id: "11",
                title: "PROPERTIES",
                side: "right",
                initiallyExpanded: true,
                allowUndock: false,
                isCollapsibleSection: false,
                dockItemWidget: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          _projectViewModel.setProjectMode(ProjectMode.systemListingMode);
                        },
                        child: SemanticHelper.button(
                          testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.listingViewIcon),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: isListingViewMode ? context.colorScheme.elevation3 : Colors.transparent,
                            ),
                            child: FusionSvgIcon(
                              icon: AssetSvg.listingViewIcon,
                              size: 40,
                              color: context.colorScheme.primaryWhite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _projectViewModel.setProjectMode(ProjectMode.systemWiringMode);
                        },
                        child: SemanticHelper.button(
                          testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.wiringViewIcon),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: isListingViewMode ? Colors.transparent : context.colorScheme.elevation3,
                            ),
                            child: FusionSvgIcon(
                              icon: AssetSvg.wiringViewIcon,
                              size: 40,
                              color: context.colorScheme.primaryWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const DockItemConfig(
                id: "5",
                title: "PROPERTIES",
                side: "right",
                initiallyExpanded: true,
                allowUndock: false,
                dockItemWidget: SchematicProperties(),
              ),
              DockItemConfig(
                id: "6",
                title: "COST CALCULATOR",
                side: "right",
                allowUndock: true,
                dockItemWidget: CostCalculatorScreen(
                  speakers: serviceLocator<ProjectViewModel>().speakers,
                  sources: serviceLocator<ProjectViewModel>().sources,
                  controllers: serviceLocator<ProjectViewModel>().fusionControllers,
                  racks:
                      serviceLocator<ProjectViewModel>().genericHardwareComponents
                          .where(
                            (GenericHardwareComponent component) => component.type == GenericHardwareComponentType.rack,
                          )
                          .toList(),
                  amplifiers: <Amplifier>[],
                  fusionDevices: <FusionDsp>[],
                  others:
                      serviceLocator<ProjectViewModel>().genericHardwareComponents
                          .where(
                            (HardwareComponent component) => component is GenericHardwareComponent && component.type == GenericHardwareComponentType.other,
                          )
                          .toList(),
                ),
              ),
              // DockItemConfig(
              //   id: "8",
              //   title: "PRODUCT QUERY",
              //   side: "right",
              //   dockItemWidget: () => const ProductQueryView(),
              // ),
              const DockItemConfig(
                id: "10",
                title: "PRODUCT LIST",
                side: "left",
                initiallyExpanded: true,
                dockItemWidget: WiringDeviceListView(),
              ),
            ],
          );
        },
      ),

      configurationPage,
    ];

    _controlWidgets = <Widget>[
      serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : const FusionControlDashboardPage(),
      serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : const FusionDevicesPage(),
      serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : buildingPage,
      serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : configurationPage,
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      animationDuration: Duration.zero,
      length: 4,
      child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          if (state is TabChanged && mounted) {
            _initController(state.tab == 0);
          }
          if (state is VipUpdated) {
            _createTabWidgets();
            _tabController.animateTo(1);
          }
        },
        builder: (BuildContext context, ProjectViewModelState state) {
          return Scaffold(
            backgroundColor: context.colorScheme.primaryBlack,
            body: Column(
              children: <Widget>[
                /// Tab Bar Section
                SizedBox(
                  height: 48,
                  child: Row(
                    children: <Widget>[
                      /// Project Name Section
                      _projectNameSection(),
                      const SizedBox(width: 5),

                      /// Tabs Section
                      /// Tabs Section
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation1,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            border: Border(
                              left: BorderSide(width: 1, color: context.colorScheme.elevation2),
                              top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                              bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                            ),
                          ),
                          child: TabBar(
                            labelColor: context.colorScheme.primaryWhite,
                            unselectedLabelColor: context.colorScheme.elevation5,
                            dividerColor: Colors.transparent,
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.center,

                            indicator: BoxDecoration(color: context.colorScheme.elevation2, borderRadius: const BorderRadius.all(Radius.circular(8))),
                            indicatorPadding: const EdgeInsets.only(
                              top: 6,
                              bottom: 6,
                              left: 6,
                              right: 6,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,

                            labelStyle: context.textTheme.bodyMedium,
                            unselectedLabelStyle: context.textTheme.bodyMedium,
                            tabs: _currentTabs,
                          ),
                        ),
                      ),

                      /// tool bar section
                      // /// Undo Icon Section
                      // Visibility(
                      //   visible: true,
                      //   child: SemanticHelper.button(
                      //     testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.undo),
                      //     child: GestureDetector(
                      //       onTap: () {
                      //         if (serviceLocator<ProjectViewModel>().canUndo) {
                      //           serviceLocator<ProjectViewModel>().undo();
                      //         }
                      //       },
                      //       child: Tooltip(
                      //         message: serviceLocator<ProjectViewModel>().canUndo ? "Undo" : "Nothing to undo",
                      //         child: Container(
                      //           width: 56,
                      //           height: 48,
                      //           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      //
                      //           decoration: BoxDecoration(
                      //             color: Theme.of(context).colorScheme.primaryWhite,
                      //           ),
                      //           child: const FusionImage.asset(
                      //             "assets/images/return_icon.png",
                      //             width: 20,
                      //             height: 20,
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      //
                      // /// Redo Icon Section
                      // Visibility(
                      //   visible: true,
                      //   child: SemanticHelper.button(
                      //     testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.redo),
                      //     child: GestureDetector(
                      //       onTap: () {
                      //         if (serviceLocator<ProjectViewModel>().canRedo) {
                      //           serviceLocator<ProjectViewModel>().redo();
                      //         }
                      //       },
                      //       child: Tooltip(
                      //         message: serviceLocator<ProjectViewModel>().canRedo ? "Redo" : "Nothing to redo",
                      //         child: Container(
                      //           width: 56,
                      //           height: 48,
                      //           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      //
                      //           decoration: BoxDecoration(
                      //             color: Theme.of(context).colorScheme.primaryWhite,
                      //           ),
                      //
                      //           child: Transform(
                      //             alignment: Alignment.center,
                      //             transform: Matrix4.rotationY(3.14),
                      //             child: const FusionImage.asset(
                      //               "assets/images/return_icon.png",
                      //               width: 20,
                      //               height: 20,
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      Row(
                        children: <Widget>[
                          if (!isInDesignMode && serviceLocator<ProjectViewModel>().virtualIP != null)
                            Container(
                              width: 160,
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation1,
                                border: Border(
                                  top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                  bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                ),
                              ),

                              alignment: Alignment.center,
                              child: SizedBox(
                                height: 35,
                                child: FusionNeumorphicButton(
                                  semanticId: 'push_configuration',
                                  onTap: () {},
                                  height: 20,
                                  borderRadius: 6,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  text: "Push Configuration",
                                  textStyle: context.textTheme.labelMedium,
                                ),
                              ),
                            ),

                          if (!isInDesignMode && serviceLocator<ProjectViewModel>().virtualIP != null)
                            SemanticHelper.button(
                              testId: SemanticHelper.createTestId(SemanticTypes.button, "device_mapping_icon"),
                              child: Container(
                                width: 56,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.elevation1,
                                  border: Border(
                                    top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                    bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.elevation3,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      DeviceMappingDialog.show(context);
                                    },
                                    child: FusionImage.asset(
                                      AssetIcons.networkIcon,
                                      assetColor: Theme.of(context).colorScheme.iconWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          if (kDebugMode)
                            /// Theme Change Icon Section (Debug Only)
                            Container(
                              width: 56,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation1,
                                border: Border(
                                  top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                  bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                ),
                              ),
                              child: ValueListenableBuilder<ThemeMode>(
                                valueListenable: FusionThemeController.themeModeNotifier,
                                builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
                                  return IconButton(
                                    icon: Icon(
                                      themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                                      size: 24,
                                      color: Theme.of(context).colorScheme.primaryWhite,
                                    ),
                                    tooltip: themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                                    onPressed: () {
                                      final bool isLight = FusionThemeController.themeModeNotifier.value == ThemeMode.light;
                                      FusionThemeController.setThemeMode(
                                        isLight ? ThemeMode.dark : ThemeMode.light,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                          /// Save Icon Section
                          SemanticHelper.button(
                            testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.saveProject),
                            child: Container(
                              width: 56,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation1,
                                border: Border(
                                  top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                  bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.save,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primaryWhite,
                                ),
                                tooltip: 'Save project',
                                onPressed: () => _showProjectJsonDialog(context),
                                onLongPress: () => serviceLocator<ProjectViewModel>().deleteCurrentProjectFromLocal(),
                              ),
                            ),
                          ),

                          /// Save Icon Section
                          if (hasCloudAccess)
                            Container(
                              width: 56,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation1,
                                border: Border(
                                  top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                  bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.cloudUpload,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primaryWhite,
                                ),
                                tooltip: 'Upload project',
                                onPressed: () async {
                                  FusionUiUtils.showLoader(context);

                                  await serviceLocator<ProjectSyncViewModel>().uploadProject(
                                    projectData: serviceLocator<ProjectViewModel>().getCurrentProjectData()!,
                                  );
                                  if (context.mounted) {
                                    FusionUiUtils.hideLoader(context);
                                  }
                                },
                              ),
                            ),

                          /// Share Icon Section
                          // SemanticHelper.button(
                          //   testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.bugReport),
                          //   child: Container(
                          //     width: 56,
                          //     height: 48,
                          //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          //     decoration: BoxDecoration(
                          //       color: Theme.of(context).colorScheme.primaryWhite,
                          //       // border horizontal
                          //       border: Border(
                          //         left: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                          //         right: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                          //       ),
                          //     ),
                          //     child: Tooltip(
                          //       message: 'Give Feedback',
                          //       child: InkWell(
                          //         child: Icon(
                          //           Icons.feedback_outlined,
                          //           size: 24,
                          //           color: Theme.of(context).colorScheme.primaryBlack,
                          //         ),
                          //         onTap: () async {
                          //           showDialog(
                          //             context: context,
                          //             builder:
                          //                 (BuildContext context) => const Dialog(
                          //                   child: _FeedbackWebView(),
                          //                 ),
                          //           );
                          //         },
                          //       ),
                          //     ),
                          // child: Image.asset(
                          //   "assets/images/share_icon.png",
                          //   width: 24,
                          //   height: 24,
                          // ),
                          // ),
                          // ),

                          /// Share Icon Section
                          Container(
                            width: 56,
                            height: 48,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation1,
                              border: Border(
                                top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                              ),
                            ),
                            child: Tooltip(
                              message: 'Feedback and bug reports',
                              child: InkWell(
                                child: Icon(
                                  Icons.feedback_outlined,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primaryWhite,
                                ),
                                onTap: () async {
                                  handleExportLogs(context);
                                },
                              ),
                            ),
                            // child: Image.asset(
                            //   "assets/images/share_icon.png",
                            //   width: 24,
                            //   height: 24,
                            // ),
                          ),
                          ControlDesignTabSwitcher(
                            onTabChanged: (int index) {
                              toggleFusionModes();
                            },
                          ),

                          /// App Build Version
                          Container(
                            height: 48,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 12),

                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation1,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              border: Border(
                                right: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                top: BorderSide(width: 1, color: context.colorScheme.elevation2),
                                bottom: BorderSide(width: 1, color: context.colorScheme.elevation2),
                              ),
                            ),
                            child: FusionAppText(
                              style: context.textTheme.bodySmall,
                              text: "Build- $_appVersion",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _currentWidgets.isNotEmpty
                          ? IndexedStack(
                            index: _tabController.index.clamp(0, _currentWidgets.length - 1),
                            children: _currentWidgets,
                          )
                          : const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Project Name Section with Back Button
  Widget _projectNameSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        border: Border.all(color: context.colorScheme.elevation2, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: <Widget>[
          /// Back Button
          SizedBox(
            width: 38,
            height: 48,

            child: IconButton(
              icon: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.primaryWhite,
                size: 20,
              ),
              onPressed: () {
                serviceLocator<ProjectViewModel>().closeProject();
                Navigator.of(context).pop();
              },
              tooltip: 'Back to projects',
            ),
          ),

          /// Project Name Section
          InkWell(
            onTap: () => CreateNewProjectDialog.show(context, isEditMode: true),
            child: Container(
              key: _projectNameKey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              width: 197,

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                          builder: (
                            BuildContext context,
                            ProjectViewModelState state,
                          ) {
                            return FusionAppText(
                              text: serviceLocator<ProjectViewModel>().projectName,
                              semanticId: FusionTestKeys.projectName,
                              textOverflow: TextOverflow.ellipsis,
                              maxLine: 1,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        FusionAppText(
                          text: "1.0.0",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectJsonDialog(BuildContext context) {
    serviceLocator<ProjectViewModel>().saveProject();

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final Map<String, dynamic> jsonMap = serviceLocator<ProjectViewModel>().getProjectJson();
    final String prettyJson = encoder.convert(jsonMap);

    showDialog(
      context: context,
      builder:
          (BuildContext ctx) => CleanDialog(
            title: 'Project Saved!',
            actions: <Widget>[
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.close),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const FusionAppText(
                    text: 'Close',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 600,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  prettyJson,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class _FeedbackWebView extends StatefulWidget {
  const _FeedbackWebView({super.key});

  @override
  State<_FeedbackWebView> createState() => __FeedbackWebViewState();
}

class __FeedbackWebViewState extends State<_FeedbackWebView> {
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: true,
      ),
      onReceivedError: (InAppWebViewController controller, WebResourceRequest request, WebResourceError error) {
        print("Error loading feedback form: ${error.description}");
      },
      initialData: InAppWebViewInitialData(
        data: '''
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Jira Issue Collector Demo</title>

        <!-- Jira Issue Collector Script -->
        <script type="text/javascript" src="https://boseprofessional.atlassian.net/s/d41d8cd98f00b204e9800998ecf8427e-T/ribuf7/b/0/c95134bc67d3a521bb3f4331beb9b804/_/download/batch/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector.js?locale=en-US&collectorId=9740b101"></script>
      </head>
      <body>
      	<iframe
          style="display:none;"
          id="jiraIssueCollector"
          name="jiraIssueCollector"
          src='https://inappwebview.dev/docs/webview/in-app-webview'
        ></iframe>
        <script type="text/javascript">
          // Initialize the Jira Issue Collector
          JIRA.IssueCollector.showIssueCollectorDialog({
            triggerFunction: function() {
              // This function is called when the dialog is shown
              console.log("Jira Issue Collector dialog opened.");
            }
          });
        </script>
      </body>
      ''',
      ),
      // initialUrlRequest: URLRequest(
      //   url: WebUri(
      //     'https://inappwebview.dev/docs/webview/in-app-webview',
      //   ),
      // ),
    );
  }
}
