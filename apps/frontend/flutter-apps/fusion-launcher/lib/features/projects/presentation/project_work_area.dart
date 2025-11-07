import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/pages/audio_system_design_page.dart';
import 'package:fusion_launcher/features/product_query/presentation/pages/product_query.dart';
import 'package:fusion_launcher/features/wiring_design/view/wiring_device_list_view.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/models/dock_item_config.dart';

import '../../../../core/spl_calculation/mace_calculation_manager.dart';
import '../../../../core/spl_calculation/mace_engine_provider.dart';
import '../../../core/service_locator.dart';
import '../../../core/spl_calculation/ffi_constants.dart';
import '../../../core/utils/broadcast_controllers.dart';
import '../../../core/widgets/clean_widgets.dart';
import '../../bill_of_materials/presentation/bill_of_materials_page.dart';
import '../../cloud_ui/presentation/pages/cloud_web_view.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../schematics/presentation/pages/schematics_page.dart';
import '../../schematics/presentation/widgets/circuit_test_widget.dart';
import '../../schematics/presentation/widgets/cost_calculator_widget.dart';
import '../widget/building/building_canvas.dart';
import '../widget/building/side_panel_widgets/building_plan.dart';
import '../widget/building/side_panel_widgets/listening_areas_panel.dart';
import '../widget/building/side_panel_widgets/properties_panel.dart';
import '../widget/building/side_panel_widgets/schematic_properties.dart';
import '../widget/building/side_panel_widgets/zone_and_listening_area.dart';
import '../widget/control_design_tab_switcher.dart';

class ProjectWorkArea extends StatefulWidget {
  const ProjectWorkArea({super.key});

  @override
  State<ProjectWorkArea> createState() => _ProjectWorkAreaState();
}

