import 'package:fusion_web/core/services/api_service.dart';
import 'package:fusion_web/features/dashboard/data/models/dashboard_models.dart';

/// Dashboard data source for API interactions
class DashboardDataSource {
  final ApiService _apiService;

  const DashboardDataSource(this._apiService);

  /// Get complete dashboard data for partner
  Future<DashboardModel> getPartnerDashboard() async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.get('dashboard/partner');
      // return DashboardModel.fromJson(response);

      // Hardcoded data for now
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simulate API delay

      return DashboardModel(
        projectOverview: ProjectOverviewModel(
          totalProjects: 42,
          activeProjects: 28,
          completedProjects: 12,
          archivedProjects: 2,
          projectsByRegion: {
            'North America': 18,
            'Europe': 15,
            'Asia Pacific': 9,
          },
          recentActivityCount7Days: 15,
          recentActivityCount30Days: 38,
        ),
        deviceHealthSummary: DeviceHealthSummaryModel(
          healthyDevicesCount: 156,
          warningDevicesCount: 23,
          criticalDevicesCount: 5,
          topDeviceModels: {
            'FreeSpace FS2SE': 45,
            'PowerMatch PM8500N': 38,
            'ControlSpace EX-1280C': 32,
            'EdgeMax EM180': 28,
            'ArenaMatch AM40': 22,
          },
          incidentsLast7Days: 8,
          incidentsLast30Days: 31,
        ),
        incidentSnapshot: IncidentSnapshotModel(
          totalOpenIncidents: 12,
          criticalAlerts: 3,
          incidentTrendData: [
            IncidentTrendPointModel(
              date: DateTime.now().subtract(const Duration(days: 6)),
              count: 2,
            ),
            IncidentTrendPointModel(
              date: DateTime.now().subtract(const Duration(days: 5)),
              count: 1,
            ),
            IncidentTrendPointModel(
              date: DateTime.now().subtract(const Duration(days: 4)),
              count: 4,
            ),
            IncidentTrendPointModel(
              date: DateTime.now().subtract(const Duration(days: 3)),
              count: 0,
            ),
            IncidentTrendPointModel(
              date: DateTime.now().subtract(const Duration(days: 2)),
              count: 1,
            ),
            IncidentTrendPointModel(
              date: DateTime.now().subtract(const Duration(days: 1)),
              count: 3,
            ),
            IncidentTrendPointModel(date: DateTime.now(), count: 2),
          ],
          topIncidentCategories: {
            'Network Connectivity': 5,
            'Audio Quality': 3,
            'Power Issues': 2,
            'Configuration': 1,
            'Hardware Failure': 1,
          },
        ),
        regionalInsights: RegionalInsightsModel(
          projectsByRegion: {
            'North America': 18,
            'Europe': 15,
            'Asia Pacific': 9,
          },
          activePartnersByRegion: {
            'North America': 12,
            'Europe': 8,
            'Asia Pacific': 6,
          },
          devicesByGeography: {
            'North America': 98,
            'Europe': 65,
            'Asia Pacific': 41,
          },
          salesKPIs: {
            'monthly_revenue': 125000.0,
            'quarter_growth': 15.5,
            'project_completion_rate': 92.3,
            'customer_satisfaction': 4.6,
          },
        ),
        usersOverview: UsersOverviewModel(
          totalUsers: 87,
          activeUsers: 72,
          invitedUsers: 8,
          inactiveUsers: 7,
          usersByRole: {
            'Admin': 5,
            'Project Manager': 12,
            'Engineer': 28,
            'Technician': 24,
            'Viewer': 18,
          },
          usersByType: {
            'Admin': 5,
            'Contributor': 40,
            'Designer': 15,
            'Technician': 20,
            'Viewer': 7,
          },
          usersJoinedLast7Days: 3,
          usersJoinedLast30Days: 12,
          lastUserJoinedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to fetch partner dashboard data: $e');
    }
  }

  /// Get project overview data
  Future<ProjectOverviewModel> getProjectOverview() async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.get('dashboard/partner/projects');
      // return ProjectOverviewModel.fromJson(response);

      await Future.delayed(const Duration(milliseconds: 500));

