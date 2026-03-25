import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/users/presentation/viewmodels/users_viewmodel.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/users/presentation/widgets/invite_user_dialog.dart';
import 'package:fusion_web/features/users/presentation/widgets/edit_user_dialog.dart';
import 'package:fusion_web/features/users/presentation/widgets/user_profile_dialog.dart';
import 'package:fusion_web/core/services/service_locator.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final UsersViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRole;
  UserStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();

    // Reset cached viewmodel to ensure fresh instance with all dependencies
    ServiceLocator().resetUsersViewModel();
    _viewModel = ServiceLocator().usersViewModel;

    _viewModel.initialize();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _viewModel.searchUsers(_searchQuery);
    });
  }

  void _applyFilters() {
    _viewModel.applyFilters(role: _selectedRole, status: _selectedStatus);
  }

  void _clearFilters() {
    setState(() {
      _selectedRole = null;
      _selectedStatus = null;
      _searchController.clear();
    });
    _viewModel.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - 48, // Account for padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section with Metrics
                      _buildHeaderWithMetrics(),
                      const SizedBox(height: 24),

                      // Filters and Search Section
                      _buildFiltersSection(),
                      const SizedBox(height: 24),

                      // Data Table Section
                      SizedBox(
                        height:
                            constraints.maxHeight -
                            400, // Reserve space for header and filters
                        child: _buildDataTable(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithMetrics() {
    return BlocBuilder<UsersViewModel, BaseState<List<UserEntity>>>(
      builder: (context, state) {
        final metrics = _viewModel.metrics;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Users',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage user lifecycle, invitations, and account-level access',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showInviteUserDialog,
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(
                    'Invite User',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            // Metrics Cards - Only 3 cards as per Figma
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Users',
                      metrics['total']?.toString() ?? '15',
                      Icons.people_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Active Users',
                      metrics['active']?.toString() ?? '15',
                      Icons.person_outline,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Pending Invitations',
                      metrics['invited']?.toString() ?? '0',
                      Icons.schedule_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
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
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Use responsive layout for smaller screens
              if (constraints.maxWidth < 1200) {
                return Column(
                  children: [
                    // Search Field
                    TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search users...',
                        labelStyle: GoogleFonts.montserrat(
                          color: Colors.grey[600],
                        ),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Role Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              labelStyle: GoogleFonts.montserrat(
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Roles'),
                              ),
                              ...['Admin', 'Designer', 'Technician'].map(
                                (role) => DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Status Filter
                        Expanded(
                          child: DropdownButtonFormField<UserStatus>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              labelStyle: GoogleFonts.montserrat(
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: [
                              const DropdownMenuItem<UserStatus>(
                                value: null,
                                child: Text('All Statuses'),
                              ),
                              ...UserStatus.values.map(
                                (status) => DropdownMenuItem<UserStatus>(
                                  value: status,
                                  child: Text(status.displayName),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search users...',
                          labelStyle: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                          ),
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
                          labelStyle: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                          ),
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
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          ...['Admin', 'Designer', 'Technician'].map(
                            (role) => DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<UserStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                          ),
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
                        items: [
                          const DropdownMenuItem<UserStatus>(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...UserStatus.values.map(
                            (status) => DropdownMenuItem<UserStatus>(
                              value: status,
                              child: Text(status.displayName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          // Clear filters button
          if (_selectedRole != null ||
              _selectedStatus != null ||
              _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text('Clear Filters', style: GoogleFonts.montserrat()),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
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
          child: BlocBuilder<UsersViewModel, BaseState<List<UserEntity>>>(
            builder: (context, state) {
              if (state is LoadingState<List<UserEntity>>) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black87),
                );
              }

              if (state is ErrorState<List<UserEntity>>) {
                return _buildErrorState();
              }

              final users = _viewModel.users;

              if (users.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // Results summary and actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${users.length} user${users.length == 1 ? '' : 's'} found',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _viewModel.loadUsers(),
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),

                  // Data Table
                  Expanded(
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 24,
                      minWidth: 1000,
                      dataRowHeight: 80,
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
                            'Roles',
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
                      rows: users.map((user) {
                        return DataRow2(
                          cells: [
                            DataCell(_buildUserCell(user)),
                            DataCell(_buildRolesCell(user.roles)),
                            DataCell(_buildStatusCell(user.status)),
                            DataCell(_buildLastLoginCell(user.lastLoginAt)),
                            DataCell(_buildActionsCell(user)),
                          ],
                          onTap: () => _showUserProfile(user),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Helper methods for building table cells
  Widget _buildUserCell(UserEntity user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[100],
          backgroundImage: user.avatar != null
              ? NetworkImage(user.avatar!)
              : null,
          child: user.avatar == null
              ? Text(
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
                )
              : null,
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

  Widget _buildRolesCell(List<String> roles) {
    if (roles.isEmpty) {
      return Text(
        'No roles',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          roles.take(2).map((role) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                role,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            );
          }).toList()..addAll(
            roles.length > 2
                ? [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${roles.length - 2}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ]
                : [],
          ),
    );
  }

  Widget _buildStatusCell(UserStatus status) {
    Color color = _getStatusColor(status);
    IconData icon = _getStatusIcon(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          status.displayName,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLastLoginCell(DateTime? lastLogin) {
    if (lastLogin == null) {
      return Text(
        'Never',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    String timeAgo;

    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inMinutes}m ago';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeAgo,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          DateFormat('MMM dd').format(lastLogin),
          style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionsCell(UserEntity user) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
        offset: const Offset(-100, 0),
        constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'view',
            child: _buildMenuItemWithIcon(
              Icons.visibility_outlined,
              'View Profile',
              Colors.blue,
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: _buildMenuItemWithIcon(
              Icons.edit_outlined,
              'Edit User',
              Colors.grey[700]!,
            ),
          ),
          if (user.status == UserStatus.invited ||
              user.status == UserStatus.pending)
            PopupMenuItem(
              value: 'resend',
              child: _buildMenuItemWithIcon(
                Icons.email_outlined,
                'Resend Invite',
                Colors.orange,
              ),
            ),
          PopupMenuItem(
            value: user.isActive ? 'deactivate' : 'activate',
            child: _buildMenuItemWithIcon(
              user.isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outlined,
              user.isActive ? 'Deactivate' : 'Activate',
              user.isActive ? Colors.red : Colors.green,
            ),
          ),
        ],
        onSelected: (value) => _handleUserAction(value, user),
      ),
    );
  }

  Widget _buildMenuItemWithIcon(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.montserrat(fontSize: 13, color: color)),
      ],
    );
  }

  // Helper methods for colors and icons
  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.invited:
        return Colors.orange;
      case UserStatus.pending:
        return Colors.amber;
      case UserStatus.inactive:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Icons.check_circle;
      case UserStatus.invited:
        return Icons.email;
      case UserStatus.pending:
        return Icons.pending;
      case UserStatus.inactive:
        return Icons.block;
    }
  }

  // Dialog and action methods
  void _showInviteUserDialog() {
    showDialog(
      context: context,
      builder: (context) => InviteUserDialog(
        onInvite: (List<Map<String, String>> invites) async {
          // Use the new bulk invite method
          await _viewModel.inviteUsersToOrganization(invites);

          if (_viewModel.hasError) {
            _showErrorSnackBar(_viewModel.errorMessage);
          } else {
            final count = invites.length;
            final message = count == 1
                ? 'User invitation sent successfully!'
                : '$count user invitations sent successfully!';
            _showSuccessSnackBar(message);
          }
        },
      ),
    );
  }

  // Helper function to extract name from email
  String _getNameFromEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex > 0) {
      return email.substring(0, atIndex);
    }
    return email;
  }

  void _showUserProfile(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(
        user: user,
        onEdit: () => _showEditUserDialog(user),
        onActivate: () => _activateUser(user),
        onDeactivate: () => _deactivateUser(user),
        onResendInvite: () => _resendInvite(user),
      ),
    );
  }

  void _showEditUserDialog(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onUpdate: (updatedUser) async {
          await _viewModel.updateUser(updatedUser);

          if (_viewModel.hasError) {
            _showErrorSnackBar(_viewModel.errorMessage);
          } else {
            _showSuccessSnackBar('User updated successfully!');
          }
        },
      ),
    );
  }

  void _handleUserAction(String action, UserEntity user) {
    switch (action) {
      case 'view':
        _showUserProfile(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'resend':
        _resendInvite(user);
        break;
      case 'activate':
        _activateUser(user);
        break;
      case 'deactivate':
        _deactivateUser(user);
        break;
    }
  }

  Future<void> _activateUser(UserEntity user) async {
    await _viewModel.activateUser(user.id);

    if (_viewModel.hasError) {
      _showErrorSnackBar(_viewModel.errorMessage);
    } else {
      _showSuccessSnackBar('${user.name} has been activated');
    }
  }

  Future<void> _deactivateUser(UserEntity user) async {
    await _viewModel.deactivateUser(user.id);

    if (_viewModel.hasError) {
      _showErrorSnackBar(_viewModel.errorMessage);
    } else {
      _showSuccessSnackBar('${user.name} has been deactivated');
    }
  }

  Future<void> _resendInvite(UserEntity user) async {
    await _viewModel.resendInvite(user.id);

    if (_viewModel.hasError) {
      _showErrorSnackBar(_viewModel.errorMessage);
    } else {
      _showSuccessSnackBar('Invitation resent to ${user.email}');
    }
  }

  // Helper UI methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
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
            'Try adjusting your search or filters',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showInviteUserDialog,
            icon: const Icon(Icons.person_add),
            label: Text(
              'Invite First User',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
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
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _viewModel.loadUsers(),
            icon: const Icon(Icons.refresh),
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
    );
  }
}
