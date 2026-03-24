import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/organizations/presentation/viewmodels/organizations_viewmodel.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_project_entity.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:go_router/go_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

class OrganizationProfilePage extends StatefulWidget {
  final String organizationId;

  const OrganizationProfilePage({super.key, required this.organizationId});

  @override
  State<OrganizationProfilePage> createState() =>
      _OrganizationProfilePageState();
}

class _OrganizationProfilePageState extends State<OrganizationProfilePage> {
  late final OrganizationsViewModel _viewModel =
      ServiceLocator().organizationsViewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.loadOrganizationById(widget.organizationId);
  }

  Color _getStatusColor(OrganizationStatus status) {
    switch (status) {
      case OrganizationStatus.active:
        return Colors.green;
      case OrganizationStatus.inactive:
        return Colors.red;
      case OrganizationStatus.pending:
        return Colors.orange;
      case OrganizationStatus.suspended:
        return Colors.red.shade800;
    }
  }

  Color _getTypeColor(OrganizationType type) {
    switch (type) {
      case OrganizationType.distributor:
        return Colors.purple;
      case OrganizationType.reseller:
        return Colors.blue;
      case OrganizationType.endUser:
        return Colors.green.shade700;
    }
  }

  Color _getUserStatusColor(UserStatus status) {
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

  Color _getProjectStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Colors.green;
      case ProjectStatus.completed:
        return Colors.blue;
      case ProjectStatus.paused:
        return Colors.orange;
      case ProjectStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button and Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Organization Info and Metrics
                _buildOrganizationInfo(),
                const SizedBox(height: 32),

                // Users Section
                _buildUsersSection(),
                const SizedBox(height: 32),

                // Projects Section
                _buildProjectsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go(AppConstants.organizationsRoute),
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Back to Organizations',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildOrganizationInfo() {
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        final organization = _viewModel.selectedOrganization;

        if (organization == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Organization Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _getTypeColor(
                      organization.type,
                    ).withOpacity(0.1),
                    child: Text(
                      organization.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _getTypeColor(organization.type),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  organization.type,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                organization.type.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getTypeColor(organization.type),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '• ${organization.region.displayName}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (organization.description != null) ...[
                const SizedBox(height: 20),
                Text(
                  organization.description!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Users',
                      organization.userCount.toString(),
                      Icons.people_outline,
                      Colors.blue.shade100,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Ongoing Projects',
                      organization.ongoingProjectsCount.toString(),
                      Icons.work_outline,
                      Colors.orange.shade100,
                      Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Completed Projects',
                      organization.completedProjectsCount.toString(),
                      Icons.check_circle_outline,
                      Colors.green.shade100,
                      Colors.green.shade700,
                    ),
                  ),
                ],
              ),

              // Contact Information
              if (organization.email != null ||
                  organization.phone != null ||
                  organization.address != null) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'Contact Information',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactInfo(organization),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(OrganizationEntity organization) {
    return Column(
      children: [
        if (organization.email != null)
          _buildContactItem(Icons.email_outlined, 'Email', organization.email!),
        if (organization.phone != null)
          _buildContactItem(Icons.phone_outlined, 'Phone', organization.phone!),
        if (organization.address != null)
          _buildContactItem(
            Icons.location_on_outlined,
            'Address',
            organization.address!,
          ),
        if (organization.website != null)
          _buildContactItem(
            Icons.web_outlined,
            'Website',
            organization.website!,
          ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Users (${_viewModel.organizationUsers.length})',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          _buildUsersTable(),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    final users = _viewModel.organizationUsers;

    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 20,
        minWidth: 600,
        columns: [
          DataColumn2(
            label: Text(
              'Name',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text(
              'Email',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text(
              'Role',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text(
              'Joined',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.M,
          ),
        ],
        rows: users.map((user) {
          return DataRow2(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to user profile or handle click
                          context.go('${AppConstants.usersRoute}/${user.id}');
                        },
                        child: Text(
                          user.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  user.email,
                  style: GoogleFonts.inter(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.primaryRole,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('MMM dd, yyyy').format(user.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Projects (${_viewModel.organizationProjects.length})',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ),
          const Divider(height: 0),
          _buildProjectsTable(),
        ],
      ),
    );
  }

  Widget _buildProjectsTable() {
    final projects = _viewModel.organizationProjects;

    if (projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.work_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No projects found',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 20,
        minWidth: 800,
        columns: [
          DataColumn2(
            label: Text(
              'Project Name',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text(
              'Region',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text(
              'Status',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text(
              'Type',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text(
              'Last Updated',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            size: ColumnSize.M,
          ),
        ],
        rows: projects.map((project) {
          return DataRow2(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to project detail or handle click
                        context.go(
                          '${AppConstants.projectsRoute}/${project.id}',
                        );
                      },
                      child: Text(
                        project.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (project.description != null)
                      Text(
                        project.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              DataCell(Text(project.region, style: GoogleFonts.inter())),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getProjectStatusColor(
                      project.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project.status.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getProjectStatusColor(project.status),
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  project.type.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('MMM dd, yyyy').format(project.lastUpdated),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
