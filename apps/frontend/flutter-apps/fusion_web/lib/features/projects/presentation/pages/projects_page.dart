import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
import 'package:fusion_web/features/projects/domain/usecases/projects_usecases.dart';
import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/features/projects/presentation/pages/project_detail_page.dart';
import 'package:fusion_web/core/constants/app_constants.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late ProjectsViewModel _viewModel;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedRegions = 'All Regions';
  String _selectedStatus = 'All Status';
  String _selectedFilterType = 'Last Updated';

  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _initializeViewModel();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _initializeViewModel() {
    final apiService = ServiceLocator().apiService;
    final remoteDataSource = ProjectsRemoteDataSource(apiService: apiService);
    final localDataSource = ProjectsLocalDataSource();

    final repository = ProjectsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    _viewModel = ProjectsViewModel(
      getProjectsUseCase: GetProjectsUseCase(repository),
      getProjectByIdUseCase: GetProjectByIdUseCase(repository),
      createProjectUseCase: CreateProjectUseCase(repository),
      updateProjectUseCase: UpdateProjectUseCase(repository),
      deleteProjectUseCase: DeleteProjectUseCase(repository),
      searchProjectsUseCase: SearchProjectsUseCase(repository),
    );

    _viewModel.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
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

  List<ProjectEntity> get _filteredProjects {
    final projects = _viewModel.projects;
    if (projects.isEmpty) return [];

    List<ProjectEntity> filtered = List.from(projects);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        return project.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            project.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            project.clientName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    if (_selectedRegions != 'All Regions') {
      filtered = filtered
          .where(
            (p) => p.region.toLowerCase() == _selectedRegions.toLowerCase(),
          )
          .toList();
    }

    if (_selectedStatus != 'All Status') {
      filtered = filtered
          .where((p) => p.status.toLowerCase() == _selectedStatus.toLowerCase())
          .toList();
    }

    return filtered;
  }

  void _navigateToDetail(ProjectEntity project) {
    Navigator.pushNamed(
      context,
      AppConstants.projectDetailRoute,
      arguments: project,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFiltersSection(),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
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

        // RIGHT SIDE (New Project Button)
        ElevatedButton.icon(
          onPressed: (){},
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'New Project',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
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
            flex: 2,
            child: _dropdown(_selectedRegions, [
              'All Regions',
              'North America',
              'Europe',
            ], (v) => setState(() => _selectedRegions = v!)),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: _dropdown(_selectedStatus, [
              'All Status',
              'Active',
              'Completed',
            ], (v) => setState(() => _selectedStatus = v!)),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _buildToggle(Icons.grid_view_rounded, true),
              const SizedBox(width: 8),
              _buildToggle(Icons.view_list_rounded, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _dropdownDecoration(),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: GoogleFonts.montserrat()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildToggle(IconData icon, bool isGrid) {
    final isSelected = _isGridView == isGrid;
    return InkWell(
      onTap: () => setState(() => _isGridView = isGrid),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
      ),
    );
  }

  // ======================================================
  // CONTENT
  // ======================================================

  Widget _buildContent() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = _filteredProjects;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Showing ${projects.length} of ${_viewModel.projects.length} projects',
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
  // LIST VIEW — matches Figma images 2 & 3
  // ======================================================

  Widget _buildListView(List<ProjectEntity> projects) {
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
          // onTap: (){},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Title + client name
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.clientName,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Region
                Expanded(
                  flex: 2,
                  child: Text(
                    p.region,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

                // Status badge
                _statusBadge(p.status),

                const SizedBox(width: 20),

                // Device health stats — only show if any devices exist
                if (totalDevices > 0) ...[
                  _healthStat(
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF22C55E),
                    p.healthyDevices,
                  ),
                  const SizedBox(width: 10),
                  _healthStat(
                    Icons.warning_amber_rounded,
                    const Color(0xFFF59E0B),
                    p.warningDevices,
                  ),
                  const SizedBox(width: 10),
                  _healthStat(
                    Icons.cancel_outlined,
                    const Color(0xFFEF4444),
                    p.criticalDevices,
                  ),
                  const SizedBox(width: 20),
                ],

                // Incidents badge — only show if > 0
                if (p.incidents > 0) ...[
                  _incidentsBadge(p.incidents),
                  const SizedBox(width: 20),
                ] else ...[
                  const SizedBox(width: 110), // keep layout stable
                ],

                // Date
                Text(
                  _formatDate(p.lastUpdated),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[500],
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
  // GRID VIEW — matches Figma images 4, 5 & 6
  // ======================================================

  Widget _buildGridView(List<ProjectEntity> projects) {
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
                        p.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(p.status),
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
                _gridInfoRow('Region:', p.region),

                const SizedBox(height: 8),

                // Type row — derived from status/context as placeholder
                // (no type field in entity yet — show region-based label)
                _gridInfoRowWidget('Type:', _typePill('installation')),

                const SizedBox(height: 14),

                // Device Health box — only if devices exist
                if (totalDevices > 0) ...[
                  _deviceHealthBox(p),
                  const SizedBox(height: 12),
                ],

                // Open incidents warning — only if > 0
                if (p.incidents > 0) ...[
                  _openIncidentsWarning(p.incidents),
                  const SizedBox(height: 12),
                ],

                // Spacer pushes date to bottom
                const Spacer(),

                // Updated date
                Text(
                  'Updated ${_formatDate(p.lastUpdated)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[400],
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
  // SHARED WIDGETS
  // ======================================================

  Widget _statusBadge(String status) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;

    if (lower == 'active') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    } else if (lower == 'completed') {
      bg = Colors.grey[200]!;
      fg = Colors.grey[600]!;
    } else {
      bg = Colors.blue[100]!;
      fg = Colors.blue[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        lower,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  Widget _healthStat(IconData icon, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _incidentsBadge(int count) {
    final label = count == 1 ? '1 incident' : '$count incidents';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFEA580C),
        ),
      ),
    );
  }

  Widget _gridInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500]),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _gridInfoRowWidget(String label, Widget valueWidget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500]),
        ),
        valueWidget,
      ],
    );
  }

  Widget _typePill(String type) {
    Color bg;
    Color fg;
    switch (type.toLowerCase()) {
      case 'installation':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7C3AED);
        break;
      case 'opportunity':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        break;
      case 'poc':
        bg = const Color(0xFFFCE7F3);
        fg = const Color(0xFFBE185D);
        break;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[600]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toLowerCase(),
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  Widget _deviceHealthBox(ProjectEntity p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Health',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _healthStat(
                Icons.check_circle_outline_rounded,
                const Color(0xFF22C55E),
                p.healthyDevices,
              ),
              const SizedBox(width: 16),
              _healthStat(
                Icons.warning_amber_rounded,
                const Color(0xFFF59E0B),
                p.warningDevices,
              ),
              const SizedBox(width: 16),
              _healthStat(
                Icons.cancel_outlined,
                const Color(0xFFEF4444),
                p.criticalDevices,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _openIncidentsWarning(int count) {
    final label = count == 1 ? '1 open incident' : '$count open incidents';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEA580C),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
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





// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:data_table_2/data_table_2.dart';
// import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
// import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
// import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
// import 'package:fusion_web/features/projects/domain/usecases/projects_usecases.dart';
// import 'package:fusion_web/features/projects/domain/entities/project_entity.dart';
// import 'package:fusion_web/core/services/service_locator.dart';
// import 'package:fusion_lib/fusion_widgets/shared_widgets/project/new_project.dart';

// class ProjectsPage extends StatefulWidget {
//   const ProjectsPage({super.key});

//   @override
//   State<ProjectsPage> createState() => _ProjectsPageState();
// }

// class _ProjectsPageState extends State<ProjectsPage> {
//   late ProjectsViewModel _viewModel;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String _selectedRegions = 'All Regions';
//   String _selectedStatus = 'All Status';
//   String _selectedFilterType = 'Last Updated';
//   bool _isGridView = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeViewModel();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//       });
//     });
//   }

//   void _initializeViewModel() {
//     final apiService = ServiceLocator().apiService;
//     final remoteDataSource = ProjectsRemoteDataSource(apiService: apiService);
//     final localDataSource = ProjectsLocalDataSource();
//     final repository = ProjectsRepositoryImpl(
//       remoteDataSource: remoteDataSource,
//       localDataSource: localDataSource,
//     );

//     _viewModel = ProjectsViewModel(
//       getProjectsUseCase: GetProjectsUseCase(repository),
//       getProjectByIdUseCase: GetProjectByIdUseCase(repository),
//       createProjectUseCase: CreateProjectUseCase(repository),
//       updateProjectUseCase: UpdateProjectUseCase(repository),
//       deleteProjectUseCase: DeleteProjectUseCase(repository),
//       searchProjectsUseCase: SearchProjectsUseCase(repository),
//     );

//     _viewModel.initialize();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _viewModel.dispose();
//     super.dispose();
//   }

//   List<ProjectEntity> get _filteredProjects {
//     final projects = _viewModel.projects;
//     if (projects.isEmpty) return [];

//     List<ProjectEntity> filtered = List.from(projects);

//     // Search filter
//     if (_searchQuery.isNotEmpty) {
//       filtered = filtered.where((project) {
//         return project.title.toLowerCase().contains(
//               _searchQuery.toLowerCase(),
//             ) ||
//             project.description.toLowerCase().contains(
//               _searchQuery.toLowerCase(),
//             ) ||
//             project.clientName.toLowerCase().contains(
//               _searchQuery.toLowerCase(),
//             );
//       }).toList();
//     }

//     // Region filter (FIXED)
//     if (_selectedRegions != 'All Regions') {
//       filtered = filtered
//           .where(
//             (project) =>
//                 project.region.toLowerCase() == _selectedRegions.toLowerCase(),
//           )
//           .toList();
//     }

//     // Status filter (FIXED)
//     if (_selectedStatus != 'All Status') {
//       filtered = filtered
//           .where(
//             (project) =>
//                 project.status.toLowerCase() == _selectedStatus.toLowerCase(),
//           )
//           .toList();
//     }

//     return filtered;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Section
//             _buildHeader(),
//             const SizedBox(height: 24),

//             // Filters and Search Section
//             _buildFiltersSection(),
//             const SizedBox(height: 24),

//             // Data Table Section
//             Expanded(child: _buildDataTable()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Column(
//               children: [
//                 Text(
//                   'Projects',
//                   style: GoogleFonts.montserrat(
//                     fontSize: 32,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Manage and monitor all projects across your organization',
//               style: GoogleFonts.montserrat(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),

//         // Add Project Button
//         ElevatedButton.icon(
//           onPressed: () => _showAddProjectDialog(),
//           icon: const Icon(Icons.add, size: 18),
//           label: Text(
//             'Add Project',
//             style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.black87, // button color
//             foregroundColor: Colors.white, // text & icon color
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(6),
//             ),
//             elevation: 0, // optional: matches your second button
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFiltersSection() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.02),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           /// 🔎 Search Field (slightly bigger than dropdowns)
//           Flexible(
//             flex: 2, // proportionally bigger than dropdowns
//             child: TextFormField(
//               controller: _searchController,
//               decoration: _inputDecoration('Search projects...', Icons.search),
//             ),
//           ),

//           const SizedBox(width: 16),

//           /// 🌍 Region Filter
//           Flexible(
//             flex: 2,
//             child: DropdownButtonFormField<String>(
//               value: _selectedRegions,
//               decoration: _dropdownDecoration(),
//               items: ['All Regions', 'North America', 'Europe']
//                   .map(
//                     (e) => DropdownMenuItem(
//                       value: e,
//                       child: Text(e, style: GoogleFonts.montserrat()),
//                     ),
//                   )
//                   .toList(),
//               onChanged: (value) => setState(() => _selectedRegions = value!),
//             ),
//           ),

//           const SizedBox(width: 16),

//           /// 📊 Status Filter
//           Flexible(
//             flex: 2,
//             child: DropdownButtonFormField<String>(
//               value: _selectedStatus,
//               decoration: _dropdownDecoration(),
//               items: ['All Status', 'Active', 'Inactive', 'Pending']
//                   .map(
//                     (e) => DropdownMenuItem(
//                       value: e,
//                       child: Text(e, style: GoogleFonts.montserrat()),
//                     ),
//                   )
//                   .toList(),
//               onChanged: (value) => setState(() => _selectedStatus = value!),
//             ),
//           ),

//           const SizedBox(width: 16),

//           /// 🔄 Sort Filter
//           Flexible(
//             flex: 2,
//             child: DropdownButtonFormField<String>(
//               value: _selectedFilterType,
//               decoration: _dropdownDecoration(),
//               items: ['Last Updated', 'Name', 'Device Count']
//                   .map(
//                     (e) => DropdownMenuItem(
//                       value: e,
//                       child: Text(e, style: GoogleFonts.montserrat()),
//                     ),
//                   )
//                   .toList(),
//               onChanged: (value) =>
//                   setState(() => _selectedFilterType = value!),
//             ),
//           ),

//           const SizedBox(width: 16),

//           /// 🔲 Grid / List Toggle Buttons
//           Row(
//             mainAxisSize: MainAxisSize.min, // keeps buttons compact
//             children: [
//               _buildViewToggleButton(
//                 icon: Icons.grid_view_rounded,
//                 isSelected: _isGridView,
//                 onTap: () => setState(() => _isGridView = true),
//               ),
//               const SizedBox(width: 8),
//               _buildViewToggleButton(
//                 icon: Icons.view_list_rounded,
//                 isSelected: !_isGridView,
//                 onTap: () => setState(() => _isGridView = false),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.grey[400]),
//       filled: true,
//       fillColor: Colors.grey[50],
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.grey[300]!),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.grey[300]!),
//       ),
//       focusedBorder: const OutlineInputBorder(
//         borderSide: BorderSide(color: Colors.black87),
//       ),
//     );
//   }

