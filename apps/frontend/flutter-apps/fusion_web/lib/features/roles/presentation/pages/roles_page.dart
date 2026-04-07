import 'package:flutter/material.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:fusion_web/features/roles/presentation/viewmodels/roles_viewmodel.dart';
import 'package:fusion_web/features/roles/data/datasources/roles_datasource.dart';
import 'package:fusion_web/features/roles/data/repositories/roles_repository_impl.dart';
import 'package:fusion_web/features/roles/domain/usecases/roles_usecases.dart';
import 'package:fusion_web/features/roles/domain/entities/role_entity.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> with TickerProviderStateMixin {
  late RolesViewModel _viewModel;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeViewModel();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _viewModel.searchRoles(_searchQuery);
      });
    });
  }

  void _initializeViewModel() {
    final dataSource = RolesDataSource();
    final repository = RolesRepositoryImpl(dataSource);
    final useCases = RolesUseCases(repository);
    _viewModel = RolesViewModel(useCases);
    _viewModel.loadRoles();
    _viewModel.loadAvailablePermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildTabSection(constraints),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Roles & Access Control',
          subtitle:
              'Define and manage what users can see and do within the Fusion ecosystem',
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final roles = _viewModel.roles;
        final systemRoles = roles.where((r) => r.isSystem).length;
        final customRoles = roles.where((r) => !r.isSystem).length;
        final totalUsers = roles.fold<int>(
          0,
          (sum, role) => sum + role.userCount,
        );

        return Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Roles',
                roles.length.toString(),
                Icons.admin_panel_settings_outlined,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'System Roles',
                systemRoles.toString(),
                Icons.settings_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'Custom Roles',
                customRoles.toString(),
                Icons.tune_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'Active Users',
                totalUsers.toString(),
                Icons.people_outlined,
                Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(BoxConstraints constraints) {
    return Container(
      height: constraints.maxHeight - 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.black,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Role Definitions'),
                Tab(text: 'Audit Trail'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildRoleDefinitionsTab(), _buildAuditTrailTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDefinitionsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Definitions Overview',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'List of all available roles with descriptions and permission sets',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) {
                  final filteredRoles = _getFilteredRoles();
                  return Text(
                    '${filteredRoles.length} roles found',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildRolesTable()),
        ],
      ),
    );
  }

  Widget _buildRolesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          switch (_viewModel.state) {
            case RolesViewState.initial:
            case RolesViewState.loading:
              return _buildLoadingState();
            case RolesViewState.loaded:
              return _buildLoadedState();
            case RolesViewState.empty:
              return _buildEmptyState();
            case RolesViewState.error:
              return _buildErrorState();
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(color: Colors.black87),
      ),
    );
  }

  Widget _buildLoadedState() {
    final filteredRoles = _getFilteredRoles();

    if (filteredRoles.isEmpty) {
      return _buildEmptyState();
    }

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 24,
      minWidth: 900,
      dataRowHeight: 80,
      headingRowHeight: 56,
      showCheckboxColumn: false,
      headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
      dataRowColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.grey[50];
        }
        return null;
      }),
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      columns: [
        DataColumn2(
          label: Text(
            'Role',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text(
            'Users',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text(
            'Permissions',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text(
            'Actions',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          size: ColumnSize.S,
          fixedWidth: 150,
        ),
      ],
      rows: filteredRoles.map((role) {
        return DataRow2(
          cells: [
            DataCell(_buildRoleCell(role)),
            DataCell(_buildUserCountCell(role.userCount)),
            DataCell(_buildPermissionsCell(role.permissions)),
            DataCell(_buildViewPermissionsAction(role)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRoleCell(RoleEntity role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            role.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            role.description.isNotEmpty
                ? role.description
                : _getDefaultDescription(role.name),
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getDefaultDescription(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return 'Full administrative access with all permissions';
      case 'designer':
        return 'Project design and configuration access';
      case 'technician':
        return 'Device installation and maintenance access';
      default:
        return 'Role description not available';
    }
  }

  Widget _buildUserCountCell(int userCount) {
    return Text(
      '$userCount users',
      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
    );
  }

  Widget _buildPermissionsCell(List<String> permissions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${permissions.length} permissions',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F7B0F),
        ),
      ),
    );
  }

  Widget _buildViewPermissionsAction(RoleEntity role) {
    return InkWell(
      onTap: () => _showPermissionsDialog(role),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              'View Permissions',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No roles found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or add new roles',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load roles',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewModel.errorMessage,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _viewModel.loadRoles(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit Trail on Role Changes',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track who changed user roles, before/after states, and timestamps',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildAuditTrailTable()),
        ],
      ),
    );
  }

  Widget _buildAuditTrailTable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Audit Trail',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feature coming soon - Track role changes and approval history',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<RoleEntity> _getFilteredRoles() {
    final roles = _viewModel.filteredRoles;
    return roles.where((role) {
      if (_selectedType != 'All') {
        if (_selectedType == 'System' && !role.isSystem) return false;
        if (_selectedType == 'Custom' && role.isSystem) return false;
      }
      return true;
    }).toList();
  }

  void _showPermissionsDialog(RoleEntity role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permissions - ${role.name}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            children: [
              Text(
                'View all permissions assigned to this role',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: role.permissions.isEmpty
                      ? Center(
                          child: Text(
                            'No permissions assigned',
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: role.permissions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(
                                Icons.security,
                                color: Colors.blue[600],
                                size: 16,
                              ),
                              title: Text(
                                role.permissions[index],
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                              trailing: Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 16,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
