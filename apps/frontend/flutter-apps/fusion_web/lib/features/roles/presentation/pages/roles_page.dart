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

class _RolesPageState extends State<RolesPage> {
  late RolesViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
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
    _viewModel.dispose();
    super.dispose();
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
            Expanded(child: _buildRolesTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Management',
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage system roles and permissions',
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
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
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
    // TODO: Implement edit role dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit role "${role.name}" functionality coming soon'),
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
}
