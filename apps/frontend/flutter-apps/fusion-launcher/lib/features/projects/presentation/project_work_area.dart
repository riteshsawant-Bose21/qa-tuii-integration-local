import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/media_files/view/configuration_media_files_pages.dart';
import 'package:fusion_launcher/features/media_files/viewModel/media_files_view_model.dart';
import 'package:fusion_launcher/features/projects/presentation/widgets/pages/building_page.dart';
import 'package:fusion_launcher/features/scheduling/view/scheduling_page.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/dock_item_config.dart';
import 'package:nested/nested.dart';

import '../../../core/service_locator.dart';
import '../../authentication/viewmodel/session_view_model.dart';
import '../../commission/presentation/pages/network_config_trigger_page.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../configuration_events/widgets/configuration_events.dart';
import '../../configuration_page/pages/configuration_processing_page.dart';
import '../../configuration_snapshot/widgets/configuration_snapshots.dart';
import '../../control_dashboard/presentation/pages/fusion_control_dashboard.dart';
import '../../devices/presentation/pages/fusion_devices_page.dart';
import '../../gpio/view/gpio_page.dart';
import '../../wiring_design/view/wiring_page.dart';
import '../view_model/spl_viewmodel.dart';
import '../widget/configuration/side_panel_widgets/configuration_tab_switcher.dart';
import 'widgets/appbar/project_work_area_appbar.dart';
import 'widgets/pages/system_page.dart';

class ProjectWorkArea extends StatefulWidget {
  const ProjectWorkArea({super.key});

  @override
  State<ProjectWorkArea> createState() => _ProjectWorkAreaState();
}

class _ProjectWorkAreaState extends State<ProjectWorkArea> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();
  final FloorCanvasController _floorCanvasController = FloorCanvasController();

  bool get isInDesignMode => !serviceLocator<ProjectViewModel>().isInControlMode;

  final List<Widget> _designTabs = const <Widget>[
    Tab(text: 'Building'),
    Tab(text: 'System'),
    Tab(text: 'Connections'),
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
    // Initialize tab widgets to preserve state
    _createTabWidgets();
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
    // serviceLocator<ProjectViewModel>().currentToolbarMode = ToolbarMode.acoustics;

    // _initSplRangeDefaults();
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

  @override
  void dispose() {
    _tabController.dispose();
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

  void _createTabWidgets() {
    /// Building tab
    final Widget buildingPage = BuildingPage(
      floorCanvasController: _floorCanvasController,
      appBarHeight: appBarHeight,
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
      const WorkSafeAreaContent(child: SystemPage()),
      const WiringPage(),

      WorkSafeAreaContent(child: configurationPage),
    ];

    _controlWidgets = <Widget>[
      WorkSafeAreaContent(child: serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : const FusionControlDashboardPage()),
      WorkSafeAreaContent(child: serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : const FusionDevicesPage()),
      WorkSafeAreaContent(child: serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : buildingPage),
      WorkSafeAreaContent(child: serviceLocator<ProjectViewModel>().virtualIP == null ? const NetworkConfigTrigger() : configurationPage),
    ];
  }

  double get appBarHeight => 64.0;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<SplViewModel>(
          create: (BuildContext context) => SplViewModel(),
        ),
      ],
      child: DefaultTabController(
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
            return WorkAreaScope(
              appBarHeight: appBarHeight,
              child: Scaffold(
                backgroundColor: context.colorScheme.primaryBlack,
                body: Stack(
                  children: <Widget>[
                    /// Tab Bar Section
                    Positioned(
                      child:
                          _currentWidgets.isNotEmpty
                              ? IndexedStack(
                                index: _tabController.index.clamp(0, _currentWidgets.length - 1),
                                children: _currentWidgets,
                              )
                              : const Center(child: CircularProgressIndicator()),
                    ),
                    SizedBox(
                      height: appBarHeight,
                      child: ProjectWorkAreaAppBar(
                        currentTabs: _currentTabs,
                        tabController: _tabController,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WorkAreaScope extends InheritedWidget {
  const WorkAreaScope({super.key, required this.appBarHeight, required super.child});

  final double appBarHeight;

  static WorkAreaScope of(BuildContext context) {
    final WorkAreaScope? scope = context.dependOnInheritedWidgetOfExactType<WorkAreaScope>();
    assert(scope != null, 'WorkAreaScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant WorkAreaScope oldWidget) {
    return appBarHeight != oldWidget.appBarHeight;
  }
}

class WorkSafeAreaContent extends StatelessWidget {
  const WorkSafeAreaContent({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = WorkAreaScope.of(context).appBarHeight;
    return SafeArea(
      minimum: EdgeInsets.only(top: appBarHeight),
      child: child,
    );
  }
}
