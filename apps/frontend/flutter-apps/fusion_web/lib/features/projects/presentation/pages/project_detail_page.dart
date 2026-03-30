import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/color_pallette.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/core/services/service_locator.dart';

import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/presentation/widgets/empty_state_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';
import 'package:go_router/go_router.dart';
//devices
import 'package:fusion_web/features/devices/data/datasources/device_datasource.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:fusion_web/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:fusion_web/features/devices/presentation/viewmodels/devices_viewmodel.dart';
import 'package:fusion_web/features/devices/presentation/widgets/devices_page_widgets/common_device_section.dart';
import 'package:fusion_web/features/devices/presentation/widgets/devices_page_widgets/device_filters.dart';
import 'package:fusion_web/features/devices/presentation/widgets/devices_page_widgets/device_grid_view.dart';
import 'package:fusion_web/features/devices/presentation/widgets/devices_page_widgets/devices_list_view.dart';

import '../viewmodels/project_detail_viewmodel.dart';

enum DetailTab { incidents, devices, activity }

class ProjectDetailPage extends StatefulWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  DetailTab _selectedTab = DetailTab.incidents;
  //devices

  @override
  void initState() {
    super.initState();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}, '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')} '
        '${date.hour >= 12 ? "PM" : "AM"}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectDetailViewmodel(
        projectId: widget.projectId,
        repository: ServiceLocator().projectsRepository,
      ),
      child: BlocBuilder<ProjectDetailViewmodel, BaseState<ProjectModel>>(
        builder: (context, state) {
          if (state is LoadingState) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ErrorState) {
            return Scaffold(
              body: Center(
                child: Text(
                  (state as ErrorState).message,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }
          final p = (state as LoadedState<ProjectModel>).data;
          final totalDevices =
              p.healthyDevices + p.warningDevices + p.criticalDevices;

          final healthyPct = totalDevices == 0
              ? 0
              : ((p.healthyDevices / totalDevices) * 100).round();

          final warningPct = totalDevices == 0
              ? 0
              : ((p.warningDevices / totalDevices) * 100).round();

          final criticalPct = totalDevices == 0
              ? 0
              : ((p.criticalDevices / totalDevices) * 100).round();
          final viewModel = ServiceLocator().projectsViewModel;
          return BlocProvider(
            create: (_) =>
                DevicesViewModel(DevicesRepositoryImpl(DeviceDatasource()))
                  ..selectedProjectId = p.id
                  ..loadDevices(),

            child: Container(
              // color: const Color(0xFFF7F7F7),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// BACK
                    TextButton.icon(
                      onPressed: () => context.go(AppConstants.projectsRoute),
                      icon: Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: context.colorScheme.elevation6,
                      ),
                      label: FusionAppText(
                        text: "Back to Projects",
                        // style: GoogleFonts.montserrat(
                        //   fontSize: 14,
                        //   fontWeight: FontWeight.w500,
                        // ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.hovered)) {
                            return context
                                .colorScheme
                                .elevation3; // hover background
                          }
                          return Colors.transparent;
                        }),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// HEADER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: FusionAppText(
                                      text: p.name,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _smallPill(p.status),
                                  const SizedBox(width: 8),
                                  _smallPill("installation"),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p.description,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        ProjectActionsMenu(
                          onInvite: () => ProjectActionsHandler.invite(
                            context: context,
                            project: p,
                            viewModel: viewModel,
                          ),
                          onArchive: () async {
                            final archived =
                                await ProjectActionsHandler.archive(
                                  context: context,
                                  project: p,
                                  viewModel: viewModel,
                                );

                            if (archived && mounted) {
                              context.go(AppConstants.projectsRoute);
                            }
                          },
                          onDelete: () async {
                            final deleted = await ProjectActionsHandler.delete(
                              context: context,
                              project: p,
                              viewModel: viewModel,
                            );

                            if (deleted && mounted) {
                              context.go(AppConstants.projectsRoute);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    /// DETAILS + SUMMARY
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// LEFT CARD
                        Expanded(
                          flex: 3,
                          child: _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _cardTitle("Project Details"),
                                const SizedBox(height: 24),
                                _detail("Customer", p.clientName),
                                const Divider(height: 32),
                                _detail("Region", p.region),
                                const Divider(height: 32),
                                _detail(
                                  "Last Updated",
                                  _formatDate(p.lastUpdated),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        /// RIGHT CARD
                        Expanded(
                          flex: 7,
                          child: _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _cardTitle("Project Summary"),
                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    _statBox("Total Devices", "$totalDevices"),
                                    const SizedBox(width: 16),
                                    _statBox(
                                      "Open Incidents",
                                      "${p.incidents}",
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                Text(
                                  "Device Health Status",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    _healthTile(
                                      "Healthy",
                                      p.healthyDevices,
                                      healthyPct,
                                      Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    _healthTile(
                                      "Warning",
                                      p.warningDevices,
                                      warningPct,
                                      Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    _healthTile(
                                      "Critical",
                                      p.criticalDevices,
                                      criticalPct,
                                      Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    /// TABS
                    BlocBuilder<DevicesViewModel, BaseState<DevicesModel>>(
                      builder: (context, deviceState) {
                        int deviceCount = 0;

                        if (deviceState is LoadedState<DevicesModel>) {
                          deviceCount = deviceState.data.devices.length;
                        }

                        return Row(
                          children: [
                            _tabButton(
                              "Incidents (${p.incidents})",
                              DetailTab.incidents,
                            ),
                            const SizedBox(width: 8),
                            _tabButton(
                              "Devices ($deviceCount)", //dynamic
                              DetailTab.devices,
                            ),
                            const SizedBox(width: 8),
                            _tabButton("Activity (0)", DetailTab.activity),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    if (_selectedTab == DetailTab.incidents)
                      p.incidents == 0
                          ? EmptyStateWidget(
                              title: "No Incidents Found",
                              description:
                                  "There are currently no reported incidents.",
                              icon: Icons.report_problem_outlined,
                            )
                          : const SizedBox(),

                    if (_selectedTab == DetailTab.devices)
                      BlocProvider(
                        create: (_) =>
                            DevicesViewModel(
                                DevicesRepositoryImpl(DeviceDatasource()),
                              )
                              ..selectedProjectId = p.id
                              ..loadDevices(),

                        child: Builder(
                          builder: (context) {
                            final viewModel = context.watch<DevicesViewModel>();

                            return BlocBuilder<
                              DevicesViewModel,
                              BaseState<DevicesModel>
                            >(
                              builder: (context, state) {
                                if (state is LoadingState) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (state is LoadedState<DevicesModel>) {
                                  final devices = state.data.devices;

                                  /// 0 devices case
                                  if (devices.isEmpty) {
                                    return EmptyStateWidget(
                                      title: "No Devices Found",
                                      description:
                                          "Devices will appear here once added to this project.",
                                      icon: Icons.devices_outlined,
                                    );
                                  }

                                  /// Devices Ui - Header, list and grid view
                                  return CommonDeviceSection(
                                    filters: DeviceFilters(
                                      searchController: TextEditingController(),

                                      onSearchChanged: viewModel.updateSearch,
                                      onClearFilters: viewModel.clearFilters,
                                      showClearFilters:
                                          viewModel.hasActiveFilters,

                                      selectedStatus: viewModel.selectedStatus,
                                      selectedProjects:
                                          viewModel.selectedProject,
                                      selectedModels: viewModel.selectedModel,
                                      selectedCategory:
                                          viewModel.selectedCategory,
                                      selectedTypes: viewModel.selectedType,
                                      isGridView: viewModel.isGridView,

                                      onStatusChanged: (v) =>
                                          viewModel.updateStatus(v!),
                                      onProjectChanged: (v) =>
                                          viewModel.updateProject(v!),
                                      onModelChanged: (v) =>
                                          viewModel.updateModel(v!),
                                      onTypeChanged: (v) =>
                                          viewModel.updateType(v!),
                                      onCategoryChanged: (v) =>
                                          viewModel.updateCategory(v!),

                                      onGridTap: () =>
                                          viewModel.toggleGrid(true),
                                      onListTap: () =>
                                          viewModel.toggleGrid(false),

                                      statusItems: const [
                                        "All Status",
                                        "Healthy",
                                        "Critical",
                                        "Inactive",
                                      ],
                                      modelItems: const [
                                        "All Models",
                                        "EdgeMax EM90",
                                        "PowerMatch PM8500N",
                                        "ControlSpace EX-1280C",
                                        "FreeSpace FS4SE",
                                        "ControlSpace EX-440C",
                                      ],
                                      typeItems: const [
                                        "All Types",
                                        "Speaker",
                                        "Amplifier",
                                        "Controller",
                                        "Processor",
                                      ],
                                      projectItems: const [
                                        "All Projects",
                                        "Metro University Campus Audio",
                                        "Skyline Downtown Conference Center",
                                        "Skyline Resort & Spa",
                                        "Grand Plaza Convention Hall",
                                        "TechHub Innovation Center",
                                      ],
                                      categoryItems: const [
                                        "Name",
                                        "Model",
                                        "Status",
                                        "Last Seen",
                                      ],
                                    ),

                                    content: viewModel.isGridView
                                        ? DevicesGridView(
                                            devices: devices,
                                            onDeviceTap: (device) {
                                              context.go(
                                                '/projects/${p.id}/devices/${device.deviceId}',
                                                extra: device,
                                              );
                                            },
                                          )
                                        : DevicesListView(
                                            devices: devices,
                                            onDeviceTap: (device) {
                                              context.go(
                                                '/projects/${p.id}/devices/${device.deviceId}',
                                                extra: device,
                                              );

                                              // context.push(
                                              //   // 'device_detail',
                                              //   // pathParameters: {
                                              //   //   "id": p.id,
                                              //   //   "deviceId": device.deviceId,
                                              //   // },
                                              //   '/devices/${device.deviceId}',
                                              //   extra: device,
                                              // );
                                            },
                                          ),
                                  );
                                }

                                if (state is ErrorState<DevicesModel>) {
                                  return Center(child: Text(state.message));
                                }

                                return const SizedBox();
                              },
                            );
                          },
                        ),
                      ),

                    if (_selectedTab == DetailTab.activity)
                      EmptyStateWidget(
                        title: "No Activity Yet",
                        description: "Recent activity will appear here.",
                        icon: Icons.timeline_outlined,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// COMPONENTS

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      // color: Colors.white,
      color: context.colorScheme.elevation2,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _cardTitle(String text) => FusionAppText(
    text: text,
    // style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FusionAppText(
          text: label,
        ),
        const SizedBox(height: 4),
        FusionAppText(
          text: value,
        ),
      ],
    ),
  );

  Widget _statBox(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FusionAppText(
            text: label,
          ),
          const SizedBox(height: 8),
          FusionAppText(
            text: value,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _healthTile(String label, int count, int pct, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 13, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            "$count",
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$pct%",
            style: GoogleFonts.montserrat(fontSize: 12, color: color),
          ),
        ],
      ),
    ),
  );

  Widget _tabButton(String text, DetailTab tab) {
    final selected = _selectedTab == tab;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FusionAppText(
          text: text
        ),
      ),
    );
  }

  Widget _smallPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: context.colorScheme.elevation6,
      borderRadius: BorderRadius.circular(20),
    ),
    child: FusionAppText(
      text: text,
    ),
  );
}