//   InputDecoration _dropdownDecoration() {
//     return InputDecoration(
//       filled: true,
//       fillColor: Colors.grey[50],
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.grey[300]!),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.grey[300]!),
//       ),
//     );
//   }

//   // Widget _buildFiltersSection() {
//   //   return Container(
//   //     padding: const EdgeInsets.all(24),
//   //     decoration: BoxDecoration(
//   //       color: Colors.white,
//   //       borderRadius: BorderRadius.circular(12),
//   //       border: Border.all(color: Colors.grey[200]!),
//   //       boxShadow: [
//   //         BoxShadow(
//   //           color: Colors.black.withValues(alpha: 0.02),
//   //           blurRadius: 8,
//   //           spreadRadius: 0,
//   //           offset: const Offset(0, 2),
//   //         ),
//   //       ],
//   //     ),

//   //     child: Wrap(
//   //       spacing: 16,
//   //       runSpacing: 16,
//   //       crossAxisAlignment: WrapCrossAlignment.center,
//   //       children: [
//   //         // Search Field
//   //         SizedBox(
//   //           width: 220,
//   //           child: TextFormField(
//   //             controller: _searchController,
//   //             decoration: InputDecoration(
//   //               labelText: 'Search projects...',
//   //               labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
//   //               prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
//   //               border: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               enabledBorder: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               focusedBorder: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: const BorderSide(color: Colors.black87),
//   //               ),
//   //               filled: true,
//   //               fillColor: Colors.grey[50],
//   //             ),
//   //           ),
//   //         ),
//   //         // const SizedBox(width: 16),

