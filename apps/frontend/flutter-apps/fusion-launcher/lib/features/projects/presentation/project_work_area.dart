import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/bill_of_materials/presentation/bill_of_materials_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/pages/audio_system_design_page.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panle_widgets/devices_panel.dart';
import 'package:fusion_launcher/features/product_query/presentation/pages/product_query.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/models/dock_item_config.dart';

import '../../../core/service_locator.dart';
import '../../../core/utils/broadcast_controllers.dart';
import '../../../core/widgets/clean_widgets.dart';
import '../../cloud_ui/presentation/pages/cloud_web_view.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../schematics/presentation/pages/schematics_page.dart';
import '../../schematics/presentation/widgets/cost_calcuator_widget.dart';
import '../widget/building/side_panle_widgets/coverage_panel.dart';
import '../widget/building/side_panle_widgets/zone_and_listening_area.dart';
import '../widget/building/building_canvas.dart';
import '../widget/building/side_panle_widgets/building_plan.dart';
import '../widget/building/side_panle_widgets/properties.dart';
import '../widget/control_design_tab_switcher.dart';

class ProjectWorkArea extends StatefulWidget {
  const ProjectWorkArea({super.key});

  @override
  State<ProjectWorkArea> createState() => _TestLibraryScreenState();
}

class _TestLibraryScreenState extends State<ProjectWorkArea> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  StreamSubscription<int>? subscription;
  late TextEditingController _projectNameController;
  final FocusNode _projectNameFocusNode = FocusNode();
  final GlobalKey _projectNameKey = GlobalKey();
  String? _projectNameError;

  final SplRangeController _splRangeController = SplRangeController();

  final List<Widget> _tabs = const <Widget>[
    Tab(text: 'Building'),
    Tab(text: 'Schematics'),
    Tab(text: 'Budget'),
    Tab(text: 'Configuration'),
    Tab(text: 'Cloud'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      animationDuration: Duration.zero,
    );

    //Need to handle this in a better way
    serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(-1);

    subscription = projectTabBroadcastController.stream.listen((int index) {
      if (index >= 0 && index < _tabController.length) {
        _tabController.animateTo(index);
      }
    });
    _projectNameController = TextEditingController(text: serviceLocator<ProjectViewModel>().projectName);
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

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  final ExpansibleController productsController = ExpansibleController();
  final ExpansibleController splController = ExpansibleController();
  final ExpansibleController zoneAreaController = ExpansibleController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      animationDuration: Duration.zero,

      length: 4,
      child: Scaffold(
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
          // title: IntrinsicWidth(
          //   child: TextField(
          //     controller: _projectNameController,
          //     textAlign: TextAlign.start,
          //     style: const TextStyle(
          //       color: Colors.white,
          //       fontSize: 20,
          //       fontWeight: FontWeight.normal,
          //     ),
          //     decoration: const InputDecoration(
          //       border: InputBorder.none,
          //       isDense: true,
          //       contentPadding: EdgeInsets.zero,
          //       hintText: 'Project Name',
          //       suffixIcon: Icon(
          //         Icons.edit,
          //         size: 16,
          //         color: Colors.grey,
          //       ),
          //       suffixIconConstraints: BoxConstraints(
          //         minWidth: 0,
          //         minHeight: 0,
          //       ),
          //     ),
          //     onSubmitted: (String value) {
          //       serviceLocator<ProjectViewModel>().setProjectName(value.trim());
          //     },
          //   ),
          // ),
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
                    visible: false,
                    child: GestureDetector(
                      onTap: () {
                        serviceLocator<ProjectViewModel>().canUndo ? () => serviceLocator<ProjectViewModel>().undo() : null;
                      },
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

                  /// Redo Icon Section
                  Visibility(
                    visible: false,
                    child: GestureDetector(
                      onTap: () {
                        serviceLocator<ProjectViewModel>().canRedo ? () => serviceLocator<ProjectViewModel>().redo() : null;
                      },
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
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  /// building tab with docking area
                  BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                    builder: (BuildContext context, ProjectViewModelState state) {
                      return FusionDockableArea(
                        tabKey: "tab1",
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
                            );
                          },
                        ),
                        dockItemList: <DockItemConfig>[
                          DockItemConfig(
                            id: "1",
                            title: "BUILDING PLAN",
                            side: "left",
                            alowUndock: false,
                            isCollapsibleSection: false,
                            dockItemWidget: () => const BuildingPlan(),
                          ),
                          DockItemConfig(
                            id: "2",
                            title: "COVERAGE",
                            side: "left",
                            alowUndock: false,
                            initiallyExpanded: true,
                            isCollapsibleSection: true,
                            dockItemWidget:
                                () => CoveragePanel(
                                  onModeSelection: (bool value) {
                                    if (value) {
                                      zoneAreaController.expand();
                                    }
                                  },
                                ),
                          ),

                          DockItemConfig(
                            id: "4",
                            title: "DEVICES",
                            side: "left",
                            alowUndock: false,
                            initiallyExpanded: true,
                            isCollapsibleSection: true,
                            dockItemWidget:
                                () => DevicesPanel(
                                  onProductSelected: () {
                                    productsController.expand();
                                  },
                                ),
                          ),

                          DockItemConfig(
                            id: "5",
                            title: "PROPERTIES",
                            side: "right",
                            alowUndock: false,
                            dockItemWidget: () => const Properties(),
                          ),
                          DockItemConfig(
                            id: "6",
                            title: "COST CALCULATOR",
                            side: "right",
                            dockItemWidget:
                                () => CostCalculatorScreen(
                                  speakers: serviceLocator<ProjectViewModel>().speakers,
                                  sources: serviceLocator<ProjectViewModel>().sources,
                                  controllers:
                                      serviceLocator<ProjectViewModel>().genericHardwareComponents
                                          .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.controller)
                                          .toList(),
                                  racks:
                                      serviceLocator<ProjectViewModel>().genericHardwareComponents
                                          .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.rack)
                                          .toList(),
                                  amplifiers: <Amplifier>[],
                                  fusionDevices: <FusionDevice>[],
                                  others:
                                      serviceLocator<ProjectViewModel>().genericHardwareComponents
                                          .where(
                                            (HardwareComponent component) =>
                                                component is GenericHardwareComponent && component.type == GenericHardwareComponentType.other,
                                          )
                                          .toList(),
                                ),
                          ),
                          DockItemConfig(
                            id: "7",
                            title: "ZONE & LISTENING AREAS",
                            side: "right",
                            controller: zoneAreaController,
                            initiallyExpanded: serviceLocator<ProjectViewModel>().isInZoneSelectionMode,
                            // isVisible: serviceLocator<ProjectViewModel>().isInZoneSelectionMode ,
                            dockItemWidget: () => const ZoneAndListeningAreaPanel(),
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
                                  onChanged: (SplPanelData value) {
                                    FusionLogger.log(tag: LogTag.panel, message: value.toString());
                                  },
                                ),
                          ),
                        ],
                      );
                    },
                  ),

                  /// schematics tab with docking area
                  FusionDockableArea(
                    tabKey: "tab2",
                    showLeft: false,
                    showRight: true,
                    mainArea: const SchematicsPage(),
                    dockItemList: <DockItemConfig>[
                      DockItemConfig(
                        id: "6",
                        title: "COST CALCULATOR",
                        side: "right",
                        dockItemWidget:
                            () => CostCalculatorScreen(
                              speakers: serviceLocator<ProjectViewModel>().speakers,
                              sources: serviceLocator<ProjectViewModel>().sources,
                              controllers:
                                  serviceLocator<ProjectViewModel>().genericHardwareComponents
                                      .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.controller)
                                      .toList(),
                              racks:
                                  serviceLocator<ProjectViewModel>().genericHardwareComponents
                                      .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.rack)
                                      .toList(),
                              amplifiers: <Amplifier>[],
                              fusionDevices: <FusionDevice>[],
                              others:
                                  serviceLocator<ProjectViewModel>().genericHardwareComponents
                                      .where(
                                        (HardwareComponent component) =>
                                            component is GenericHardwareComponent && component.type == GenericHardwareComponentType.other,
                                      )
                                      .toList(),
                            ),
                      ),
                      DockItemConfig(
                        id: "8",
                        title: "PRODUCT QUERY",
                        side: "right",
                        dockItemWidget: () => const ProductQueryView(),
                      ),
                    ],
                  ),

                  /// budget tab with docking area
                  const FusionDockableArea(
                    tabKey: "tab3",
                    showLeft: false,
                    showRight: false,
                    mainArea: BillOfMaterialsPage(),
                    dockItemList: <DockItemConfig>[],
                  ),

                  /// Config tab without docking area
                  const FusionDockableArea(
                    tabKey: "tab4",
                    showLeft: false,
                    showRight: false,
                    mainArea: AudioSystemDesignPage(),
                    dockItemList: <DockItemConfig>[],
                  ),

                  /// Cloud tab without docking area
                  const FusionCloudWebView(
                    pageToRedirect: "google.com",
                    // "embed/projects/${projectManager.value.cloudId}?token=${serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.accessToken)}",
                  ),
                ],
              ),
            ),
          ],
        ),
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
            right: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
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
                    builder: (BuildContext context, ProjectViewModelState state) {
                      return FusionAppText(
                        text: serviceLocator<ProjectViewModel>().projectName,
                        textOverflow: TextOverflow.ellipsis,
                        maxLine: 1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  FusionAppText(
                    text: "File_Version",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.greyDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down_outlined,
              size: 18,
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
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
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
                      autofocus: true,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.fusionTextViewColor,
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter project name',
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
                          borderSide: BorderSide(color: _projectNameError != null ? Colors.red : Theme.of(context).colorScheme.fusionTextViewColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                          serviceLocator<ProjectViewModel>().setProjectName(trimmedName);
                          Navigator.of(context).pop();
                        } else {
                          setMenuState(() {
                            _projectNameError = "Name can not be empty";
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
                          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        FusionButton(
                          height: 28,
                          width: 84,
                          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.fusionButtonTextColor),

                          label: "Edit Name",
                          onTap: () {
                            final String trimmedName = _projectNameController.text.trim();
                            if (trimmedName.isNotEmpty) {
                              serviceLocator<ProjectViewModel>().setProjectName(trimmedName);
                              Navigator.of(context).pop();
                            } else {
                              setMenuState(() {
                                _projectNameError = "Name can't be empty";
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
    serviceLocator<ProjectViewModel>().saveProjectToLocal();

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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
