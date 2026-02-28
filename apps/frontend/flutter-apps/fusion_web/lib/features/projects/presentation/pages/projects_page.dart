// // WORKING VERSION - before adding action button
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fusion_web/core/presentation/base_viewmodel.dart';
// import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
// import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
// import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
// import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
// import 'package:fusion_web/features/projects/data/models/project_model.dart';
// import 'package:fusion_web/core/services/service_locator.dart';
// import 'package:fusion_web/features/projects/presentation/pages/project_detail_page.dart';
// import 'package:fusion_web/core/constants/app_constants.dart';
// import 'package:fusion_lib/fusion_widgets/shared_widgets/project/project_dialog.dart';
// import 'package:fusion_lib/fusion_widgets/shared_widgets/project/animated_blur_dialog_route.dart';
// import 'dart:ui';
// import 'package:fusion_lib/fusion_widgets/shared_widgets/project/confirmation_dialog.dart';
// import 'package:fusion_web/features/projects/presentation/dialogs/invite_user_dialog.dart';
// import 'package:go_router/go_router.dart';

// class ProjectsPage extends StatefulWidget {
//   const ProjectsPage({super.key});

//   @override
//   State<ProjectsPage> createState() => _ProjectsPageState();
// }

// class _ProjectsPageState extends State<ProjectsPage> {
//   late final ProjectsViewModel _viewModel = ServiceLocator().projectsViewModel;

//   final TextEditingController _searchController = TextEditingController();

//   String _searchQuery = '';
//   String _selectedRegions = 'All';
//   String _selectedStatus = 'All';
//   String _selectedFilterType = 'Last Updated';

//   bool _isGridView = false;

//   @override
//   void initState() {
//     super.initState();
//     _viewModel.loadProjects();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//         _viewModel.searchProjects(_searchQuery);
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

  
//   // List<ProjectModel> get _filteredProjects {
//   //   final projects = _viewModel.projects;
//   //   if (projects.isEmpty) return [];

//   //   List<ProjectModel> filtered = List.from(projects);

//   //   if (_searchQuery.isNotEmpty) {
//   //     filtered = filtered.where((project) {
//   //       return project.name.toLowerCase().contains(
//   //             _searchQuery.toLowerCase(),
//   //           ) ||
//   //           project.description.toLowerCase().contains(
//   //             _searchQuery.toLowerCase(),
//   //           ) ||
//   //           project.clientName.toLowerCase().contains(
//   //             _searchQuery.toLowerCase(),
//   //           );
//   //     }).toList();
//   //   }

//   //   if (_selectedRegions != 'All') {
//   //     filtered = filtered
//   //         .where(
//   //           (p) => p.region.toLowerCase() == _selectedRegions.toLowerCase(),
//   //         )
//   //         .toList();
//   //   }

//   //   if (_selectedStatus != 'All') {
//   //     filtered = filtered
//   //         .where((p) => p.status.toLowerCase() == _selectedStatus.toLowerCase())
//   //         .toList();
//   //   }

//   //   return filtered;
//   // }

  

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _viewModel,
//       child: Scaffold(
//         backgroundColor: Colors.grey[50],
//         body: Padding(
//           padding: const EdgeInsets.all(24),
//           child: BlocBuilder<ProjectsViewModel, BaseState<List<ProjectModel>>>(
//             builder: (context, state) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildHeader(),
//                   const SizedBox(height: 24),
//                   _buildFiltersSection(),
//                   const SizedBox(height: 24),
//                   Expanded(child: _buildContent()),
//                 ],
//               );
//             },
//           ),
//         ),
        
//       ),
//     );
//   }

//   // ======================================================
//   // HEADER
//   // ======================================================

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // LEFT SIDE (Title + subtitle)
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Projects',
//               style: GoogleFonts.montserrat(
//                 fontSize: 32,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//               ),
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

