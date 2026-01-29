import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:fusion_web/features/users/presentation/viewmodels/users_viewmodel.dart';
import 'package:fusion_web/features/users/data/datasources/users_datasource.dart';
import 'package:fusion_web/features/users/data/repositories/users_repository_impl.dart';
import 'package:fusion_web/features/users/domain/usecases/users_usecases.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/core/services/service_locator.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late UsersViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';

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
    final remoteDataSource = UsersRemoteDataSource(apiService: apiService);
    final localDataSource = UsersLocalDataSource();
    final repository = UsersRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    _viewModel = UsersViewModel(
      getUsersUseCase: GetUsersUseCase(repository),
      getUserByIdUseCase: GetUserByIdUseCase(repository),
      createUserUseCase: CreateUserUseCase(repository),
      updateUserUseCase: UpdateUserUseCase(repository),
      deleteUserUseCase: DeleteUserUseCase(repository),
      searchUsersUseCase: SearchUsersUseCase(repository),
    );

    _viewModel.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  List<UserEntity> get _filteredUsers {
    final users = _viewModel.users;
    if (users.isEmpty) return [];

    List<UserEntity> filtered = List.from(users);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.role.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply role filter
    if (_selectedRole != 'All') {
      filtered = filtered.where((user) => user.role == _selectedRole).toList();
    }

    // Apply status filter
    if (_selectedStatus != 'All') {
      filtered = filtered
          .where((user) => user.status == _selectedStatus)
          .toList();
    }

    return filtered;
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
            // Header Section
            _buildHeader(),
            const SizedBox(height: 24),

            // Filters and Search Section
            _buildFiltersSection(),
            const SizedBox(height: 24),

            // Data Table Section
            Expanded(child: _buildDataTable()),
          ],
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
              'User Management',
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your team members and their access permissions',
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
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users...',
                labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Role Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Role',
                labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: ['All', 'Admin', 'Manager', 'User', 'Viewer']
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role, style: GoogleFonts.montserrat()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: ['All', 'Active', 'Inactive', 'Pending']
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status, style: GoogleFonts.montserrat()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
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

  Widget _buildDataTable() {
    return Container(
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
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black87),
            );
          }

          if (_viewModel.hasError) {
            return _buildErrorState();
          }

          final filteredUsers = _filteredUsers;

          if (filteredUsers.isEmpty) {
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
                      '${filteredUsers.length} users found',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _viewModel.loadUsers(),
                          icon: const Icon(Icons.refresh, size: 18),
                          tooltip: 'Refresh',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddUserDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            'Add User',
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
                    minWidth: 800,
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
                          'User',
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
                          'Role',
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
                          'Status',
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
                          'Last Login',
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
                    rows: filteredUsers.map((user) {
                      return DataRow2(
                        cells: [
                          DataCell(_buildUserCell(user)),
                          DataCell(_buildRoleBadge(user.role)),
                          DataCell(_buildStatusBadge(user.status)),
                          DataCell(
                            Text(
                              user.lastLoginAt != null
                                  ? _formatDate(user.lastLoginAt!)
                                  : 'Never',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          DataCell(_buildActionsMenu(user)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.purple;
        break;
      case 'manager':
        color = Colors.blue;
        break;
      case 'user':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getShadeColor(color),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'inactive':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          status,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _getShadeColor(color),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or add new users',
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
              'Failed to load users',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _viewModel.loadUsers(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddUserDialog() {
    // TODO: Implement add user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add user functionality coming soon')),
    );
  }

  void _showEditUserDialog(UserEntity user) {
    // TODO: Implement edit user dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit user: ${user.name}')));
  }

  void _showDeleteUserDialog(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete User',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${user.name}? This action cannot be undone.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted user: ${user.name}')),
              );
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

  Color _getShadeColor(Color color) {
    if (color == Colors.purple) return Colors.purple[700]!;
    if (color == Colors.blue) return Colors.blue[700]!;
    if (color == Colors.green) return Colors.green[700]!;
    if (color == Colors.orange) return Colors.orange[700]!;
    if (color == Colors.red) return Colors.red[700]!;
    return Colors.grey[700]!;
  }

  Widget _buildUserCell(UserEntity user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue[100],
          child: Text(
            user.name.isNotEmpty
                ? user.name
                      .split(' ')
                      .map((e) => e[0])
                      .take(2)
                      .join()
                      .toUpperCase()
                : user.email[0].toUpperCase(),
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name.isNotEmpty ? user.name : 'No Name',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
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

  Widget _buildActionsMenu(UserEntity user) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
      offset: const Offset(-50, 0),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text('Edit', style: GoogleFonts.montserrat(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditUserDialog(user);
            break;
          case 'delete':
            _showDeleteUserDialog(user);
            break;
        }
      },
    );
  }
}