//   //         // Regions Filter
//   //         SizedBox(
//   //           width: 180,
//   //           child: DropdownButtonFormField<String>(
//   //             value: _selectedRegions,
//   //             decoration: InputDecoration(
//   //               // labelText: 'Role',
//   //               labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
//   //               border: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               enabledBorder: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               filled: true,
//   //               fillColor: Colors.grey[50],
//   //             ),
//   //             items: ['All Regions', 'North America', 'Europe']
//   //                 .map(
//   //                   (role) => DropdownMenuItem(
//   //                     value: role,
//   //                     child: Text(role, style: GoogleFonts.montserrat()),
//   //                   ),
//   //                 )
//   //                 .toList(),
//   //             onChanged: (value) {
//   //               setState(() {
//   //                 _selectedRegions = value!;
//   //               });
//   //             },
//   //           ),
//   //         ),
//   //         // const SizedBox(width: 16),

//   //         // Role Status
//   //         SizedBox(
//   //           width: 180,
//   //           child: DropdownButtonFormField<String>(
//   //             value: _selectedStatus,
//   //             decoration: InputDecoration(
//   //               // labelText: 'Role',
//   //               labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
//   //               border: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               enabledBorder: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               filled: true,
//   //               fillColor: Colors.grey[50],
//   //             ),
//   //             items: ['All Status', 'Active', 'Inactive', 'Pending']
//   //                 .map(
//   //                   (role) => DropdownMenuItem(
//   //                     value: role,
//   //                     child: Text(role, style: GoogleFonts.montserrat()),
//   //                   ),
//   //                 )
//   //                 .toList(),
//   //             onChanged: (value) {
//   //               setState(() {
//   //                 _selectedStatus = value!;
//   //               });
//   //             },
//   //           ),
//   //         ),
//   //         // const SizedBox(width: 16),

