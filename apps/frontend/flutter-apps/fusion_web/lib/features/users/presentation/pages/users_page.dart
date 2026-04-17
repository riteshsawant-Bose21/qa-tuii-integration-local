import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/users/presentation/viewmodels/users_viewmodel.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:fusion_web/features/users/presentation/widgets/invite_user_dialog.dart';
import 'package:fusion_web/features/users/presentation/widgets/edit_user_dialog.dart';
import 'package:fusion_web/features/users/presentation/widgets/user_ui_helpers.dart';
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
        backgroundColor: context.colorScheme.elevation1,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Metrics
              _buildHeaderWithMetrics(),
              const SizedBox(height: 24),

              // Single container with filters + table (like projects page)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildFiltersRow(),
                      const SizedBox(height: 24),
                      Expanded(child: _buildTableContent()),
                    ],
                  ),
                ),
              ),
            ],
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
                    const PageHeader(
                      title: 'Users',
                      subtitle:
                          'Manage user lifecycle, invitations, and account-level access',
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
                    backgroundColor: context.colorScheme.primaryColor,
                    foregroundColor: context.colorScheme.white,
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
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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
                    color: context.colorScheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: context.colorScheme.elevation6,
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

  Widget _buildFiltersRow() {
    return Row(
      children: [
        // Search Field
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _searchController,
            style: TextStyle(color: context.colorScheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Search users...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: context.colorScheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Role Filter
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            dropdownColor: context.colorScheme.elevation2,
            style: TextStyle(color: context.colorScheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Role',
              filled: true,
              fillColor: context.colorScheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Roles'),
              ),
              ...['Admin', 'Designer', 'Technician'].map(
                (role) =>
                    DropdownMenuItem<String>(value: role, child: Text(role)),
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
            dropdownColor: context.colorScheme.elevation2,
            style: TextStyle(color: context.colorScheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Status',
              filled: true,
              fillColor: context.colorScheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
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

        // Clear filters
        if (_selectedRole != null ||
            _selectedStatus != null ||
            _searchQuery.isNotEmpty) ...[
          const SizedBox(width: 16),
          IconButton(
            onPressed: _clearFilters,
            icon: Icon(
              Icons.clear,
              size: 20,
              color: context.colorScheme.elevation6,
            ),
            tooltip: 'Clear Filters',
          ),
        ],
      ],
    );
  }

  Widget _buildTableContent() {
    return BlocBuilder<UsersViewModel, BaseState<List<UserEntity>>>(
      builder: (context, state) {
        if (state is LoadingState<List<UserEntity>>) {
          return Center(
            child: CircularProgressIndicator(color: context.colorScheme.white),
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
            // Data Table
            Expanded(
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 24,
                minWidth: 1000,
                dataRowHeight: 80,
                headingRowHeight: 56,
                headingRowColor: WidgetStateProperty.all(
                  context.colorScheme.elevation3,
                ),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: context.colorScheme.strokeLight,
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
                        color: context.colorScheme.textPrimary,
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
                        color: context.colorScheme.textPrimary,
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
                        color: context.colorScheme.textPrimary,
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
                        color: context.colorScheme.textPrimary,
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
                        color: context.colorScheme.textPrimary,
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
                      DataCell(
                        buildRoleChips(user.roles, context, limit: true),
                      ),
                      DataCell(buildStatusChip(user.status)),
                      DataCell(_buildLastLoginCell(user.lastLoginAt)),
                      DataCell(_buildActionsCell(user)),
                    ],
                    onTap: () => _openUserProfile(user),
                  );
                }).toList(),
              ),
            ),
          ],
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
          backgroundColor: context.colorScheme.elevation3,
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
                    color: context.colorScheme.textPrimary,
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
                  color: context.colorScheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: context.colorScheme.elevation6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
          color: context.colorScheme.elevation6,
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
            color: context.colorScheme.textPrimary,
          ),
        ),
        Text(
          DateFormat('MMM dd').format(lastLogin),
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: context.colorScheme.elevation6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCell(UserEntity user) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        color: context.colorScheme.elevation2,
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: context.colorScheme.elevation6,
        ),
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
  
  // Dialog and action methods
  void _showInviteUserDialog() {
    showDialog(
      context: context,
      builder: (context) => InviteUserDialog(
        onInvite: (List<Map<String, dynamic>> invites) async {
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

  void _openUserProfile(UserEntity user) {
    context.push('/users/${user.id}', extra: user);
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
        _openUserProfile(user);
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
          Icon(
            Icons.people_outline,
            size: 64,
            color: context.colorScheme.elevation6,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: context.colorScheme.elevation6,
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
              backgroundColor: context.colorScheme.primaryColor,
              foregroundColor: context.colorScheme.white,
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: context.colorScheme.errorText,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.errorText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _viewModel.errorMessage,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: context.colorScheme.elevation6,
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
              backgroundColor: context.colorScheme.primaryColor,
              foregroundColor: context.colorScheme.white,
            ),
          ),
        ],
      ),
    );
  }
}