      return const ProjectOverviewModel(
        totalProjects: 42,
        activeProjects: 28,
        completedProjects: 12,
        archivedProjects: 2,
        projectsByRegion: {
          'North America': 18,
          'Europe': 15,
          'Asia Pacific': 9,
        },
        recentActivityCount7Days: 15,
        recentActivityCount30Days: 38,
      );
    } catch (e) {
      throw Exception('Failed to fetch project overview: $e');
    }
  }

  /// Get device health summary data
  Future<DeviceHealthSummaryModel> getDeviceHealthSummary() async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.get('dashboard/partner/devices');
      // return DeviceHealthSummaryModel.fromJson(response);

      await Future.delayed(const Duration(milliseconds: 600));

      return const DeviceHealthSummaryModel(
        healthyDevicesCount: 156,
        warningDevicesCount: 23,
        criticalDevicesCount: 5,
        topDeviceModels: {
          'FreeSpace FS2SE': 45,
          'PowerMatch PM8500N': 38,
          'ControlSpace EX-1280C': 32,
          'EdgeMax EM180': 28,
          'ArenaMatch AM40': 22,
        },
        incidentsLast7Days: 8,
        incidentsLast30Days: 31,
      );
    } catch (e) {
      throw Exception('Failed to fetch device health summary: $e');
    }
  }

  /// Get incident snapshot data
  Future<IncidentSnapshotModel> getIncidentSnapshot() async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.get('dashboard/partner/incidents');
      // return IncidentSnapshotModel.fromJson(response);

      await Future.delayed(const Duration(milliseconds: 700));

      return IncidentSnapshotModel(
        totalOpenIncidents: 12,
        criticalAlerts: 3,
        incidentTrendData: [
          IncidentTrendPointModel(
            date: DateTime.now().subtract(const Duration(days: 6)),
            count: 2,
          ),
          IncidentTrendPointModel(
            date: DateTime.now().subtract(const Duration(days: 5)),
            count: 1,
          ),
          IncidentTrendPointModel(
            date: DateTime.now().subtract(const Duration(days: 4)),
            count: 4,
          ),
          IncidentTrendPointModel(
            date: DateTime.now().subtract(const Duration(days: 3)),
            count: 0,
          ),
          IncidentTrendPointModel(
            date: DateTime.now().subtract(const Duration(days: 2)),
            count: 1,
          ),
          IncidentTrendPointModel(
            date: DateTime.now().subtract(const Duration(days: 1)),
            count: 3,
          ),
          IncidentTrendPointModel(date: DateTime.now(), count: 2),
        ],
        topIncidentCategories: const {
          'Network Connectivity': 5,
          'Audio Quality': 3,
          'Power Issues': 2,
          'Configuration': 1,
          'Hardware Failure': 1,
        },
      );
    } catch (e) {
      throw Exception('Failed to fetch incident snapshot: $e');
    }
  }

  /// Get regional insights data
  Future<RegionalInsightsModel> getRegionalInsights() async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.get('dashboard/partner/regions');
      // return RegionalInsightsModel.fromJson(response);

      await Future.delayed(const Duration(milliseconds: 400));

      return const RegionalInsightsModel(
        projectsByRegion: {
          'North America': 18,
          'Europe': 15,
          'Asia Pacific': 9,
        },
        activePartnersByRegion: {
          'North America': 12,
          'Europe': 8,
          'Asia Pacific': 6,
        },
        devicesByGeography: {
          'North America': 98,
          'Europe': 65,
          'Asia Pacific': 41,
        },
        salesKPIs: {
          'monthly_revenue': 125000.0,
          'quarter_growth': 15.5,
          'project_completion_rate': 92.3,
          'customer_satisfaction': 4.6,
        },
      );
    } catch (e) {
      throw Exception('Failed to fetch regional insights: $e');
    }
  }

  /// Get users overview data
  Future<UsersOverviewModel> getUsersOverview() async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.get('dashboard/partner/users');
      // return UsersOverviewModel.fromJson(response);

      await Future.delayed(const Duration(milliseconds: 350));

      return UsersOverviewModel(
        totalUsers: 87,
        activeUsers: 72,
        invitedUsers: 8,
        inactiveUsers: 7,
        usersByRole: {
          'Admin': 5,
          'Project Manager': 12,
          'Engineer': 28,
          'Technician': 24,
          'Viewer': 18,
        },
        usersByType: {
          'Admin': 5,
          'Contributor': 40,
          'Designer': 15,
          'Technician': 20,
          'Viewer': 7,
        },
        usersJoinedLast7Days: 3,
        usersJoinedLast30Days: 12,
        lastUserJoinedAt: DateTime.now().subtract(const Duration(days: 2)),
      );
    } catch (e) {
      throw Exception('Failed to fetch users overview: $e');
    }
  }
}