//   //         // Status Filter type
//   //         SizedBox(
//   //           width: 180,
//   //           child: DropdownButtonFormField<String>(
//   //             value: _selectedFilterType,
//   //             decoration: InputDecoration(
//   //               // labelText: 'Status',
//   //               labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
//   //               border: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               enabledBorder: OutlineInputBorder(
//   //                 borderRadius: BorderRadius.circular(8),
//   //                 borderSide: BorderSide(color: Colors.grey[300]!),
//   //               ),
//   //               filled: true,
//   //               fillColor: Colors.grey[50],
//   //             ),
//   //             items: ['Last Updated', 'Name', 'Device Count']
//   //                 .map(
//   //                   (status) => DropdownMenuItem(
//   //                     value: status,
//   //                     child: Text(status, style: GoogleFonts.montserrat()),
//   //                   ),
//   //                 )
//   //                 .toList(),
//   //             onChanged: (value) {
//   //               setState(() {
//   //                 _selectedFilterType = value!;
//   //               });
//   //             },
//   //           ),
//   //         ),
//   //         // const SizedBox(width: 16),

//   //         // View Toggle Buttons
//   //         Row(
//   //           children: [
//   //             _buildViewToggleButton(
//   //               icon: Icons.grid_view_rounded,
//   //               isSelected: _isGridView,
//   //               onTap: () {
//   //                 setState(() {
//   //                   _isGridView = true;
//   //                 });
//   //               },
//   //             ),
//   //             const SizedBox(width: 8),
//   //             _buildViewToggleButton(
//   //               icon: Icons.view_list_rounded,
//   //               isSelected: !_isGridView,
//   //               onTap: () {
//   //                 setState(() {
//   //                   _isGridView = false;
//   //                 });
//   //               },
//   //             ),
//   //           ],
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   Widget _buildDataTable() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.02),
//             blurRadius: 8,
//             spreadRadius: 0,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListenableBuilder(
//         listenable: _viewModel,
//         builder: (context, child) {
//           if (_viewModel.isLoading) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.black87),
//             );
//           }

