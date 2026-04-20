import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';
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

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedRegion = null;
      _selectedStatus = null;
      _searchController.clear();
    });
    _viewModel.clearFilters();
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
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithMetrics(),
              const SizedBox(height: 24),
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
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        final metrics = _viewModel.metrics;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Organizations',
              subtitle: 'Manage and monitor all organizations in your network',
            ),
            if (metrics != null) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Distributors',
                      metrics.totalDistributors.toString(),
                      Icons.business,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Resellers',
                      metrics.totalResellers.toString(),
                      Icons.store,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Total End Users',
                      metrics.totalEndUsers.toString(),
                      Icons.people,
                      Colors.green,
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
              labelText: 'Search organizations...',
              prefixIcon: const Icon(Icons.search),
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

        // Type Filter
        Expanded(
          child: DropdownButtonFormField<OrganizationType?>(
            value: _selectedType,
            dropdownColor: context.colorScheme.elevation2,
            style: TextStyle(color: context.colorScheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Type',
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
              const DropdownMenuItem<OrganizationType?>(
                value: null,
                child: Text('All Types'),
              ),
              ...OrganizationType.values.map((type) {
                return DropdownMenuItem<OrganizationType?>(
                  value: type,
                  child: Text(type.displayName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 16),

        // Region Filter
        Expanded(
          child: DropdownButtonFormField<OrganizationRegion?>(
            value: _selectedRegion,
            dropdownColor: context.colorScheme.elevation2,
            style: TextStyle(color: context.colorScheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Region',
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
              const DropdownMenuItem<OrganizationRegion?>(
                value: null,
                child: Text('All Regions'),
              ),
              ...OrganizationRegion.values.map((region) {
                return DropdownMenuItem<OrganizationRegion?>(
                  value: region,
                  child: Text(region.displayName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRegion = value;
              });
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 16),

        // Status Filter
        Expanded(
          child: DropdownButtonFormField<OrganizationStatus?>(
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
            items: const [
              DropdownMenuItem<OrganizationStatus?>(
                value: null,
                child: Text('All Statuses'),
              ),
              DropdownMenuItem<OrganizationStatus?>(
                value: OrganizationStatus.active,
                child: Text('Active'),
              ),
              DropdownMenuItem<OrganizationStatus?>(
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

        // Clear filters
        if (_selectedType != null ||
            _selectedRegion != null ||
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
    return BlocBuilder<
      OrganizationsViewModel,
      BaseState<List<OrganizationEntity>>
    >(
      builder: (context, state) {
        if (state is LoadingState<List<OrganizationEntity>>) {
          return Center(
            child: CircularProgressIndicator(color: context.colorScheme.white),
          );
        }

        if (state is ErrorState<List<OrganizationEntity>>) {
          return _buildErrorState();
        }

        final organizations = state is LoadedState
            ? List<OrganizationEntity>.from((state as LoadedState).data ?? [])
            : <OrganizationEntity>[];

        if (organizations.isEmpty) {
          return _buildEmptyState();
        }

        return DataTable2(
          columnSpacing: 12,
          horizontalMargin: 24,
          minWidth: 800,
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
                'Organization Name',
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
                'Type',
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
                'Region',
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
                'No. of Users',
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
          rows: organizations
              .map((organization) => _buildDataRow(organization))
              .toList(),
        );
      },
    );
  }

  DataRow2 _buildDataRow(OrganizationEntity organization) {
    final typeColor = _getTypeColor(organization.type);

    return DataRow2(
      onTap: () => _navigateToOrganizationProfile(organization),
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: typeColor.withOpacity(0.15),
                child: Text(
                  organization.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                    fontSize: 14,
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
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.colorScheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (organization.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        organization.description!,
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
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              organization.type.displayName,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: typeColor,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            organization.region.displayName,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: context.colorScheme.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            organization.userCount.toString(),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),
        ),
        DataCell(
          Material(
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
              onSelected: (String result) {
                switch (result) {
                  case 'view':
                    _navigateToOrganizationProfile(organization);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'View Profile',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: context.colorScheme.elevation6,
          ),
          const SizedBox(height: 16),
          Text(
            'No organizations found',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Organizations will appear here once they are created',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: context.colorScheme.elevation6,
            ),
            textAlign: TextAlign.center,
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
            'Error loading organizations',
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
            onPressed: () => _viewModel.loadOrganizations(),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
