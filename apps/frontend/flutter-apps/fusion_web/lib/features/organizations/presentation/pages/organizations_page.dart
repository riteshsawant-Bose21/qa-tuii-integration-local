import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/organizations/presentation/viewmodels/organizations_viewmodel.dart';
import 'package:fusion_web/features/organizations/domain/entities/organization_entity.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:go_router/go_router.dart';
import 'package:fusion_web/core/constants/app_constants.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  late final OrganizationsViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  OrganizationType? _selectedType;
  OrganizationRegion? _selectedRegion;
  OrganizationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();

    try {
      _viewModel = ServiceLocator().organizationsViewModel;
    } catch (e) {
      print('OrganizationsPage: Error creating viewModel: $e');
      rethrow;
    }

    _viewModel.initialize();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _viewModel.searchOrganizations(_searchQuery);
    });
  }

  void _applyFilters() {
    _viewModel.applyFilters(
      type: _selectedType,
      region: _selectedRegion,
      status: _selectedStatus,
    );
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

  void _navigateToOrganizationProfile(OrganizationEntity organization) {
    context.go('${AppConstants.organizationsRoute}/${organization.id}');
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
                    minHeight: constraints.maxHeight - 48,
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
                        height: constraints.maxHeight - 400,
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
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        final metrics = _viewModel.metrics;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Action Button Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organizations',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage and monitor all organizations in your network',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Future: Add organization button here if needed
              ],
            ),
            const SizedBox(height: 32),

            // Metrics Cards Row
            if (metrics != null)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Distributors',
                      metrics.totalDistributors.toString(),
                      Icons.business,
                      Colors.purple.shade100,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Resellers',
                      metrics.totalResellers.toString(),
                      Icons.store,
                      Colors.blue.shade100,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Total End Users / System Owners',
                      metrics.totalEndUsers.toString(),
                      Icons.people,
                      Colors.green.shade100,
                      Colors.green.shade700,
                    ),
                  ),
                ],
              ),
          ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
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
          Text(
            'All Organizations',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar and Filters in Same Row
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search organizations...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Type Filter
              Expanded(
                child: DropdownButtonFormField<OrganizationType?>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<OrganizationType?>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...OrganizationType.values.map((type) {
                      return DropdownMenuItem<OrganizationType?>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Region Filter
              Expanded(
                child: DropdownButtonFormField<OrganizationRegion?>(
                  value: _selectedRegion,
                  decoration: InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<OrganizationRegion?>(
                      value: null,
                      child: Text('All Regions'),
                    ),
                    ...OrganizationRegion.values.map((region) {
                      return DropdownMenuItem<OrganizationRegion?>(
                        value: region,
                        child: Text(region.displayName),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Status Filter
              Expanded(
                child: DropdownButtonFormField<OrganizationStatus?>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<OrganizationStatus?>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    const DropdownMenuItem<OrganizationStatus?>(
                      value: OrganizationStatus.active,
                      child: Text('Active'),
                    ),
                    const DropdownMenuItem<OrganizationStatus?>(
                      value: OrganizationStatus.inactive,
                      child: Text('Inactive'),
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
      ),
    );
  }

  Widget _buildDataTable() {
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildTableContent(state),
          ),
        );
      },
    );
  }

  Widget _buildTableContent(BaseState<List<OrganizationEntity>> state) {
    if (state is LoadingState) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is ErrorState) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading organizations',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (state as ErrorState).message,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _viewModel.loadOrganizations(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final organizations = state is LoadedState
        ? List<OrganizationEntity>.from((state as LoadedState).data ?? [])
        : <OrganizationEntity>[];

    if (organizations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.business_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No organizations found',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Organizations will appear here once they are created',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 20,
      minWidth: 800,
      headingRowColor: WidgetStateColor.resolveWith(
        (states) => Colors.grey.shade50,
      ),
      columns: _buildColumns(),
      rows: organizations
          .map((organization) => _buildDataRow(organization))
          .toList(),
    );
  }

  List<DataColumn2> _buildColumns() {
    return [
      DataColumn2(
        label: Text(
          'Organization Name',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        size: ColumnSize.L,
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
          'Region',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(
          'No. of Users',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        size: ColumnSize.S,
      ),
      DataColumn2(
        label: Text(
          'Actions',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        size: ColumnSize.S,
      ),
    ];
  }

  DataRow2 _buildDataRow(OrganizationEntity organization) {
    return DataRow2(
      cells: [
        DataCell(
          GestureDetector(
            onTap: () => _navigateToOrganizationProfile(organization),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getTypeColor(
                    organization.type,
                  ).withOpacity(0.1),
                  child: Text(
                    organization.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(organization.type),
                      fontSize: 12,
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
                        organization.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (organization.description != null)
                        Text(
                          organization.description!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor(organization.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              organization.type.displayName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getTypeColor(organization.type),
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            organization.region.displayName,
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        DataCell(
          Text(
            organization.userCount.toString(),
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) {
              switch (result) {
                case 'view':
                  _navigateToOrganizationProfile(organization);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 16),
                    SizedBox(width: 8),
                    Text('View'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