//           if (_viewModel.hasError) {
//             return _buildErrorState();
//           }

//           final filteredProjects = _filteredProjects;

//           if (filteredProjects.isEmpty) {
//             return _buildEmptyState();
//           }

//           return Column(
//             children: [
//               // Results summary
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     topRight: Radius.circular(12),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       '${filteredProjects.length} projects found',
//                       style: GoogleFonts.montserrat(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     Row(
//                       children: [
//                         IconButton(
//                           onPressed: () => _viewModel.loadProjects(),
//                           icon: const Icon(Icons.refresh, size: 18),
//                           tooltip: 'Refresh',
//                         ),
//                         const SizedBox(width: 8),
//                         ElevatedButton.icon(
//                           onPressed: () => _showAddProjectDialog(),
//                           icon: const Icon(Icons.add, size: 18),
//                           label: Text(
//                             'Add Project',
//                             style: GoogleFonts.montserrat(
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.black87,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               // Enterprise Data Table
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: const BorderRadius.only(
//                       bottomLeft: Radius.circular(12),
//                       bottomRight: Radius.circular(12),
//                     ),
//                     border: Border.all(color: Colors.grey[200]!),
//                   ),
//                   child: DataTable2(
//                     columnSpacing: 12,
//                     horizontalMargin: 24,
//                     minWidth: 800,
//                     dataRowHeight: 72,
//                     headingRowHeight: 56,
//                     headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
//                     border: TableBorder(
//                       horizontalInside: BorderSide(
//                         color: Colors.grey[200]!,
//                         width: 1,
//                       ),
//                     ),
//                     // ... inside _buildDataTable columns: [ ... ]
//                     columns: [
//                       DataColumn2(
//                         label: Text(
//                           'Project',
//                           style: GoogleFonts.montserrat(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         size: ColumnSize.L,
//                       ),
//                       DataColumn2(
//                         label: Text(
//                           'Category',
//                           style: GoogleFonts.montserrat(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ), // Changed from Role
//                         size: ColumnSize.M,
//                       ),
//                       DataColumn2(
//                         label: Text(
//                           'Status',
//                           style: GoogleFonts.montserrat(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         size: ColumnSize.S,
//                       ),
//                       DataColumn2(
//                         label: Text(
//                           'Progress',
//                           style: GoogleFonts.montserrat(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ), // Changed from Last Login
//                         size: ColumnSize.S,
//                       ),
//                       DataColumn2(
//                         label: Text(
//                           'Actions',
//                           style: GoogleFonts.montserrat(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         size: ColumnSize.S,
//                         fixedWidth: 100,
//                       ),
//                     ],
//                     rows: filteredProjects.map((project) {
//                       return DataRow2(
//                         cells: [
//                           DataCell(_buildProjectCell(project)),
//                           DataCell(
//                             _buildRoleBadge(project.category),
//                           ), // Using category now
//                           DataCell(_buildStatusBadge(project.status)),
//                           DataCell(
//                             // Progress Column
//                             Text(
//                               '${(project.progress * 100).toInt()}%',
//                               style: GoogleFonts.montserrat(
//                                 fontSize: 13,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ),
//                           DataCell(_buildActionsMenu(project)),
//                         ],
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildRoleBadge(String role) {
//     Color color;
//     switch (role.toLowerCase()) {
//       case 'admin':
//         color = Colors.purple;
//         break;
//       case 'manager':
//         color = Colors.blue;
//         break;
//       case 'project':
//         color = Colors.green;
//         break;
//       default:
//         color = Colors.grey;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withValues(alpha: 0.3)),
//       ),
//       child: Text(
//         role,
//         style: GoogleFonts.montserrat(
//           fontSize: 12,
//           fontWeight: FontWeight.w500,
//           color: _getShadeColor(color),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusBadge(String status) {
//     Color color;
//     IconData icon;
//     switch (status.toLowerCase()) {
//       case 'active':
//         color = Colors.green;
//         icon = Icons.check_circle;
//         break;
//       case 'inactive':
//         color = Colors.red;
//         icon = Icons.cancel;
//         break;
//       case 'pending':
//         color = Colors.orange;
//         icon = Icons.schedule;
//         break;
//       default:
//         color = Colors.grey;
//         icon = Icons.help;
//     }

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 14, color: color),
//         const SizedBox(width: 6),
//         Text(
//           status,
//           style: GoogleFonts.montserrat(
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//             color: _getShadeColor(color),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(48),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.people, size: 64, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'No projects found',
//               style: GoogleFonts.montserrat(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Try adjusting your search criteria or add new projects',
//               style: GoogleFonts.montserrat(
//                 fontSize: 14,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(48),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Failed to load projects',
//               style: GoogleFonts.montserrat(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.red[600],
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () => _viewModel.loadProjects(),
//               icon: const Icon(Icons.refresh, size: 18),
//               label: Text(
//                 'Retry',
//                 style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.black87,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // String _formatDate(DateTime date) {
//   //   final now = DateTime.now();
//   //   final difference = now.difference(date);

//   //   if (difference.inDays == 0) {
//   //     return 'Today';
//   //   } else if (difference.inDays == 1) {
//   //     return 'Yesterday';
//   //   } else if (difference.inDays < 7) {
//   //     return '${difference.inDays} days ago';
//   //   } else {
//   //     return '${date.day}/${date.month}/${date.year}';
//   //   }
//   // }

//   // void _showAddProjectDialog() {
//   //   // TODO: Implement add project dialog
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     const SnackBar(content: Text('Add project functionality coming soon')),
//   //   );
//   // }

//   void _showAddProjectDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return Dialog(
//           insetPadding: const EdgeInsets.all(24),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(
//               maxWidth: 600, // good for web
//               maxHeight: 700,
//             ),
//             child: const NewProjectWidget(),
//           ),
//         );
//       },
//     );
//   }

//   void _showEditProjectDialog(ProjectEntity project) {
//     // TODO: Implement edit project dialog
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text('Edit project: ${project.title}')));
//   }

