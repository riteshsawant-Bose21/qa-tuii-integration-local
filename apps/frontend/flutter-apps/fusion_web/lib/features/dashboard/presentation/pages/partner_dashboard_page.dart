import 'package:flutter/material.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:fusion_web/features/dashboard/presentation/widgets/project_overview_widget.dart';
import 'package:fusion_web/features/dashboard/presentation/widgets/device_health_widget.dart';
import 'package:fusion_web/features/dashboard/presentation/widgets/incident_snapshot_widget.dart';
import 'package:fusion_web/features/dashboard/presentation/widgets/regional_insights_widget.dart';
import 'package:fusion_web/features/dashboard/presentation/widgets/users_overview_widget.dart';
import 'package:fusion_web/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:fusion_web/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:fusion_web/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/core/permissions/permissions.dart';

/// Partner Dashboard Page - Main dashboard for reseller/partner view
class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage>
    with PermissionMixin {
  late DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeViewModel();
  }

  void _initializeViewModel() {
    // Initialize data layer
    final dataSource = DashboardDataSource(ServiceLocator().apiService);
    final repository = DashboardRepositoryImpl(dataSource: dataSource);

    // Initialize use cases
    final getPartnerDashboardUseCase = GetPartnerDashboardUseCase(repository);
    final getProjectOverviewUseCase = GetProjectOverviewUseCase(repository);
    final getDeviceHealthSummaryUseCase = GetDeviceHealthSummaryUseCase(
      repository,
    );
    final getIncidentSnapshotUseCase = GetIncidentSnapshotUseCase(repository);
    final getRegionalInsightsUseCase = GetRegionalInsightsUseCase(repository);
    final getUsersOverviewUseCase = GetUsersOverviewUseCase(repository);

    // Initialize view model
    _viewModel = DashboardViewModel(
      getPartnerDashboardUseCase: getPartnerDashboardUseCase,
      getProjectOverviewUseCase: getProjectOverviewUseCase,
      getDeviceHealthSummaryUseCase: getDeviceHealthSummaryUseCase,
      getIncidentSnapshotUseCase: getIncidentSnapshotUseCase,
      getRegionalInsightsUseCase: getRegionalInsightsUseCase,
      getUsersOverviewUseCase: getUsersOverviewUseCase,
    );

    // Load initial data
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF8FAFC),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return Column(
            children: [
              // Modern Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                decoration: const BoxDecoration(
                  // color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Title Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PageHeader(
                            title: 'Dashboard',
                            subtitle:
                                'Overview of your Fusion ecosystem performance and insights',
                          ),
                        ],
                      ),
                    ),

                    // Actions Section
                    Row(
                      children: [
                        // Last Updated Badge
                        if (_viewModel.dashboard != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Updated ${_formatLastUpdated(_viewModel.dashboard!.lastUpdated)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16),

                        // Refresh Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _viewModel.isLoading
                                ? null
                                : _handleRefresh,
                            icon: _viewModel.isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF3B82F6),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh_rounded,
                                    color: Color(0xFF64748B),
                                    size: 20,
                                  ),
                            tooltip: 'Refresh Dashboard',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dashboard Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _buildDashboardContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent() {
    // Show loading state on initial load
    if (_viewModel.isLoading && !_viewModel.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading dashboard data...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (_viewModel.error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load dashboard',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _viewModel.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show dashboard widgets in responsive grid
    return _buildResponsiveGrid();
  }

  Widget _buildResponsiveGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet = constraints.maxWidth > 768;

        if (isDesktop) {
          // Desktop: 3x2 grid
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProjectOverviewWidget(
                      projectOverview: _viewModel.projectOverview,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadProjectOverview,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: DeviceHealthWidget(
                      deviceHealth: _viewModel.deviceHealthSummary,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadDeviceHealthSummary,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: UsersOverviewWidget(
                      usersOverview: _viewModel.usersOverview,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadUsersOverview,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: IncidentSnapshotWidget(
                      incidentSnapshot: _viewModel.incidentSnapshot,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadIncidentSnapshot,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: RegionalInsightsWidget(
                      regionalInsights: _viewModel.regionalInsights,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadRegionalInsights,
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: SizedBox(),
                  ), // Empty space for alignment
                ],
              ),
            ],
          );
        } else if (isTablet) {
          // Tablet: 2x3 grid with smaller spacing
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProjectOverviewWidget(
                      projectOverview: _viewModel.projectOverview,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadProjectOverview,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DeviceHealthWidget(
                      deviceHealth: _viewModel.deviceHealthSummary,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadDeviceHealthSummary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: UsersOverviewWidget(
                      usersOverview: _viewModel.usersOverview,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadUsersOverview,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: IncidentSnapshotWidget(
                      incidentSnapshot: _viewModel.incidentSnapshot,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadIncidentSnapshot,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RegionalInsightsWidget(
                      regionalInsights: _viewModel.regionalInsights,
                      isLoading: _viewModel.isLoading,
                      onRefresh: _viewModel.loadRegionalInsights,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: SizedBox(),
                  ), // Empty space for alignment
                ],
              ),
            ],
          );
        } else {
          // Mobile: Single column
          return Column(
            children: [
              ProjectOverviewWidget(
                projectOverview: _viewModel.projectOverview,
                isLoading: _viewModel.isLoading,
                onRefresh: _viewModel.loadProjectOverview,
              ),
              const SizedBox(height: 16),
              DeviceHealthWidget(
                deviceHealth: _viewModel.deviceHealthSummary,
                isLoading: _viewModel.isLoading,
                onRefresh: _viewModel.loadDeviceHealthSummary,
              ),
              const SizedBox(height: 16),
              UsersOverviewWidget(
                usersOverview: _viewModel.usersOverview,
                isLoading: _viewModel.isLoading,
                onRefresh: _viewModel.loadUsersOverview,
              ),
              const SizedBox(height: 16),
              IncidentSnapshotWidget(
                incidentSnapshot: _viewModel.incidentSnapshot,
                isLoading: _viewModel.isLoading,
                onRefresh: _viewModel.loadIncidentSnapshot,
              ),
              const SizedBox(height: 16),
              RegionalInsightsWidget(
                regionalInsights: _viewModel.regionalInsights,
                isLoading: _viewModel.isLoading,
                onRefresh: _viewModel.loadRegionalInsights,
              ),
            ],
          );
        }
      },
    );
  }

  void _handleRefresh() {
    _viewModel.clearError();
    _viewModel.refreshDashboard();
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