//         // RIGHT SIDE (New Project Button)
//         ElevatedButton.icon(
//           onPressed: () => ProjectActionsHandler.create(
//             context: context,
//             viewModel: _viewModel,
//           ),

//           icon: const Icon(Icons.add, size: 18),
//           label: Text(
//             'New Project',
//             style: GoogleFonts.montserrat(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.black87,
//             foregroundColor: Colors.white,
//             elevation: 0,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(6),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ======================================================
//   // FILTERS SECTION
//   // ======================================================

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
//           Flexible(
//             flex: 2,
//             child: TextFormField(
//               controller: _searchController,
//               decoration: _inputDecoration('Search projects...', Icons.search),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Flexible(
//             flex: 1,
//             child: _dropdown(_selectedRegions, [
//               'All',
//               'Indoor',
//               'Outdoor',
//               'Hybrid',
//             ], (v) => setState(() => _selectedRegions = v!)),
//           ),
//           const SizedBox(width: 16),
//           Flexible(
//             flex: 1,
//             child: _dropdown(_selectedStatus, [
//               'All',
//               'Proposal',
//               'Planning',
//               'Commissioned',
//             ], (v) => setState(() => _selectedStatus = v!)),
//           ),
//           const SizedBox(width: 16),
//           Row(
//             children: [
//               _buildToggle(Icons.grid_view_rounded, true),
//               const SizedBox(width: 8),
//               _buildToggle(Icons.view_list_rounded, false),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _dropdown(
//     String value,
//     List<String> items,
//     ValueChanged<String?> onChanged,
//   ) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       decoration: _dropdownDecoration(),
//       items: items
//           .map(
//             (e) => DropdownMenuItem(
//               value: e,
//               child: Text(e, style: GoogleFonts.montserrat()),
//             ),
//           )
//           .toList(),
//       onChanged: onChanged,
//     );
//   }

//   Widget _buildToggle(IconData icon, bool isGrid) {
//     final isSelected = _isGridView == isGrid;
//     return InkWell(
//       onTap: () => setState(() => _isGridView = isGrid),
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.black87 : Colors.grey[100],
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
//       ),
//     );
//   }

//   // ======================================================
//   // CONTENT
//   // ======================================================

//   Widget _buildContent() {
//     return BlocBuilder<ProjectsViewModel, BaseState<List<ProjectModel>>>(
//       builder: (context, state) {
//         if (state is LoadingState) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (state is ErrorState) {
//           return Center(
//             child: Text(
//               (state as ErrorState).message,
//               style: GoogleFonts.montserrat(
//                 fontSize: 16,
//                 color: Colors.red[400],
//               ),
//             ),
//           );
//         }
//         final projects = (state as LoadedState<List<ProjectModel>>).data;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               //TODO: This from should come from API.
//               'Showing ${projects.length} of ${projects.length} projects',
//               style: GoogleFonts.montserrat(
//                 fontSize: 14,
//                 color: Colors.grey[500],
//               ),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: _isGridView
//                   ? _buildGridView(projects)
//                   : _buildListView(projects),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ======================================================
//   // LIST VIEW
//   // ======================================================

    

//   // ======================================================
//   // GRID VIEW
//   // ======================================================

  

//   // ======================================================
//   // SHARED WIDGETS
//   // ======================================================

  

//   // Widget _buildActionsMenu(ProjectModel project) {
//   //   return PopupMenuButton<String>(
//   //     icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
//   //     padding: EdgeInsets.zero,
//   //     onSelected: (value) {
//   //       switch (value) {
//   //         case 'edit':
//   //           _openEditProjectDialog(project);
//   //           break;

//   //         case 'invite':
//   //           _showInviteUserDialog(project);
//   //           break;

//   //         case 'archive':
//   //           _showArchiveDialog(project);
//   //           break;

//   //         case 'delete':
//   //           _showDeleteDialog(project);
//   //           break;
//   //       }
//   //     },