//   void _showDeleteProjectDialog(ProjectEntity project) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Delete Project',
//           style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
//         ),
//         content: Text(
//           'Are you sure you want to delete ${project.title}? This action cannot be undone.',
//           style: GoogleFonts.montserrat(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Cancel', style: GoogleFonts.montserrat()),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               // TODO: Implement delete project
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Deleted project: ${project.title}')),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: Text(
//               'Delete',
//               style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getShadeColor(Color color) {
//     if (color == Colors.purple) return Colors.purple[700]!;
//     if (color == Colors.blue) return Colors.blue[700]!;
//     if (color == Colors.green) return Colors.green[700]!;
//     if (color == Colors.orange) return Colors.orange[700]!;
//     if (color == Colors.red) return Colors.red[700]!;
//     return Colors.grey[700]!;
//   }

//   Widget _buildProjectCell(ProjectEntity project) {
//     return Row(
//       children: [
//         CircleAvatar(
//           radius: 20,
//           backgroundColor: Colors.blue[100],
//           child: Text(
//             project.title.isNotEmpty
//                 ? project.title
//                       .split(' ')
//                       .map((e) => e[0])
//                       .take(2)
//                       .join()
//                       .toUpperCase()
//                 : project.title[0].toUpperCase(),
//             style: GoogleFonts.montserrat(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//               color: Colors.blue[700],
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 project.title.isNotEmpty ? project.title : 'No Name',
//                 style: GoogleFonts.montserrat(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 project.description,
//                 style: GoogleFonts.montserrat(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionsMenu(ProjectEntity project) {
//     return PopupMenuButton<String>(
//       icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
//       offset: const Offset(-50, 0),
//       itemBuilder: (context) => [
//         PopupMenuItem(
//           value: 'edit',
//           child: Row(
//             children: [
//               Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
//               const SizedBox(width: 8),
//               Text('Edit', style: GoogleFonts.montserrat(fontSize: 13)),
//             ],
//           ),
//         ),
//         PopupMenuItem(
//           value: 'delete',
//           child: Row(
//             children: [
//               const Icon(Icons.delete_outline, size: 16, color: Colors.red),
//               const SizedBox(width: 8),
//               Text(
//                 'Delete',
//                 style: GoogleFonts.montserrat(fontSize: 13, color: Colors.red),
//               ),
//             ],
//           ),
//         ),
//       ],
//       onSelected: (value) {
//         switch (value) {
//           case 'edit':
//             _showEditProjectDialog(project);
//             break;
//           case 'delete':
//             _showDeleteProjectDialog(project);
//             break;
//         }
//       },
//     );
//   }
// }

