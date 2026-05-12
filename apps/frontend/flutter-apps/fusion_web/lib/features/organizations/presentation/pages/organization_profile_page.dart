import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
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

  Color _getTypeColor(OrganizationType type) {
    switch (type) {
      case OrganizationType.distributor:
        return Colors.purple;
      case OrganizationType.reseller:
        return Colors.blue;
      case OrganizationType.endUser:
        return Colors.green.shade700;
      case OrganizationType.bosePro:
        return Colors.orange.shade700;
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
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                TextButton.icon(
                  onPressed: () => context.go(AppConstants.organizationsRoute),
                  icon: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: context.colorScheme.elevation6,
                  ),
                  label: const FusionAppText(text: "Back to Organizations"),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return context.colorScheme.elevation2;
                      }
                      return Colors.transparent;
                    }),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildOrgDetailsCard()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildActivityCard()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildUsersSection(),
                        const SizedBox(height: 24),
                        _buildProjectsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        final organization = _viewModel.selectedOrganization;

        if (organization == null) {
          return Center(
            child: CircularProgressIndicator(
              color: context.colorScheme.primaryColor,
            ),
          );
        }

        final typeColor = _getTypeColor(organization.type);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: typeColor.withOpacity(0.15),
              child: Text(
                organization.name.substring(0, 2).toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FusionAppText(
                    text: organization.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          organization.type.displayName,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.colorScheme.elevation3,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          organization.region.displayName,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (organization.email != null)
                    FusionAppText(text: organization.email!),
                  if (organization.phone != null)
                    FusionAppText(text: organization.phone!),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FusionAppText(
            text: title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: FusionAppText(
              text: label,
              style: TextStyle(color: context.colorScheme.elevation6),
            ),
          ),
          Expanded(child: FusionAppText(text: value)),
        ],
      ),
    );
  }

  Widget _statBox(String title, int value, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FusionAppText(
              text: title,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 6),
            FusionAppText(
              text: "$value",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgDetailsCard() {
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        final organization = _viewModel.selectedOrganization;

        if (organization == null) {
          return _card(
            title: "Organization Details",
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return _card(
          title: "Organization Details",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row("Type", organization.type.displayName),
              _row("Region", organization.region.displayName),
              if (organization.description != null)
                _row("Description", organization.description!),
              if (organization.address != null)
                _row("Address", organization.address!),
              if (organization.website != null)
                _row("Website", organization.website!),
              _row(
                "Created",
                DateFormat("MMM dd, yyyy").format(organization.createdAt),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCard() {
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        final organization = _viewModel.selectedOrganization;

        return _card(
          title: "Activity Overview",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    _statBox(
                      "Total Users",
                      organization?.userCount ?? 0,
                      context.colorScheme.elevation3,
                      context.colorScheme.white,
                    ),
                    _statBox(
                      "Ongoing Projects",
                      organization?.ongoingProjectsCount ?? 0,
                      context.colorScheme.elevation3,
                      context.colorScheme.white,
                    ),
                    _statBox(
                      "Completed",
                      organization?.completedProjectsCount ?? 0,
                      context.colorScheme.elevation3,
                      context.colorScheme.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const FusionAppText(
                text: "Contact Information",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (organization?.email != null)
                _contactRow(Icons.email_outlined, organization!.email!),
              if (organization?.phone != null)
                _contactRow(Icons.phone_outlined, organization!.phone!),
              if (organization?.address != null)
                _contactRow(Icons.location_on_outlined, organization!.address!),
              if (organization?.website != null)
                _contactRow(Icons.web_outlined, organization!.website!),
            ],
          ),
        );
      },
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colorScheme.elevation6),
          const SizedBox(width: 10),
          Expanded(
            child: FusionAppText(
              text: value,
              style: TextStyle(color: context.colorScheme.elevation6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        return _card(
          title: "Users (${_viewModel.organizationUsers.length})",
          child: _buildUsersTable(),
        );
      },
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
              Icon(
                Icons.people_outline,
                size: 48,
                color: context.colorScheme.elevation6,
              ),
              const SizedBox(height: 16),
              FusionAppText(
                text: "No users found",
                style: TextStyle(
                  fontSize: 16,
                  color: context.colorScheme.elevation6,
                ),
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
        horizontalMargin: 24,
        minWidth: 600,
        dataRowHeight: 60,
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
              "Name",
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
              "Email",
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
              "Role",
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
              "Joined",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.colorScheme.textPrimary,
              ),
            ),
            size: ColumnSize.M,
          ),
        ],
        rows: users.map((user) {
          final displayName = user.name.isEmpty
              ? user.email.split('@').first
              : user.name;
          return DataRow2(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: context.colorScheme.elevation3,
                      child: Text(
                        displayName.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: context.colorScheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  user.email,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: context.colorScheme.elevation6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.primaryRole,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat("MMM dd, yyyy").format(user.createdAt),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: context.colorScheme.elevation6,
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
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        return _card(
          title: "Projects (${_viewModel.organizationProjects.length})",
          child: _buildProjectsTable(),
        );
      },
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
              Icon(
                Icons.work_outline,
                size: 48,
                color: context.colorScheme.elevation6,
              ),
              const SizedBox(height: 16),
              FusionAppText(
                text: "No projects found",
                style: TextStyle(
                  fontSize: 16,
                  color: context.colorScheme.elevation6,
                ),
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
        horizontalMargin: 24,
        minWidth: 800,
        dataRowHeight: 60,
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
              "Project Name",
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
              "Region",
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
              "Status",
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
              "Type",
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
              "Last Updated",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.colorScheme.textPrimary,
              ),
            ),
            size: ColumnSize.M,
          ),
        ],
        rows: projects.map((project) {
          final statusColor = _getProjectStatusColor(project.status);

          return DataRow2(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      project.name,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.colorScheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.description!,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: context.colorScheme.elevation6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              DataCell(
                Text(
                  project.region,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project.status.displayName,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  project.type.displayName,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: context.colorScheme.elevation6,
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat("MMM dd, yyyy").format(project.lastUpdated),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: context.colorScheme.elevation6,
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