//   //     itemBuilder: (context) => [
//   //       PopupMenuItem(
//   //         value: 'edit',
//   //         child: Row(
//   //           children: [
//   //             Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
//   //             const SizedBox(width: 8),
//   //             const Text('Edit'),
//   //           ],
//   //         ),
//   //       ),
//   //       PopupMenuItem(
//   //         value: 'invite',
//   //         child: Row(
//   //           children: [
//   //             Icon(
//   //               Icons.person_add_outlined,
//   //               size: 16,
//   //               color: Colors.grey[700],
//   //             ),
//   //             const SizedBox(width: 8),
//   //             const Text('Invite User'),
//   //           ],
//   //         ),
//   //       ),
//   //       PopupMenuItem(
//   //         value: 'archive',
//   //         child: Row(
//   //           children: [
//   //             Icon(Icons.archive_outlined, size: 16, color: Colors.grey[700]),
//   //             const SizedBox(width: 8),
//   //             const Text('Archive'),
//   //           ],
//   //         ),
//   //       ),
//   //       PopupMenuItem(
//   //         value: 'delete',
//   //         child: Row(
//   //           children: [
//   //             const Icon(Icons.delete_outline, size: 16, color: Colors.red),
//   //             const SizedBox(width: 8),
//   //             const Text('Delete', style: TextStyle(color: Colors.red)),
//   //           ],
//   //         ),
//   //       ),
//   //     ],
//   //   );
//   // }

//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.grey[400]),
//       filled: true,
//       fillColor: Colors.grey[50],
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//     );
//   }

//   InputDecoration _dropdownDecoration() {
//     return InputDecoration(
//       filled: true,
//       fillColor: Colors.grey[50],
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//     );
//   }
// }