// Widget _buildViewToggleButton({
//   required IconData icon,
//   required bool isSelected,
//   required VoidCallback onTap,
// }) {
//   return InkWell(
//     onTap: onTap,
//     borderRadius: BorderRadius.circular(8),
//     child: Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.black87 : Colors.grey[100],
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isSelected ? Colors.black87 : Colors.grey[300]!,
//         ),
//       ),
//       child: Icon(
//         icon,
//         size: 20,
//         color: isSelected ? Colors.white : Colors.grey[600],
//       ),
//     ),
//   );
// }


//_______OLDER VERSION________

// import 'package:data_table_2/data_table_2.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';


// class Project {
//   final String title;
//   final String client;
//   final String deadline;
//   final String status;
//   VoidCallback? action;

//   Project({
//     required this.title,
//     required this.client,
//     this.deadline = "November",
//     this.status = "demo",
//     this.action,
//   });
// }

// class ProjectsPage extends StatefulWidget {
//   const ProjectsPage({super.key});

//   @override
//   State<ProjectsPage> createState() => _ProjectsPageState();
// }

// class _ProjectsPageState extends State<ProjectsPage> {
// final List<Project> projects =  [
//     Project(title: 'Website Redesign', client: 'A', status: "çompleted"),
//     Project(title: 'Mobile App', client: 'B', deadline: 'August'),
//     Project(title: 'Backend API', client: 'A', action: () {}),
//   ];

//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String _selectedRole = 'All';
//   String _selectedStatus = 'All';

//   @override

//   void initState() {
//     super.initState();
//     // _initializeViewModel();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//       });
//     });
//   }

//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Section
//             _buildHeader(),
//             const SizedBox(height: 24),

//             // Filters and Search Section
//             _buildFiltersSection(),
//             const SizedBox(height: 24),

//             //Data Table Section
//             Expanded(child: _buildDataTable()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Project Management',
//               style: GoogleFonts.montserrat(
//                 fontSize: 32,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Manage your projects and their users',
//               style: GoogleFonts.montserrat(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildFiltersSection() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.02),
//             blurRadius: 8,
//             spreadRadius: 0,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Search Field
//           Expanded(
//             flex: 2,
//             child: TextFormField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search projects...',
//                 labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
//                 prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: const BorderSide(color: Colors.black87),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[50],
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),

//           // Role Filter
//           Expanded(
//             child: DropdownButtonFormField<String>(
//               value: _selectedRole,
//               decoration: InputDecoration(
//                 labelText: 'Client',
//                 labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[50],
//               ),
//               items: ['All', 'Admin', 'Manager', 'User', 'Viewer']
//                   .map(
//                     (role) => DropdownMenuItem(
//                       value: role,
//                       child: Text(role, style: GoogleFonts.montserrat()),
//                     ),
//                   )
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedRole = value!;
//                 });
//               },
//             ),
//           ),
//           const SizedBox(width: 16),