class _ProjectWorkAreaState extends State<ProjectWorkArea> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
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

  bool get isListingViewMode => _projectViewModel.currentProjectMode == ProjectMode.systemListingMode;

  final List<Widget> _tabs = const <Widget>[
    Tab(text: 'Building'),
    Tab(text: 'Schematics'),
    Tab(text: 'Zone config'),
    Tab(text: 'Budget'),
    Tab(text: 'Configuration'),
    Tab(text: 'Cloud'),
  ];

  late List<Widget> _tabWidgets;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      animationDuration: Duration.zero,
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

    // Initialize tab widgets to preserve state
    _tabWidgets = _createTabWidgets();
  }

  Future<void> _initMace() async {
    if (Platform.isMacOS || Platform.isIOS) {
      WidgetsFlutterBinding.ensureInitialized();
      _engine = await MaceEngine.create();
    }
  }

  SplPanelData? _lastPanelData;

  _initSplRangeDefaults() {
    final SplPanelData currentPanelData = _splRangeController.getPanelData();
    _lastPanelData = currentPanelData;
    serviceLocator<ProjectViewModel>().setMinSPL(minSPL: currentPanelData.splLowerDb, autoSave: false);
    serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: currentPanelData.splUpperDb, autoSave: false);
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
    if (_engine == null) {
      debugPrint('calculateSPL: _engine is null');
      return;
    }
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

    final List<Speaker> speakers = List<Speaker>.from(
      serviceLocator<ProjectViewModel>().getHardwareForFloor(floorId: currentFloor.id).whereType<Speaker>(),
    );
    final List<ListeningArea> surfaces = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
      floorId: currentFloor.id,
    );

    await SPLCalculationManager.calculateSpl(
      _engine!,
      speakers,
      surfaces,
      _lastPanelData!.getResolutionSpacing(),
    );

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
    if (_engine == null) return;
    if (!_floorCanvasController.isShowingSpl.value) return;

    final int currentFloorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
    if (currentFloorIndex == -1) return;

    final FloorModel currentFloor = serviceLocator<ProjectViewModel>().floors[currentFloorIndex];
    final List<ListeningArea> floorListeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForFloor(
      floorId: currentFloor.id,
    );
    if (floorListeningAreas.isEmpty) return;

    final List<SPLCalculation> toApply = <SPLCalculation>[];
    final Iterable<SPLCalculation> currentCalcs = SPLCalculationManager.currentCalculations();

    for (final SPLCalculation sc in currentCalcs) {
      if (!floorListeningAreas.any((ListeningArea area) => area.id == sc.surface.id)) continue;

      final List<SPLCalculation> updated = SPLCalculationManager.getSplAt(
        _engine!,
        sc.fphHandle,
        bw,
        (bw == Bandwidth.oneThirdOctave || bw == Bandwidth.oneOctave) ? frequency : 2000,
        weighting,
        relative,
        _lastPanelData?.getResolutionSpacing() ?? 20.0,
      );

      toApply.addAll(updated);
    }

    for (final SPLCalculation calc in toApply) {
      final List<ui.Offset> pts = calc.surface.getFieldPoints(
        _lastPanelData?.getResolutionSpacing() ?? 20.0,
      );
      calc.surface.setSplData(pts, calc.spl);
    }
  }

  /// Clear input fields
  void _clearFields() {
    _projectNameController.clear();
    _projectNameError = null;
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
    _floorCanvasController.dispose();

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  final ExpansibleController productsController = ExpansibleController();
  final ExpansibleController splController = ExpansibleController();
  final ExpansibleController zoneAreaController = ExpansibleController();

  List<DockItemConfig> _createBuildingDockItems(ToolbarMode toolbarMode) {
    return <DockItemConfig>[
      DockItemConfig(
        id: "1",
        title: "FLOORS",
        side: "left",
        allowUndock: true,
        isCollapsibleSection: false,
        dockItemWidget: () => const BuildingPlan(),
      ),
      DockItemConfig(
        id: "5",
        title: "PROPERTIES",
        side: "right",
        initiallyExpanded: false,
        dockItemWidget:
            () => PropertiesPanel(
              onSpeakerUpdated: () {
                print("Speaker properties updated, update SPL...");
                calculateSPL();
              },
            ),
      ),
      DockItemConfig(
        id: "6",
        title: "COST CALCULATOR",
        side: "right",
        allowUndock: true,
        dockItemWidget:
            () => CostCalculatorScreen(
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
        dockItemWidget: () => toolbarMode == ToolbarMode.acoustics ? const ListeningAreasPanel() : const ZoneAndListeningAreaPanel(),
      ),
      DockItemConfig(
        id: "8",
        title: "PRODUCT QUERY",
        side: "right",
        dockItemWidget: () => const ProductQueryView(),
        controller: productsController,
      ),
      DockItemConfig(
        id: "9",
        title: "SPL MAPPING",
        side: "right",
        controller: splController,
        dockItemWidget:
            () => SplPanel(
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
    ];
  }

  List<Widget> _createTabWidgets() {
    return <Widget>[
      /// Building tab
      BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          return FusionDockableArea(
            tabKey: "building_tab",
            showLeft: true,
            showRight: true,
            mainArea: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
              builder: (BuildContext context, ProjectViewModelState state) {
                return BuildingCanvas(
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
                );
              },
            ),
            dockItemList: _createBuildingDockItems(
              serviceLocator<ProjectViewModel>().currentToolbarMode,
            ),
          );
        },
      ),

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
                id: "5",
                title: "PROPERTIES",
                side: "right",
                initiallyExpanded: true,
                allowUndock: false,
                dockItemWidget: () => const SchematicProperties(),
              ),
              DockItemConfig(
                id: "6",
                title: "COST CALCULATOR",
                side: "right",
                allowUndock: true,
                dockItemWidget:
                    () => CostCalculatorScreen(
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
              DockItemConfig(
                id: "10",
                title: "PRODUCT LIST",
                side: "left",
                initiallyExpanded: true,
                dockItemWidget: () => const WiringDeviceListView(),
              ),
            ],
          );
        },
      ),

      const FusionDockableArea(
        tabKey: "zone_config_tab",
        showLeft: false,
        showRight: false,
        mainArea: ZoneCircuitConfigPage(),
        dockItemList: <DockItemConfig>[],
      ),

      /// budget tab with docking area
      const FusionDockableArea(
        tabKey: "budget_tab",
        showLeft: false,
        showRight: false,
        mainArea: BillOfMaterialsPage(),
        dockItemList: <DockItemConfig>[],
      ),

      /// Config tab without docking area
      const FusionDockableArea(
        tabKey: "configuration_tab",
        showLeft: false,
        showRight: false,
        mainArea: AudioSystemDesignPage(),
        dockItemList: <DockItemConfig>[],
      ),

      /// Cloud tab without docking area
      const FusionDockableArea(
        tabKey: "cloud_tab",
        showLeft: false,
        showRight: false,
        mainArea: FusionCloudWebView(
          pageToRedirect: "google.com",
        ),
        dockItemList: <DockItemConfig>[],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      animationDuration: Duration.zero,
      length: 4,
      child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {},
        builder: (BuildContext context, ProjectViewModelState state) {
          return Scaffold(
            appBar: FusionAppBar(
              backgroundColor: Colors.black87,
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).colorScheme.white,
                      size: 20,
                    ),
                    onPressed: () {
                      serviceLocator<ProjectViewModel>().closeProject();
                      Navigator.of(context).pop();
                    },
                    tooltip: 'Back to projects',
                  ),
                ),
              ), // List icon
              actions: <Widget>[
                const FusionProfileImage(
                  assetPath: "assets/images/fusion_default_icon.png",
                  size: 24,
                ),
              ],
              title: const SizedBox(),
            ),
            body: Column(
              children: <Widget>[
                /// Tab Bar Section
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.white,
                    border: Border.all(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                  ),
                  child: Row(
                    children: <Widget>[
                      /// Project Name Section
                      _projectNameSection(),

                      /// Tabs Section
                      Expanded(
                        child: TabBar(
                          labelColor: Colors.black87,
                          unselectedLabelColor: Theme.of(context).colorScheme.grey,
                          dividerColor: Colors.transparent,
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicatorColor: Colors.black,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          labelPadding: const EdgeInsets.only(left: 32),
                          tabs: _tabs,
                        ),
                      ),

                      /// Undo Icon Section
                      Visibility(
                        visible: true,
                        child: GestureDetector(
                          onTap: () {
                            if (serviceLocator<ProjectViewModel>().canUndo) {
                              serviceLocator<ProjectViewModel>().undo();
                            }
                          },
                          child: Tooltip(
                            message: serviceLocator<ProjectViewModel>().canUndo ? "Undo" : "Nothing to undo",
                            child: Container(
                              width: 56,
                              height: 48,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),

                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                              ),
                              child: const FusionImage.asset(
                                "assets/images/return_icon.png",
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Redo Icon Section
                      Visibility(
                        visible: true,
                        child: GestureDetector(
                          onTap: () {
                            if (serviceLocator<ProjectViewModel>().canRedo) {
                              serviceLocator<ProjectViewModel>().redo();
                            }
                          },
                          child: Tooltip(
                            message: serviceLocator<ProjectViewModel>().canRedo ? "Redo" : "Nothing to redo",
                            child: Container(
                              width: 56,
                              height: 48,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),

                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                              ),

                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(3.14),
                                child: const FusionImage.asset(
                                  "assets/images/return_icon.png",
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Save Icon Section
                      Container(
                        width: 56,
                        height: 48,
                        // padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.white,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.save,
                            size: 24,
                            color: Theme.of(context).colorScheme.greyDark,
                          ),
                          tooltip: 'Save project',
                          onPressed: () => _showProjectJsonDialog(context),
                          onLongPress: () => serviceLocator<ProjectViewModel>().deleteCurrentProjectFromLocal(),
                        ),
                      ),

                      /// Share Icon Section
                      Container(
                        width: 56,
                        height: 48,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.white,
                          // border horizontal
                          border: Border(
                            left: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                            right: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                          ),
                        ),
                        child: Image.asset(
                          "assets/images/share_icon.png",
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const ControlDesignTabSwitcher(),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _tabController.index,
                    children: _tabWidgets,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Project Name Section
  Widget _projectNameSection() {
    return InkWell(
      onTap: _showEditProjectNameDropdown,
      child: Container(
        key: _projectNameKey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        width: 237,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          // border right
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.dividerColor,
              width: 1,
            ),
          ),
        ),
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
                    text: "File_Version",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.greyDark),
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
    );
  }

  /// Show Edit Project Name Dropdown
  void _showEditProjectNameDropdown() {
    final RenderBox button = _projectNameKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      const Offset(-100, -20) & overlay.size,
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
      constraints: const BoxConstraints(minWidth: 237, maxWidth: 237),
      // Match container width
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setMenuState) {
              /// Auto-focus the text field when the menu opens
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _projectNameFocusNode.requestFocus();
              });

              return Container(
                width: 237,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FusionAppText(
                      text: "Edit Project Name",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _projectNameController,
                      focusNode: _projectNameFocusNode,
                      maxLength: 24,
                      autofocus: true,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.fusionTextViewColor,
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: 'Enter project name',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.grey,
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: _projectNameError != null ? Colors.red : Theme.of(context).colorScheme.fusionTextViewColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (String value) {
                        if (_projectNameError != null) {
                          setMenuState(() {
                            _projectNameError = null;
                          });
                        }
                      },
                      onSubmitted: (String value) {
                        final String trimmedName = value.trim();
                        if (trimmedName.isNotEmpty) {
                          serviceLocator<ProjectViewModel>().setProjectName(name: trimmedName);
                          Navigator.of(context).pop();
                        } else {
                          setMenuState(() {
                            _projectNameError = "Name cannot be empty";
                          });
                        }
                      },
                    ),
                    if (_projectNameError != null) ...<Widget>[
                      const SizedBox(height: 4),
                      FusionAppText(
                        text: _projectNameError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          textStyle: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(fontSize: 10),
                          onTap: () {
                            _clearFields();
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        FusionButton(
                          height: 28,
                          width: 84,
                          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.fusionButtonTextColor,
                          ),

                          label: "Edit Name",
                          onTap: () {
                            final String trimmedName = _projectNameController.text.trim();
                            if (trimmedName.isNotEmpty) {
                              serviceLocator<ProjectViewModel>().setProjectName(name: trimmedName);
                              Navigator.of(context).pop();
                            } else {
                              setMenuState(() {
                                _projectNameError = "Name cannot be empty";
                              });
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
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