// WORKING VERSION - before adding action button
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/projects/presentation/handlers/project_actions_handler.dart';
import 'package:fusion_web/features/projects/presentation/widgets/project_actions_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/projects/data/datasources/project_datasource.dart';
import 'package:fusion_web/features/projects/data/repositories/projects_repository_impl.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/features/projects/presentation/pages/project_detail_page.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_lib/fusion_widgets/shared_widgets/project/project_dialog.dart';
import 'package:fusion_lib/fusion_widgets/shared_widgets/project/animated_blur_dialog_route.dart';
import 'dart:ui';
import 'package:fusion_lib/fusion_widgets/shared_widgets/project/confirmation_dialog.dart';
import 'package:fusion_web/features/projects/presentation/dialogs/invite_user_dialog.dart';
import 'package:go_router/go_router.dart';

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
  String _selectedFilterType = 'Last Updated';

  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _viewModel.loadProjects();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _viewModel.searchProjects(_searchQuery);
      });
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

  // List<ProjectModel> get _filteredProjects {
  //   final projects = _viewModel.projects;
  //   if (projects.isEmpty) return [];

  //   List<ProjectModel> filtered = List.from(projects);

  //   if (_searchQuery.isNotEmpty) {
  //     filtered = filtered.where((project) {
  //       return project.name.toLowerCase().contains(
  //             _searchQuery.toLowerCase(),
  //           ) ||
  //           project.description.toLowerCase().contains(
  //             _searchQuery.toLowerCase(),
  //           ) ||
  //           project.clientName.toLowerCase().contains(
  //             _searchQuery.toLowerCase(),
  //           );
  //     }).toList();
  //   }

  //   if (_selectedRegions != 'All') {
  //     filtered = filtered
  //         .where(
  //           (p) => p.region.toLowerCase() == _selectedRegions.toLowerCase(),
  //         )
  //         .toList();
  //   }

  //   if (_selectedStatus != 'All') {
  //     filtered = filtered
  //         .where((p) => p.status.toLowerCase() == _selectedStatus.toLowerCase())
  //         .toList();
  //   }

  //   return filtered;
  // }

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

        // RIGHT SIDE (New Project Button)
        ElevatedButton.icon(
          onPressed: () => ProjectActionsHandler.create(
            context: context,
            viewModel: _viewModel,
          ),

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
            flex: 1,
            child: _dropdown(_selectedRegions, [
              'All',
              'Indoor',
              'Outdoor',
              'Hybrid',
            ], (v) => setState(() => _selectedRegions = v!)),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 1,
            child: _dropdown(_selectedStatus, [
              'All',
              'Proposal',
              'Planning',
              'Commissioned',
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
                    child: _statusBadge(p.status),
                  ),
                ),

                /// 4️⃣ HEALTH
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      _healthStat(
                        Icons.check_circle_outline_rounded,
                        const Color(0xFF22C55E),
                        p.healthyDevices,
                      ),
                      const SizedBox(width: 12),
                      _healthStat(
                        Icons.warning_amber_rounded,
                        const Color(0xFFF59E0B),
                        p.warningDevices,
                      ),
                      const SizedBox(width: 12),
                      _healthStat(
                        Icons.cancel_outlined,
                        const Color(0xFFEF4444),
                        p.criticalDevices,
                      ),
                    ],
                  ),
                ),

                /// 5️⃣ INCIDENTS
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _incidentsBadge(p.incidents),
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
                        onEdit: () => ProjectActionsHandler.edit(
                          context: context,
                          project: p,
                          viewModel: _viewModel,
                        ),
                        onInvite: () => ProjectActionsHandler.invite(
                          context: context,
                          project: p,
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
                if (totalDevices >= 0) ...[
                  _deviceHealthBox(p),
                  const SizedBox(height: 12),
                ],

                // Open incidents warning — only if > 0
                if (p.incidents >= 0) ...[
                  _openIncidentsWarning(p.incidents),
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
                      onEdit: () => ProjectActionsHandler.edit(
                        context: context,
                        project: p,
                        viewModel: _viewModel,
                      ),
                      onInvite: () => ProjectActionsHandler.invite(
                        context: context,
                        project: p,
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

  // ======================================================
  // SHARED WIDGETS
  // ======================================================

  Widget _statusBadge(String status) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;

    if (lower == 'planning') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    } else if (lower == 'proposal') {
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

  Widget _deviceHealthBox(ProjectModel p) {
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

  // Widget _buildActionsMenu(ProjectModel project) {
  //   return PopupMenuButton<String>(
  //     icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
  //     padding: EdgeInsets.zero,
  //     onSelected: (value) {
  //       switch (value) {
  //         case 'edit':
  //           _openEditProjectDialog(project);
  //           break;

  //         case 'invite':
  //           _showInviteUserDialog(project);
  //           break;

  //         case 'archive':
  //           _showArchiveDialog(project);
  //           break;

  //         case 'delete':
  //           _showDeleteDialog(project);
  //           break;
  //       }
  //     },

  //     itemBuilder: (context) => [
  //       PopupMenuItem(
  //         value: 'edit',
  //         child: Row(
  //           children: [
  //             Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
  //             const SizedBox(width: 8),
  //             const Text('Edit'),
  //           ],
  //         ),
  //       ),
  //       PopupMenuItem(
  //         value: 'invite',
  //         child: Row(
  //           children: [
  //             Icon(
  //               Icons.person_add_outlined,
  //               size: 16,
  //               color: Colors.grey[700],
  //             ),
  //             const SizedBox(width: 8),
  //             const Text('Invite User'),
  //           ],
  //         ),
  //       ),
  //       PopupMenuItem(
  //         value: 'archive',
  //         child: Row(
  //           children: [
  //             Icon(Icons.archive_outlined, size: 16, color: Colors.grey[700]),
  //             const SizedBox(width: 8),
  //             const Text('Archive'),
  //           ],
  //         ),
  //       ),
  //       PopupMenuItem(
  //         value: 'delete',
  //         child: Row(
  //           children: [
  //             const Icon(Icons.delete_outline, size: 16, color: Colors.red),
  //             const SizedBox(width: 8),
  //             const Text('Delete', style: TextStyle(color: Colors.red)),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

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

