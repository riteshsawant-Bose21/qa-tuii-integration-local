import 'package:flutter/material.dart';
// import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
//Routes
import 'package:go_router/go_router.dart';
//Handlers
import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
//Widgets
import 'package:fusion_web/features/projects/presentation/widgets/view_toggle_button.dart';
import 'package:fusion_web/features/projects/presentation/widgets/filter_dropdown.dart';
import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';
import 'package:fusion_web/features/projects/presentation/widgets/status_badge.dart';
import 'package:fusion_web/features/projects/presentation/widgets/health_stat.dart';
import 'package:fusion_web/features/projects/presentation/widgets/incidents_badge.dart';
import 'package:fusion_web/features/projects/presentation/widgets/grid_info_row.dart';
import 'package:fusion_web/features/projects/presentation/widgets/type_pill.dart';
import 'package:fusion_web/features/projects/presentation/widgets/device_health_box.dart';
import 'package:fusion_web/features/projects/presentation/widgets/open_incidents_warning.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late final ProjectsViewModel _viewModel = ServiceLocator().projectsViewModel;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedRegions = 'All';
  String _selectedStatus = 'All';
  final String _selectedFilterType = 'Last Updated';

  bool _isGridView = false;

  @override
  void initState() {
    super.initState();

    _viewModel.initialize();

    _searchController.addListener(() {
      final query = _searchController.text;
      _viewModel.searchProjects(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _navigateToDetail(ProjectModel project) {
    context.go('${AppConstants.projectsRoute}/${project.id}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<ProjectsViewModel, BaseState<List<ProjectModel>>>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFiltersSection(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildContent()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ======================================================
  // HEADER
  // ======================================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDE (Title + subtitle)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projects',
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and monitor all projects across your organization',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ======================================================
  // FILTERS SECTION
  // ======================================================

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: TextFormField(
              controller: _searchController,
              decoration: _inputDecoration('Search projects...', Icons.search),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 1,
            child: FilterDropdown(
              value: _selectedRegions,
              items: ['All', 'indoor', 'outdoor', 'hybrid'],
              onChanged: (v) {
                setState(() => _selectedRegions = v!);

                _viewModel.filterProjects(
                  region: _selectedRegions,
                  status: _selectedStatus,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 1,
            child: FilterDropdown(
              value: _selectedStatus,
              items: ['All', 'Proposal', 'Development', 'Commissioned'],
              onChanged: (v) {
                setState(() => _selectedStatus = v!);

                _viewModel.filterProjects(
                  region: _selectedRegions,
                  status: _selectedStatus,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              ViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: _isGridView,
                onTap: () => setState(() => _isGridView = true),
              ),
              const SizedBox(width: 8),
              ViewToggleButton(
                icon: Icons.view_list_rounded,
                isSelected: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildToggle(IconData icon, bool isGrid) {
  //   final isSelected = _isGridView == isGrid;
  //   return InkWell(
  //     onTap: () => setState(() => _isGridView = isGrid),
  //     child: Container(
  //       padding: const EdgeInsets.all(10),
  //       decoration: BoxDecoration(
  //         color: isSelected ? Colors.black87 : Colors.grey[100],
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
  //     ),
  //   );
  // }

  // ======================================================
  // CONTENT
  // ======================================================

  Widget _buildContent() {
    return BlocBuilder<ProjectsViewModel, BaseState<List<ProjectModel>>>(
      builder: (context, state) {
        if (state is LoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ErrorState) {
          return Center(
            child: Text(
              (state as ErrorState).message,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.red[400],
              ),
            ),
          );
        }
        final projects = (state as LoadedState<List<ProjectModel>>).data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              //TODO: This from should come from API.
              'Showing ${projects.length} of ${projects.length} projects',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isGridView
                  ? _buildGridView(projects)
                  : _buildListView(projects),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // LIST VIEW
  // ======================================================

  Widget _buildListView(List<ProjectModel> projects) {
    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = projects[index];
        final totalDevices =
            p.healthyDevices + p.warningDevices + p.criticalDevices;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDetail(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// 1️⃣ name (earlier was named title)
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                        maxLines: 2,
                        softWrap: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.clientName,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                /// 2️⃣ REGION
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      p.region,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                  ),
                ),

                /// 3️⃣ STATUS
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(status: p.status),
                  ),
                ),

                /// 4️⃣ HEALTH
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      HealthStat(
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF22C55E),
                        count: p.healthyDevices,
                      ),
                      const SizedBox(width: 12),
                      HealthStat(
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFF59E0B),
                        count: p.warningDevices,
                      ),
                      const SizedBox(width: 12),
                      HealthStat(
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFEF4444),
                        count: p.criticalDevices,
                      ),
                    ],
                  ),
                ),

                /// 5️⃣ INCIDENTS
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IncidentsBadge(count: p.incidents),
                  ),
                ),

                /// 6️⃣ DATE + MENU
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(p.lastUpdated),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ProjectActionsMenu(
                        onInvite: () => ProjectActionsHandler.invite(
                          context: context,
                          project: p,
                          viewModel: _viewModel,
                        ),
                        onArchive: () => ProjectActionsHandler.archive(
                          context: context,
                          project: p,
                          viewModel: _viewModel,
                        ),
                        onDelete: () => ProjectActionsHandler.delete(
                          context: context,
                          project: p,
                          viewModel: _viewModel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ======================================================
  // GRID VIEW
  // ======================================================

  Widget _buildGridView(List<ProjectModel> projects) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.72,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];
        final totalDevices =
            p.healthyDevices + p.warningDevices + p.criticalDevices;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(p),
          // onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: p.status),
                  ],
                ),

                const SizedBox(height: 4),

                // Client name
                Text(
                  p.clientName,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 16),

                // Region row
                GridInfoRow(label: 'Region:', value: p.region),

                const SizedBox(height: 8),

                // Type row — derived from status/context as placeholder
                // (no type field in entity yet — show region-based label)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Type:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    TypePill(type: 'installation'),
                  ],
                ),

                const SizedBox(height: 14),

                // Device Health box — only if devices exist
                if (totalDevices >= 0) ...[
                  DeviceHealthBox(
                    healthy: p.healthyDevices,
                    warning: p.warningDevices,
                    critical: p.criticalDevices,
                  ),
                  const SizedBox(height: 12),
                ],

                // Open incidents warning — only if > 0
                if (p.incidents >= 0) ...[
                  OpenIncidentsWarning(count: p.incidents),
                  const SizedBox(height: 12),
                ],

                // Spacer pushes date to bottom
                const Spacer(),

                // Updated date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Updated ${_formatDate(p.lastUpdated)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    ProjectActionsMenu(
                      onInvite: () => ProjectActionsHandler.invite(
                        context: context,
                        project: p,
                        viewModel: _viewModel,
                      ),
                      onArchive: () => ProjectActionsHandler.archive(
                        context: context,
                        project: p,
                        viewModel: _viewModel,
                      ),
                      onDelete: () => ProjectActionsHandler.delete(
                        context: context,
                        project: p,
                        viewModel: _viewModel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
