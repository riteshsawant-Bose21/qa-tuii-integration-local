import 'package:flutter/material.dart';
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
  String _selectedStatus = 'All';

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
    // Force a fresh load after fixing the API response parsing
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
      backgroundColor: Colors.grey[50],
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
                    _buildRolesMetrics(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roles & Access Control',
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Define and manage what users can see and do within the Fusion ecosystem',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showCreateRoleDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Create Role',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search roles by name, description, or permissions...',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Role Type Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Role Type',
                labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              items: ['All', 'System', 'Custom'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.montserrat()),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),

          // Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              items: ['All', 'Active', 'Inactive'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.montserrat()),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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

    return Column(
      children: [
        // Results summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredRoles.length} roles found',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _viewModel.loadRoles(),
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRoleDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add Role',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Enterprise Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 24,
              minWidth: 900,
              dataRowHeight: 72,
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
                horizontalInside: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              columns: [
                DataColumn2(
                  label: Text(
                    'Role',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Text(
                    'Users',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Text(
                    'Permissions',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(
                    'Type',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Text(
                    'Actions',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  size: ColumnSize.S,
                  fixedWidth: 100,
                ),
              ],
              rows: filteredRoles.map((role) {
                return DataRow2(
                  cells: [
                    DataCell(_buildRoleCell(role)),
                    DataCell(_buildUserCountBadge(role.userCount)),
                    DataCell(_buildPermissionsBadge(role.permissions)),
                    DataCell(_buildTypeBadge(role.isSystem)),
                    DataCell(_buildActionsMenu(role)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCell(RoleEntity role) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: role.isSystem ? Colors.orange[100] : Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: role.isSystem ? Colors.orange[300]! : Colors.blue[300]!,
              width: 1,
            ),
          ),
          child: Icon(
            role.isSystem ? Icons.admin_panel_settings : Icons.person_outline,
            color: role.isSystem ? Colors.orange[700] : Colors.blue[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      role.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (role.isSystem)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'SYSTEM',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                role.description.isNotEmpty
                    ? role.description
                    : 'No description available',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCountBadge(int userCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$userCount users',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildPermissionsBadge(List<String> permissions) {
    return InkWell(
      onTap: () => _showPermissionsListDialog(permissions),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: permissions.isEmpty ? Colors.red[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: permissions.isEmpty ? Colors.red[300]! : Colors.green[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              permissions.isEmpty ? Icons.warning_outlined : Icons.security,
              size: 12,
              color: permissions.isEmpty ? Colors.red[700] : Colors.green[700],
            ),
            const SizedBox(width: 4),
            Text(
              permissions.isEmpty
                  ? 'No permissions'
                  : '${permissions.length} permissions',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: permissions.isEmpty
                    ? Colors.red[700]
                    : Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(bool isSystem) {
    final color = isSystem ? Colors.orange : Colors.blue;
    final text = isSystem ? 'System' : 'Custom';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color[700],
        ),
      ),
    );
  }

  Widget _buildActionsMenu(RoleEntity role) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
      offset: const Offset(-50, 0),
      splashRadius: 20,
      tooltip: 'Role actions',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text('View Details', style: GoogleFonts.montserrat(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'permissions',
          child: Row(
            children: [
              Icon(Icons.security_outlined, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Manage Permissions',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        if (!role.isSystem) ...[
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text('Edit Role', style: GoogleFonts.montserrat(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_outlined, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Duplicate',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete Role',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'System Role - Protected',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showRoleDetailsDialog(role);
            break;
          case 'permissions':
            _showPermissionsDialog(role);
            break;
          case 'edit':
            _showEditRoleDialog(role);
            break;
          case 'duplicate':
            _showDuplicateRoleDialog(role);
            break;
          case 'delete':
            _showDeleteRoleDialog(role);
            break;
        }
      },
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
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or add new roles',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
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
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewModel.errorMessage,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
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
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RoleEntity> _getFilteredRoles() {
    final roles = _viewModel.filteredRoles;

    return roles.where((role) {
      // Filter by type
      if (_selectedType != 'All') {
        if (_selectedType == 'System' && !role.isSystem) return false;
        if (_selectedType == 'Custom' && role.isSystem) return false;
      }

      // Add more filters as needed
      return true;
    }).toList();
  }

  void _showRoleDetailsDialog(RoleEntity role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              role.isSystem ? Icons.admin_panel_settings : Icons.person_outline,
              color: role.isSystem ? Colors.orange[700] : Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                role.name,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Description',
                role.description.isNotEmpty
                    ? role.description
                    : 'No description',
              ),
              _buildDetailRow(
                'Type',
                role.isSystem ? 'System Role' : 'Custom Role',
              ),
              _buildDetailRow('Users Assigned', '${role.userCount} users'),
              _buildDetailRow(
                'Permissions',
                '${role.permissions.length} permissions',
              ),
              _buildDetailRow('Created', _formatDate(role.createdAt)),
              if (role.updatedAt != null)
                _buildDetailRow('Last Updated', _formatDate(role.updatedAt!)),
              const SizedBox(height: 16),
              Text(
                'Permissions:',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: role.permissions.isEmpty
                    ? Center(
                        child: Text(
                          'No permissions assigned',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: role.permissions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            title: Text(
                              role.permissions[index],
                              style: GoogleFonts.montserrat(fontSize: 13),
                            ),
                          );
                        },
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
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
          if (!role.isSystem)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditRoleDialog(role);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Edit Role',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.montserrat())),
        ],
      ),
    );
  }

  void _showPermissionsDialog(RoleEntity role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Manage Permissions - ${role.name}',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            children: [
              Text(
                'Permission management functionality coming soon',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
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
                          style: GoogleFonts.montserrat(fontSize: 13),
                        ),
                        trailing: Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
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
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionsListDialog(List<String> permissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permissions (${permissions.length})',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 300,
          height: 200,
          child: permissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        size: 48,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No permissions assigned',
                        style: GoogleFonts.montserrat(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 16,
                      ),
                      title: Text(
                        permissions[index],
                        style: GoogleFonts.montserrat(fontSize: 13),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDuplicateRoleDialog(RoleEntity role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Duplicate Role',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Create a copy of "${role.name}" with the same permissions?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Duplicate role "${role.name}" functionality coming soon',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Duplicate',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  void _showAddRoleDialog() {
    // TODO: Implement add role dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add role functionality coming soon')),
    );
  }

  void _showEditRoleDialog(RoleEntity role) {
    final nameController = TextEditingController(text: role.name);
    final descriptionController = TextEditingController(text: role.description);
    final formKey = GlobalKey<FormState>();

    // Define available role types
    final List<String> roleTypes = ['Admin', 'Designer', 'Technician'];
    String selectedRoleType = roleTypes.contains(role.name)
        ? role.name
        : roleTypes.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            width: 600,
            height: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Role',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form
                Expanded(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role Type Dropdown
                        Text(
                          'Role Type',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedRoleType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                          ),
                          items: roleTypes.map((String roleType) {
                            return DropdownMenuItem<String>(
                              value: roleType,
                              child: Text(
                                roleType,
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedRoleType = newValue;
                                nameController.text = newValue;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a role type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Role Name (auto-filled from dropdown)
                        TextFormField(
                          controller: nameController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Role Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.badge_outlined),
                            fillColor: Colors.grey[50],
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Description
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Role Information
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Role Permissions',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getRolePermissionsInfo(selectedRoleType),
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.montserrat(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          // Show loading
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Updating role...'),
                                  ],
                                ),
                                duration: Duration(seconds: 30),
                              ),
                            );
                          }

                          // Get permissions for the selected role type
                          final rolePermissions = _getRolePermissions(
                            selectedRoleType,
                          );

                          // Update the role
                          final success = await _viewModel.updateRole(
                            roleId: role.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            permissions: rolePermissions,
                          );

                          // Hide loading snackbar and show result
                          if (mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Role "${nameController.text.trim()}" updated successfully',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_viewModel.errorMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Update Role',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteRoleDialog(RoleEntity role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Role',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete the role "${role.name}"? This action cannot be undone.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _viewModel.deleteRole(role.id);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Role "${role.name}" deleted successfully'),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_viewModel.errorMessage)),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // New comprehensive methods for Roles & Access Control
  Widget _buildRolesMetrics() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final roles = _viewModel.roles;
        final systemRoles = roles.where((r) => r.isSystem).length;
        final customRoles = roles.where((r) => !r.isSystem).length;
        final totalUsers = roles.fold<int>(
          0,
          (sum, role) => sum + role.userCount,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: (constraints.maxWidth - 48) / 4,
                  child: _buildMetricCard(
                    'Total Roles',
                    roles.length.toString(),
                    Icons.admin_panel_settings,
                    Colors.blue,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - 48) / 4,
                  child: _buildMetricCard(
                    'System Roles',
                    systemRoles.toString(),
                    Icons.settings,
                    Colors.green,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - 48) / 4,
                  child: _buildMetricCard(
                    'Custom Roles',
                    customRoles.toString(),
                    Icons.tune,
                    Colors.orange,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - 48) / 4,
                  child: _buildMetricCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(
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
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
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
              labelStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.black87,
              indicatorWeight: 2,
              tabs: const [
                Tab(
                  icon: Icon(Icons.list_alt, size: 18),
                  text: 'Role Definitions',
                ),
                Tab(icon: Icon(Icons.history, size: 18), text: 'Audit Trail'),
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
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'List of all available roles with types, descriptions, and permission sets',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildRolesTable()),
        ],
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
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track who changed user roles, before/after states, and timestamps',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
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
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feature coming soon - Track role changes and approval history',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Create Role feature coming soon!',
          style: GoogleFonts.montserrat(),
        ),
      ),
    );
  }

  void _showBulkAssignDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bulk Assign feature coming soon!',
          style: GoogleFonts.montserrat(),
        ),
      ),
    );
  }

  // Helper methods for formatting permissions
  String _formatPermissionName(String permission) {
    // Convert snake_case or camelCase to Title Case
    return permission
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  String _getPermissionDescription(String permission) {
    // Provide descriptions for common permissions
    final descriptions = {
      'user_read': 'View user profiles and information',
      'user_write': 'Create and modify user accounts',
      'user_delete': 'Remove user accounts from the system',
      'role_read': 'View roles and their permissions',
      'role_write': 'Create and modify roles and permissions',
      'role_delete': 'Remove roles from the system',
      'project_read': 'View project details and information',
      'project_write': 'Create and modify projects',
      'project_delete': 'Remove projects from the system',
      'device_read': 'View device information and status',
      'device_write': 'Configure and manage devices',
      'device_delete': 'Remove devices from the system',
      'settings_read': 'View system settings and configuration',
      'settings_write': 'Modify system settings and configuration',
      'dashboard_access': 'Access to main dashboard and overview',
      'reports_read': 'View reports and analytics',
      'reports_write': 'Create and modify reports',
      'audit_read': 'View audit logs and system activity',
      'admin_access': 'Full administrative access to the system',
    };

    return descriptions[permission] ??
        'Permission for ${_formatPermissionName(permission).toLowerCase()}';
  }

  // Helper methods for role dropdown functionality
  IconData _getRoleIcon(String roleType) {
    switch (roleType) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Designer':
        return Icons.design_services;
      case 'Technician':
        return Icons.engineering;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String roleType) {
    switch (roleType) {
      case 'Admin':
        return Colors.red[600]!;
      case 'Designer':
        return Colors.purple[600]!;
      case 'Technician':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getRolePermissionsInfo(String roleType) {
    switch (roleType) {
      case 'Admin':
        return 'Full system access with all administrative privileges including user management, system settings, and complete control over all features.';
      case 'Designer':
        return 'Design-focused permissions including project creation, design asset management, and collaboration tools with limited administrative access.';
      case 'Technician':
        return 'Technical permissions including device management, system maintenance, troubleshooting tools, and operational control with restricted administrative access.';
      default:
        return 'Basic user permissions with limited access to system features.';
    }
  }

  List<String> _getRolePermissions(String roleType) {
    switch (roleType) {
      case 'Admin':
        return [
          'admin_access',
          'user_read',
          'user_write',
          'user_delete',
          'role_read',
          'role_write',
          'role_delete',
          'project_read',
          'project_write',
          'project_delete',
          'device_read',
          'device_write',
          'device_delete',
          'settings_read',
          'settings_write',
          'dashboard_access',
          'reports_read',
          'reports_write',
          'audit_read',
        ];
      case 'Designer':
        return [
          'dashboard_access',
          'project_read',
          'project_write',
          'user_read',
          'device_read',
          'reports_read',
        ];
      case 'Technician':
        return [
          'dashboard_access',
          'device_read',
          'device_write',
          'project_read',
          'user_read',
          'reports_read',
        ];
      default:
        return ['dashboard_access'];
    }
  }
}