//           // Status Filter
//           Expanded(
//             child: DropdownButtonFormField<String>(
//               value: _selectedStatus,
//               decoration: InputDecoration(
//                 labelText: 'Status',
//                 labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[50],
//               ),
//               items: ['All', 'Active', 'Inactive', 'Pending']
//                   .map(
//                     (status) => DropdownMenuItem(
//                       value: status,
//                       child: Text(status, style: GoogleFonts.montserrat()),
//                     ),
//                   )
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedStatus = value!;
//                 });
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   //DATA TABLE
//   Widget _buildDataTable() {
//     return Scaffold(
//         body: Column(
//           children: [
//             // Results summary
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(12),
//                   topRight: Radius.circular(12),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     '3 projects found',
//                     style: GoogleFonts.montserrat(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       IconButton(
//                         onPressed: () {},
//                         icon: const Icon(Icons.refresh, size: 18),
//                         tooltip: 'Refresh',
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.add, size: 18),
//                         label: Text(
//                           'Add Project',
//                           style: GoogleFonts.montserrat(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black87,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 12,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Enterprise Data Table
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(12),
//                     bottomRight: Radius.circular(12),
//                   ),
//                   border: Border.all(color: Colors.grey[200]!),
//                 ),
//                 child: DataTable2(
//                   columnSpacing: 12,
//                   horizontalMargin: 24,
//                   minWidth: 800,
//                   dataRowHeight: 72,
//                   headingRowHeight: 56,
//                   headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
//                   border: TableBorder(
//                     horizontalInside: BorderSide(
//                       color: Colors.grey[200]!,
//                       width: 1,
//                     ),
//                   ),
//                   columns: [
//                     DataColumn2(
//                       label: Text(
//                         'Project',
//                         style: GoogleFonts.montserrat(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       size: ColumnSize.L,
//                     ),
//                     DataColumn2(
//                       label: Text(
//                         'Client',
//                         style: GoogleFonts.montserrat(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       size: ColumnSize.S,
//                     ),
//                     DataColumn2(
//                       label: Text(
//                         'Deadline',
//                         style: GoogleFonts.montserrat(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       size: ColumnSize.S,
//                     ),
//                     DataColumn2(
//                       label: Text(
//                         'Status',
//                         style: GoogleFonts.montserrat(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       size: ColumnSize.M,
//                     ),
//                     DataColumn2(
//                       label: Text(
//                         'Actions',
//                         style: GoogleFonts.montserrat(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       size: ColumnSize.S,
//                       fixedWidth: 100,
//                     ),
//                   ],
//                   rows: projects.map((project) {
//                     return DataRow2(
//                       cells: [
//                         DataCell(Text(project.title)),
//                         DataCell(Text(project.client)),
//                         DataCell(Text(project.deadline)),
//                         DataCell(Text(project.status)),
//                         DataCell(_buildActionsMenu(project)),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }


// //ACTIONS MENU
//     Widget _buildActionsMenu(Project project) {
//       return PopupMenuButton<String>(
//         icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
//         offset: const Offset(-50, 0),
//         itemBuilder: (context) => [
//           PopupMenuItem(
//             value: 'edit',
//             child: Row(
//               children: [
//                 Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
//                 const SizedBox(width: 8),
//                 Text('Edit', style: GoogleFonts.montserrat(fontSize: 13)),
//               ],
//             ),
//           ),
//           PopupMenuItem(
//             value: 'delete',
//             child: Row(
//               children: [
//                 const Icon(Icons.delete_outline, size: 16, color: Colors.red),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Delete',
//                   style: GoogleFonts.montserrat(fontSize: 13, color: Colors.red),
//                 ),
//               ],
//             ),
//           ),
//           PopupMenuItem(
//             value: 'view',
//             child: Row(
//               children: [
//                 Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey[700]),
//                 const SizedBox(width: 8),
//                 Text('View', style: GoogleFonts.montserrat(fontSize: 13)),
//               ],
//             ),
//           ),
//         ],
//         // onSelected: (value) {
//         //   switch (value) {
//         //     case 'edit':
//         //       _showEditUserDialog(user);
//         //       break;
//         //     case 'delete':
//         //       _showDeleteUserDialog(user);
//         //       break;
//         //   }
//         // },
//       );
//     }
//   }